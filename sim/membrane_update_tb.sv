`timescale 1ns/1ps

module membrane_update_tb;

  parameter DATA_W = 48;
  parameter FRAME_PIXELS = 16384;
  parameter TIMEOUT_CYCLES = 500000;

  reg clk;
  reg aresetn;

  reg  [DATA_W-1:0] s_axis_tdata;
  reg               s_axis_tvalid;
  wire              s_axis_tready;
  reg               s_axis_tlast;

  wire [DATA_W-1:0] m_axis_tdata;
  wire              m_axis_tvalid;
  reg               m_axis_tready;
  wire              m_axis_tlast;

  reg [DATA_W-1:0] mem_in [0:FRAME_PIXELS-1];

  integer fd_out;
  integer tx_idx;
  integer rx_cnt;
  integer cycle_cnt;
  integer post_last_cnt;

  reg sending_done;
  reg last_seen;
  reg finish_armed;

  membrane_update dut (
    .aclk         (clk),
    .aresetn      (aresetn),
    .s_axis_tdata (s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast (s_axis_tlast),
    .m_axis_tdata (m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast (m_axis_tlast)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    $readmemh("sim/membrane_in.hex", mem_in);
    fd_out = $fopen("sim/membrane_out.hex", "w");
    if (fd_out == 0) begin
      $display("ERROR: cannot open sim/membrane_out.hex");
      $finish;
    end

    aresetn = 1'b0;
    s_axis_tdata = {DATA_W{1'b0}};
    s_axis_tvalid = 1'b0;
    s_axis_tlast = 1'b0;
    m_axis_tready = 1'b0;

    tx_idx = 0;
    rx_cnt = 0;
    cycle_cnt = 0;
    post_last_cnt = 0;
    sending_done = 1'b0;
    last_seen = 1'b0;
    finish_armed = 1'b0;

    repeat (10) @(posedge clk);
    aresetn = 1'b1;
  end

  always @(posedge clk) begin
    if (!aresetn) begin
      m_axis_tready <= 1'b0;
    end else begin
      m_axis_tready <= ({$random} % 4) != 0;
    end
  end

  always @(posedge clk) begin
    if (!aresetn) begin
      s_axis_tvalid <= 1'b0;
      s_axis_tdata  <= {DATA_W{1'b0}};
      s_axis_tlast  <= 1'b0;
      tx_idx <= 0;
      sending_done <= 1'b0;
    end else begin
      if (!sending_done) begin
        s_axis_tvalid <= 1'b1;
        s_axis_tdata  <= mem_in[tx_idx];
        s_axis_tlast  <= (tx_idx == FRAME_PIXELS-1);

        if (s_axis_tvalid && s_axis_tready) begin
          if (tx_idx == FRAME_PIXELS-1) begin
            sending_done <= 1'b1;
            s_axis_tvalid <= 1'b0;
            s_axis_tlast <= 1'b0;
          end else begin
            tx_idx <= tx_idx + 1;
          end
        end
      end else begin
        s_axis_tvalid <= 1'b0;
        s_axis_tlast <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (aresetn && m_axis_tvalid && m_axis_tready) begin
      $fdisplay(fd_out, "%012X", m_axis_tdata);
      rx_cnt <= rx_cnt + 1;
    end
  end

  always @(posedge clk) begin
    if (!aresetn) begin
      last_seen <= 1'b0;
      finish_armed <= 1'b0;
      post_last_cnt <= 0;
    end else begin
      if (m_axis_tvalid && m_axis_tready && m_axis_tlast) begin
        last_seen <= 1'b1;
      end

      if (last_seen && !m_axis_tlast && !finish_armed) begin
        finish_armed <= 1'b1;
        post_last_cnt <= 0;
      end

      if (finish_armed) begin
        if (post_last_cnt >= 10) begin
          $fclose(fd_out);
          $display("TB_DONE rx_cnt=%0d", rx_cnt);
          $finish;
        end else begin
          post_last_cnt <= post_last_cnt + 1;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (!aresetn) begin
      cycle_cnt <= 0;
    end else begin
      cycle_cnt <= cycle_cnt + 1;
      if (cycle_cnt >= TIMEOUT_CYCLES) begin
        $fclose(fd_out);
        $display("TB_TIMEOUT cycle=%0d tx=%0d rx=%0d", cycle_cnt, tx_idx, rx_cnt);
        $finish;
      end
    end
  end

endmodule
