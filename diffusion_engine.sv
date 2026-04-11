`timescale 1ns/1ps

module diffusion_engine (
  input  logic         aclk,
  input  logic         aresetn,

  input  logic [47:0]  s_axis_tdata,
  input  logic         s_axis_tvalid,
  output logic         s_axis_tready,
  input  logic         s_axis_tlast,

  output logic [47:0]  m_axis_tdata,
  output logic         m_axis_tvalid,
  input  logic         m_axis_tready,
  output logic         m_axis_tlast
);

  localparam int GRID_W = 128;
  localparam int GRID_H = 128;

  localparam logic signed [15:0] D_S_Q8_8 = 16'sd51;
  localparam logic signed [15:0] D_P_Q8_8 = 16'sd0;
  localparam logic signed [15:0] D_M_Q8_8 = 16'sd0;

  // === LINE BUFFERS ===
  logic [47:0] linebuf0 [0:GRID_W-1];
  logic [47:0] linebuf1 [0:GRID_W-1];

  // === SHIFT REGISTERS (3-deep for left/center/right neighbors) ===
  logic [47:0] top_l, top_c, top_r;
  logic [47:0] mid_l, mid_c, mid_r;
  logic [47:0] bot_l, bot_c, bot_r;
  logic [47:0] tap_top, tap_mid, tap_bot;

  // === COUNTERS ===
  logic [6:0] col_cnt;
  logic [6:0] row_cnt;
  logic [6:0] out_col;
  logic [6:0] out_row;
  logic       out_col_valid;
  logic       out_row_valid;

  // === NEIGHBOR FIELDS ===
  logic signed [15:0] s_up, s_dn, s_lt, s_rt, s_ce;
  logic signed [15:0] p_up, p_dn, p_lt, p_rt, p_ce;
  logic signed [15:0] m_up, m_dn, m_lt, m_rt, m_ce;

  // === ARITHMETIC ===
  logic signed [19:0] lap_s, lap_p, lap_m;
  logic signed [35:0] mul_s, mul_p, mul_m;
  logic signed [35:0] nxt_s_wide, nxt_p_wide, nxt_m_wide;
  logic signed [15:0] s_next, p_next, m_next;

  // === CONTROL ===
  logic fire_in;

  // === FUNCTIONS ===
  function automatic logic signed [15:0] clip_nonneg_q8_8(input logic signed [35:0] v);
    logic signed [35:0] vmax;
    begin
      vmax = 36'sd32767;
      if (v < 0)         clip_nonneg_q8_8 = 16'sd0;
      else if (v > vmax) clip_nonneg_q8_8 = 16'h7fff;
      else               clip_nonneg_q8_8 = v[15:0];
    end
  endfunction

  function automatic logic signed [19:0] lap5(
    input logic signed [15:0] up,
    input logic signed [15:0] dn,
    input logic signed [15:0] lt,
    input logic signed [15:0] rt,
    input logic signed [15:0] ce
  );
    logic signed [19:0] sum4;
    logic signed [19:0] c4;
    begin
      sum4 = $signed(up) + $signed(dn) + $signed(lt) + $signed(rt);
      c4   = $signed(ce) <<< 2;
      lap5 = sum4 - c4;
    end
  endfunction

  function automatic logic signed [15:0] field_s(input logic [47:0] w);
    field_s = $signed(w[47:32]);
  endfunction

  function automatic logic signed [15:0] field_p(input logic [47:0] w);
    field_p = $signed(w[31:16]);
  endfunction

  function automatic logic signed [15:0] field_m(input logic [47:0] w);
    field_m = $signed(w[15:0]);
  endfunction

  // === COMBINATORIAL ===
  assign s_axis_tready = (~m_axis_tvalid) | m_axis_tready;
  assign fire_in = s_axis_tvalid & s_axis_tready;

  always_comb begin
    out_col_valid = (col_cnt != 0);
    out_row_valid = (row_cnt != 0);
    out_col       = col_cnt - 7'd2;
    out_row       = row_cnt - 7'd1;

    tap_top = linebuf0[col_cnt];
    tap_mid = linebuf1[col_cnt];
    tap_bot = s_axis_tdata;

    s_ce = field_s(mid_c);
    s_up = (out_row_valid && out_row != 0)              ? field_s(top_c) : 16'sd0;
    s_dn = (out_row_valid && out_row != (GRID_H-1))     ? field_s(bot_c) : 16'sd0;
    s_lt = (out_col_valid && out_col != 0)               ? field_s(mid_l) : 16'sd0;
    s_rt = (out_col_valid && out_col != (GRID_W-1))      ? field_s(mid_r) : 16'sd0;

    p_ce = field_p(mid_c);
    p_up = (out_row_valid && out_row != 0)              ? field_p(top_c) : 16'sd0;
    p_dn = (out_row_valid && out_row != (GRID_H-1))     ? field_p(bot_c) : 16'sd0;
    p_lt = (out_col_valid && out_col != 0)               ? field_p(mid_l) : 16'sd0;
    p_rt = (out_col_valid && out_col != (GRID_W-1))      ? field_p(mid_r) : 16'sd0;

    m_ce = field_m(mid_c);
    m_up = (out_row_valid && out_row != 0)              ? field_m(top_c) : 16'sd0;
    m_dn = (out_row_valid && out_row != (GRID_H-1))     ? field_m(bot_c) : 16'sd0;
    m_lt = (out_col_valid && out_col != 0)               ? field_m(mid_l) : 16'sd0;
    m_rt = (out_col_valid && out_col != (GRID_W-1))      ? field_m(mid_r) : 16'sd0;

    lap_s = lap5(s_up, s_dn, s_lt, s_rt, s_ce);
    lap_p = lap5(p_up, p_dn, p_lt, p_rt, p_ce);
    lap_m = lap5(m_up, m_dn, m_lt, m_rt, m_ce);

    mul_s = $signed(lap_s) * $signed(D_S_Q8_8);
    mul_p = $signed(lap_p) * $signed(D_P_Q8_8);
    mul_m = $signed(lap_m) * $signed(D_M_Q8_8);

    nxt_s_wide = $signed(s_ce) + ($signed(mul_s) >>> 8);
    nxt_p_wide = $signed(p_ce) + ($signed(mul_p) >>> 8);
    nxt_m_wide = $signed(m_ce) + ($signed(mul_m) >>> 8);

    s_next = clip_nonneg_q8_8(nxt_s_wide);
    p_next = clip_nonneg_q8_8(nxt_p_wide);
    m_next = clip_nonneg_q8_8(nxt_m_wide);
  end

  // === SEQUENTIAL ===
  // Generate-based async reset for line buffers (Verilator-compatible)
  for (genvar ii = 0; ii < GRID_W; ii++) begin : GEN_LB_RESET0
    always_ff @(posedge aclk) begin
      if (!aresetn) linebuf0[ii] <= '0;
    end
  end
  for (genvar ii = 0; ii < GRID_W; ii++) begin : GEN_LB_RESET1
    always_ff @(posedge aclk) begin
      if (!aresetn) linebuf1[ii] <= '0;
    end
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      top_l <= '0; top_c <= '0; top_r <= '0;
      mid_l <= '0; mid_c <= '0; mid_r <= '0;
      bot_l <= '0; bot_c <= '0; bot_r <= '0;
      col_cnt <= '0;
      row_cnt <= '0;
      m_axis_tdata  <= '0;
      m_axis_tvalid <= 1'b0;
      m_axis_tlast  <= 1'b0;
    end else begin
      if (m_axis_tvalid && m_axis_tready) begin
        m_axis_tvalid <= 1'b0;
      end

      if (fire_in) begin
        linebuf0[col_cnt] <= linebuf1[col_cnt];
        linebuf1[col_cnt] <= s_axis_tdata;

        top_l <= top_c;  top_c <= top_r;  top_r <= tap_top;
        mid_l <= mid_c;  mid_c <= mid_r;  mid_r <= tap_mid;
        bot_l <= bot_c;  bot_c <= bot_r;  bot_r <= tap_bot;

        m_axis_tdata  <= {s_next, p_next, m_next};
        m_axis_tvalid <= 1'b1;
        m_axis_tlast  <= (out_row == (GRID_H-1)) && (out_col == (GRID_W-1));

        if (col_cnt == (GRID_W-1)) begin
          col_cnt <= 7'd0;
          row_cnt <= (row_cnt == (GRID_H-1)) ? 7'd0 : row_cnt + 7'd1;
        end else begin
          col_cnt <= col_cnt + 7'd1;
        end
      end
    end
  end

endmodule
