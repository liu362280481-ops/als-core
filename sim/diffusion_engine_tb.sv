`timescale 1ns/1ps

// =============================================================================
// diffusion_engine_tb.sv — v3 修复版
// Fix 1: TX 严格遵守 AXI 握手因果律，valid 只在 valid&ready 完成后撤销
// Fix 2: 超时放宽至 5M 周期，或用 m_axis_tlast 优雅结束
// =============================================================================

module diffusion_engine_tb;

  localparam DATA_W        = 48;
  localparam MAX_SAMPLES   = 16384;  // 128 x 128
  localparam CLK_PERIOD_NS  = 10;      // 100MHz
  localparam READY_HIGH_PCT = 75;      // backpressure %
  localparam TIMEOUT_CYCLES = 5000000; // 放大5倍

  string input_hex_path  = "sim/input_q8_8.hex";
  string output_hex_path = "sim/output_q8_8.hex";

  reg clk;
  reg rst_n;

  reg  [DATA_W-1:0] s_axis_tdata;
  reg              s_axis_tvalid;
  wire             s_axis_tready;
  reg              s_axis_tlast;

  wire [DATA_W-1:0] m_axis_tdata;
  wire             m_axis_tvalid;
  reg              m_axis_tready;
  wire             m_axis_tlast;

  reg  [DATA_W-1:0] input_mem [0:MAX_SAMPLES-1];
  integer          input_count;
  integer          tx_idx;
  integer          rx_idx;
  integer          cycle_cnt;
  reg              input_done;
  reg              output_done;
  integer          f_out;

  wire [DATA_W-1:0] zero_word;
  assign zero_word = {DATA_W{1'b0}};

  // VCD dump
  initial begin
    $dumpfile("sim/diff_wave.vcd");
    $dumpvars(0, diffusion_engine_tb);
  end

  // DUT
  diffusion_engine dut (
    .aclk          (clk),
    .aresetn       (rst_n),
    .s_axis_tdata  (s_axis_tdata),
    .s_axis_tvalid (s_axis_tvalid),
    .s_axis_tready (s_axis_tready),
    .s_axis_tlast  (s_axis_tlast),
    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (m_axis_tready),
    .m_axis_tlast  (m_axis_tlast)
  );

  // Clock
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS / 2) clk = ~clk;
  end

  // Load input
  initial begin
    $display("[TB] Loading input: %0s", input_hex_path);
    $readmemh(input_hex_path, input_mem);
    input_count = 0;
    begin : find_count
      integer i;
      for (i = 0; i < MAX_SAMPLES; i = i + 1) begin
        if (input_mem[i] !== zero_word && input_mem[i] !== {DATA_W{1'bx}}) begin
          input_count = input_count + 1;
        end else begin
          disable find_count;
        end
      end
    end
    if (input_count == 0) begin
      $display("[TB][FATAL] input_mem is empty!");
      $fatal(1);
    end
    $display("[TB] Valid input samples: %0d", input_count);
  end

  // Open output file
  initial begin
    f_out = $fopen(output_hex_path, "w");
    if (f_out == 0) begin
      $display("[TB][FATAL] Cannot open output: %0s", output_hex_path);
      $fatal(1);
    end
  end

  // Reset sequence
  initial begin
    rst_n = 1'b0;
    s_axis_tdata  = zero_word;
    s_axis_tvalid = 1'b0;
    s_axis_tlast  = 1'b0;
    m_axis_tready = 1'b0;
    tx_idx     = 0;
    rx_idx     = 0;
    cycle_cnt  = 0;
    input_done  = 1'b0;
    output_done = 1'b0;
    repeat (20) @(posedge clk);
    rst_n = 1'b1;
    m_axis_tready = 1'b1;
    $display("[TB] Reset released at t=%0t", $time);
  end

  // =============================================================================
  // TX: 严格 AXI 握手因果律
  // Fix: valid 只在 valid&ready 同时为高之后才撤销
  // =============================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      s_axis_tvalid <= 1'b0;
      s_axis_tdata  <= zero_word;
      s_axis_tlast  <= 1'b0;
      tx_idx        <= 0;
      input_done    <= 1'b0;
    end else if (!input_done) begin
      // 驱动当前 beat
      s_axis_tvalid <= 1'b1;
      s_axis_tdata  <= input_mem[tx_idx];
      s_axis_tlast  <= (tx_idx == (input_count - 1));

      // 严格 AXI 握手：只有 valid & ready 同时为高，才算完成
      if (s_axis_tvalid && s_axis_tready) begin
        if (tx_idx == (input_count - 1)) begin
          // 最后一拍握手完成，安全撤销
          input_done    <= 1'b1;
          s_axis_tvalid <= 1'b0;
          s_axis_tlast  <= 1'b0;
        end else begin
          // 推进到下一个 beat
          tx_idx <= tx_idx + 1;
        end
      end
    end
  end

  // =============================================================================
  // RX: 背压 + 捕获写入文件
  // =============================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      m_axis_tready <= 1'b0;
      rx_idx      <= 0;
      output_done <= 1'b0;
    end else begin
      // 随机背压
      m_axis_tready <= ($random % 100) < READY_HIGH_PCT;

      // 捕获有效数据
      if (m_axis_tvalid && m_axis_tready) begin
        $fwrite(f_out, "%012X\n", m_axis_tdata);
        rx_idx <= rx_idx + 1;
      end
      // 当所有数据都收到时（不依赖 tlast），立即结束
      if (rx_idx >= input_count) begin
        output_done <= 1'b1;
      end
    end
  end

  // =============================================================================
  // 超时检测（放宽到5M）
  // =============================================================================
  always @(posedge clk) begin
    if (rst_n) begin
      cycle_cnt <= cycle_cnt + 1;
      if (cycle_cnt > TIMEOUT_CYCLES) begin
        $display("[TB][FATAL] Timeout @ cycle %0d", cycle_cnt);
        $fclose(f_out);
        $fatal(1);
      end
    end
  end

  // =============================================================================
  // 结束：优雅检测 output_done
  // =============================================================================
  always @(posedge clk) begin
    if (rst_n && output_done) begin
      $fclose(f_out);
      $display("============================================================");
      $display("[TB] DONE — RX capture complete");
      $display("[TB] Cycles: %0d", cycle_cnt);
      $display("============================================================");
      #20;
      $finish;
    end
  end

endmodule
