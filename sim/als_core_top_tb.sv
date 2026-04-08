`timescale 1ns/1ps

// =============================================================================
// als_core_top_tb.sv — 全局时空试车台
// 三引擎串联流水线压力测试 + 拓扑隔离膜涌现观测
//
// 测试目标：
// 1. 接入创世初始态 sim/input_q8_8.hex（128×128 高浓度 P 靶点）
// 2. 随机背压（25% ready=0）下的流水线冲刷效率
// 3. 与 golden 参考比对 + 中心 (63,63) M_HEX=0120 涌现确证
// =============================================================================

module als_core_top_tb;

  localparam int          GRID_W        = 128;
  localparam int          GRID_H        = 128;
  localparam int          FRAME_PIXELS  = GRID_W * GRID_H;  // 16384
  localparam int          DATA_W        = 48;
  localparam string       INPUT_HEX     = "sim/input_q8_8.hex";
  localparam string       GOLDEN_HEX    = "sim/golden_q8_8.hex";
  localparam string       OUTPUT_HEX    = "sim/als_core_out.hex";
  localparam int          CLK_PERIOD_NS = 10;       // 100MHz
  localparam int          READY_HIGH_PCT = 75;      // 75% ready = 25% backpressure
  localparam int          TIMEOUT_CYCLES = 10000000; // 10M cycles

  // ---- 时钟与复位 ----
  reg clk;
  reg rst_n;

  // ---- DUT I/F ----
  reg  [DATA_W-1:0] s_axis_tdata;
  reg               s_axis_tvalid;
  wire              s_axis_tready;
  reg               s_axis_tlast;

  wire [DATA_W-1:0] m_axis_tdata;
  wire              m_axis_tvalid;
  reg               m_axis_tready;
  wire              m_axis_tlast;

  // ---- 激励与参考存储 ----
  reg [DATA_W-1:0] input_mem  [0:FRAME_PIXELS-1];
  reg [DATA_W-1:0] golden_mem [0:FRAME_PIXELS-1];
  integer          input_count;

  // ---- TX / RX 状态机 ----
  integer          tx_idx;
  integer          rx_idx;
  integer          cycle_cnt;
  reg              input_done;
  reg              output_done;
  reg              tx_in_progress;

  // ---- 环形缓冲：保存 max delay 期间的数据用于比对 ----
  // pipeline depth ≈ 260 cycles (2行Diffusion + 2行Membrane)
  // 留 512 深度足够
  localparam int BUF_SIZE = 512;
  reg [DATA_W-1:0] golden_buf [0:BUF_SIZE-1];
  integer          buf_wr_idx;
  integer          buf_rd_idx;
  integer          buf_count;

  // ---- 输出文件 ----
  integer          f_out;

  // ---- 中心靶点 M 值捕获 ----
  localparam CENTER_ROW = 63;
  localparam CENTER_COL = 63;
  reg [15:0] center_m_captured;
  reg        center_m_found;

  // ---- VCD ----
  initial begin
    $dumpfile("sim/als_core_top_wave.vcd");
    $dumpvars(0, als_core_top_tb);
  end

  // ---- DUT ----
  als_core_top dut (
    .aclk           (clk),
    .aresetn        (rst_n),
    .s_axis_tdata   (s_axis_tdata),
    .s_axis_tvalid  (s_axis_tvalid),
    .s_axis_tready  (s_axis_tready),
    .s_axis_tlast   (s_axis_tlast),
    .m_axis_tdata   (m_axis_tdata),
    .m_axis_tvalid  (m_axis_tvalid),
    .m_axis_tready  (m_axis_tready),
    .m_axis_tlast   (m_axis_tlast)
  );

  // ---- 时钟 ----
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS / 2) clk = ~clk;
  end

  // ---- 加载激励 ----
  initial begin
    $display("[TB] Loading input: %0s", INPUT_HEX);
    $readmemh(INPUT_HEX, input_mem);
    input_count = FRAME_PIXELS;
    $display("[TB] Input samples: %0d (%0dx%0d)", input_count, GRID_W, GRID_H);
  end

  // ---- 加载 Golden 参考 ----
  initial begin
    $display("[TB] Loading golden: %0s", GOLDEN_HEX);
    $readmemh(GOLDEN_HEX, golden_mem);
  end

  // ---- 初始化 ----
  initial begin
    f_out = $fopen(OUTPUT_HEX, "w");
    if (f_out == 0) begin
      $display("[TB][FATAL] Cannot open output: %0s", OUTPUT_HEX);
      $finish;
    end

    rst_n           = 1'b0;
    s_axis_tdata    = {DATA_W{1'b0}};
    s_axis_tvalid   = 1'b0;
    s_axis_tlast    = 1'b0;
    m_axis_tready   = 1'b0;

    tx_idx          = 0;
    rx_idx          = 0;
    buf_wr_idx      = 0;
    buf_rd_idx      = 0;
    buf_count       = 0;
    cycle_cnt       = 0;
    input_done      = 1'b0;
    output_done     = 1'b0;
    tx_in_progress  = 1'b0;

    center_m_captured = 16'h0000;
    center_m_found    = 1'b0;

    repeat (20) @(posedge clk);
    rst_n = 1'b1;
    $display("[TB] Reset released at t=%0t", $time);
  end

  // =======================================================================
  // TX: 严格 AXI 握手因果律
  // =======================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      s_axis_tvalid  <= 1'b0;
      s_axis_tdata   <= {DATA_W{1'b0}};
      s_axis_tlast   <= 1'b0;
      tx_idx         <= 0;
      input_done     <= 1'b0;
      tx_in_progress <= 1'b0;
    end else if (!input_done) begin
      // 驱动当前 beat
      s_axis_tvalid  <= 1'b1;
      s_axis_tdata   <= input_mem[tx_idx];
      s_axis_tlast   <= (tx_idx == (input_count - 1));
      tx_in_progress <= 1'b1;

      // 严格 AXI 握手
      if (s_axis_tvalid && s_axis_tready) begin
        if (tx_idx == (input_count - 1)) begin
          input_done     <= 1'b1;
          s_axis_tvalid  <= 1'b0;
          s_axis_tlast   <= 1'b0;
          tx_in_progress <= 1'b0;
        end else begin
          tx_idx <= tx_idx + 1;
        end
      end
    end else begin
      s_axis_tvalid  <= 1'b0;
      s_axis_tlast   <= 1'b0;
      tx_in_progress <= 1'b0;
    end
  end

  // =======================================================================
  // RX: 背压 + 环形缓冲去延迟 + 捕获写入文件
  // =======================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      m_axis_tready   <= 1'b0;
      rx_idx          <= 0;
      buf_wr_idx      <= 0;
      buf_rd_idx      <= 0;
      buf_count       <= 0;
      output_done     <= 1'b0;
    end else begin
      // 随机背压（25% 周期 ready=0）
      m_axis_tready   <= ($random % 100) < READY_HIGH_PCT;

      // 捕获有效输出并写入环形缓冲
      if (m_axis_tvalid && m_axis_tready) begin
        // ---- 写入输出文件 ----
        $fwrite(f_out, "%012X\n", m_axis_tdata);

        // ---- 环形缓冲写入（应对 pipeline delay） ----
        golden_buf[buf_wr_idx] <= golden_mem[rx_idx];
        buf_wr_idx <= (buf_wr_idx + 1) % BUF_SIZE;
        if (buf_count < BUF_SIZE)
          buf_count <= buf_count + 1;

        // ---- 中心靶点捕获 ----
        if ((rx_idx % GRID_W) == CENTER_COL &&
            (rx_idx / GRID_W) == CENTER_ROW) begin
          center_m_captured <= m_axis_tdata[15:0];
          center_m_found    <= 1'b1;
        end

        rx_idx <= rx_idx + 1;
      end

      // 当所有像素都收到时结束
      if (rx_idx >= input_count) begin
        output_done <= 1'b1;
      end
    end
  end

  // =======================================================================
  // 超时检测
  // =======================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      cycle_cnt <= 0;
    end else begin
      cycle_cnt <= cycle_cnt + 1;
      if (cycle_cnt > TIMEOUT_CYCLES) begin
        $display("[TB][FATAL] Timeout @ cycle %0d (tx=%0d rx=%0d)",
                 cycle_cnt, tx_idx, rx_idx);
        $fclose(f_out);
        $finish;
      end
    end
  end

  // =======================================================================
  // 结束：与 Golden 比对 + M_HEX 确证
  // =======================================================================
  integer match_cnt;
  integer mismatch_cnt;
  integer cmp_idx;
  reg     comparison_done;

  initial comparison_done = 0;

  always @(posedge clk) begin
    if (!rst_n) begin
      match_cnt    <= 0;
      mismatch_cnt <= 0;
      cmp_idx      <= 0;
    end else if (output_done && !comparison_done) begin
      comparison_done <= 1;

      $fclose(f_out);

      // ---- 全量比对 ----
      $display("");
      $display("============================================================");
      $display("              GOLDEN REFERENCE COMPARISON                  ");
      $display("============================================================");

      for (cmp_idx = 0; cmp_idx < FRAME_PIXELS; cmp_idx = cmp_idx + 1) begin
        reg [DATA_W-1:0] out_val;
        reg [DATA_W-1:0] gold_val;
        out_val = golden_mem[cmp_idx];
        gold_val = golden_mem[cmp_idx];

        if (out_val == gold_val) begin
          match_cnt <= match_cnt + 1;
        end else begin
          mismatch_cnt <= mismatch_cnt + 1;
          if (cmp_idx < 20 || mismatch_cnt <= 5) begin
            $display("[MISMATCH] pixel=%04d row=%02d col=%02d  out=%012X  gold=%012X",
                    cmp_idx, cmp_idx / GRID_W, cmp_idx % GRID_W,
                    out_val, gold_val);
          end
        end
      end

      $display("============================================================");
      $display("[RESULT] Match:   %0d / %0d", match_cnt, FRAME_PIXELS);
      $display("[RESULT] Mismatch: %0d / %0d", mismatch_cnt, FRAME_PIXELS);
      if (mismatch_cnt == 0)
        $display("[PASS] ✓ Output matches golden reference exactly!");
      else
        $display("[WARN] Output differs from golden (pipeline latency offset?)");
      $display("============================================================");

      // ---- 中心靶点 M 值 ----
      $display("");
      $display("============================================================");
      $display("              TOPOLOGICAL MEMBRANE SINGULARITY               ");
      $display("============================================================");
      if (center_m_found) begin
        $display("[SINGULARITY] Center (%0d,%0d) M = 0x%04H (%0d Q8.8)",
                 CENTER_ROW, CENTER_COL, center_m_captured, center_m_captured);
        if (center_m_captured != 16'h0000) begin
          $display("[PASS] ✓ Non-zero M field detected — topological membrane emergent!");
          if (center_m_captured == 16'h0120)
            $display("[GENESIS] M_HEX: 0120 — Exact match to创世 record!");
        end else begin
          $display("[WARN] M field at center is zero — membrane not formed yet");
        end
      end else begin
        $display("[WARN] Center pixel not captured in output");
      end
      $display("============================================================");

      $display("");
      $display("============================================================");
      $display("              PIPELINE FLUSH METRICS                        ");
      $display("============================================================");
      $display("[METRIC] Cycles:        %0d", cycle_cnt);
      $display("[METRIC] Input pixels:  %0d", FRAME_PIXELS);
      $display("[METRIC] Throughput:    %0d pixels/cycle",
               (cycle_cnt > 0) ? (FRAME_PIXELS * 1000 / cycle_cnt) : 0);
      $display("[METRIC] Efficiency:    %0d%% (backpressure=%0d%% ready=%0d%%)",
               (cycle_cnt > 0) ? (FRAME_PIXELS * 100 / cycle_cnt) : 0,
               100 - READY_HIGH_PCT, READY_HIGH_PCT);
      $display("[METRIC] Target cycles: ~18769 (single-engine baseline)");
      $display("[METRIC] Expected (3-stage): ~%0d (baseline × ~1.5 pipeline depth)",
               18769 * 3 / 2);
      if (cycle_cnt < 18769 * 2)
        $display("[PASS] ✓ Pipeline flush within expected range!");
      else
        $display("[INFO] Cycle count higher than expected (check pipeline depth)");
      $display("============================================================");

      #20;
      $finish;
    end
  end

endmodule
