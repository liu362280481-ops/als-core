`timescale 1ns/1ps

module membrane_update #(
  parameter int GRID_W = 128,
  parameter int GRID_H = 128,
  parameter logic signed [15:0] K_GROWTH_Q8_8  = 16'sd384, // 1.5
  parameter logic signed [15:0] K_DECAY_M_Q8_8 = 16'sd26   // 0.1
) (
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

  localparam logic signed [15:0] Q8_8_ONE = 16'sd256; // 1.0

  logic [47:0] linebuf0 [0:GRID_W-1];
  logic [47:0] linebuf1 [0:GRID_W-1];

  logic [47:0] top_l, top_c, top_r;
  logic [47:0] mid_l, mid_c, mid_r;
  logic [47:0] bot_l, bot_c, bot_r;
  logic [47:0] tap_top, tap_mid, tap_bot;

  logic [6:0] col_cnt;
  logic [6:0] row_cnt;
  logic [6:0] out_col;
  logic [6:0] out_row;
  logic       out_col_valid;
  logic       out_row_valid;

  logic signed [15:0] s_center, p_center, m_center;
  logic signed [15:0] p_up, p_dn, p_lt, p_rt;
  logic signed [15:0] m_up, m_dn, m_lt, m_rt;

  logic signed [19:0] p_nb_sum4;
  logic signed [15:0] p_nb_avg;
  logic signed [19:0] boundary_raw;
  logic signed [15:0] boundary_q8_8;

  logic signed [19:0] m_nb_sum4;
  logic signed [15:0] m_nb_avg;
  logic signed [19:0] sat_raw;
  logic signed [19:0] nb_raw;
  logic signed [15:0] sat_inhibit_q8_8;
  logic signed [15:0] nb_inhibit_q8_8;

  logic signed [31:0] mul_s_b_reg;
  logic signed [31:0] mul_sat_nb_reg;
  logic signed [63:0] mul_comb_reg;
  logic signed [63:0] mul_final_reg;
  logic signed [31:0] growth_q8_8;
  logic signed [31:0] decay_mul;
  logic signed [31:0] decay_q8_8;
  logic signed [31:0] m_next_wide;
  logic signed [15:0] m_next_q8_8;

  logic signed [15:0] s_center_d1, s_center_d2, s_center_d3;
  logic signed [15:0] p_center_d1, p_center_d2, p_center_d3;
  logic signed [15:0] m_center_d1, m_center_d2, m_center_d3;
  logic signed [31:0] decay_q8_8_d1, decay_q8_8_d2, decay_q8_8_d3;
  logic               vld_d1, vld_d2, vld_d3;
  logic               tlast_d1, tlast_d2, tlast_d3;
  logic               pipe_ce;

  logic fire_in;

  function automatic logic signed [15:0] clip_nonneg_q8_8(input logic signed [31:0] v);
    begin
      if (v < 0) begin
        clip_nonneg_q8_8 = 16'sd0;
      end else if (v > 32'sd32767) begin
        clip_nonneg_q8_8 = 16'sh7fff;
      end else if (v < 32'sd1) begin
        // remove sub-1/256 thermodynamic noise
        clip_nonneg_q8_8 = 16'sd0;
      end else begin
        clip_nonneg_q8_8 = v[15:0];
      end
    end
  endfunction

  function automatic logic signed [15:0] fs(input logic [47:0] w);
    fs = $signed(w[47:32]);
  endfunction

  function automatic logic signed [15:0] fp(input logic [47:0] w);
    fp = $signed(w[31:16]);
  endfunction

  function automatic logic signed [15:0] fm(input logic [47:0] w);
    fm = $signed(w[15:0]);
  endfunction

  assign pipe_ce = (~m_axis_tvalid) | m_axis_tready;
  assign s_axis_tready = pipe_ce;
  assign fire_in = s_axis_tvalid & s_axis_tready;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      integer i;
      for (i = 0; i < GRID_W; i = i + 1) begin
        linebuf0[i] <= '0;
        linebuf1[i] <= '0;
      end

      top_l <= '0; top_c <= '0; top_r <= '0;
      mid_l <= '0; mid_c <= '0; mid_r <= '0;
      bot_l <= '0; bot_c <= '0; bot_r <= '0;

      col_cnt <= '0;
      row_cnt <= '0;

      mul_s_b_reg    <= '0;
      mul_sat_nb_reg <= '0;
      mul_comb_reg   <= '0;
      mul_final_reg  <= '0;
      growth_q8_8    <= '0;
      decay_mul      <= '0;
      decay_q8_8     <= '0;

      s_center_d1    <= '0; s_center_d2 <= '0; s_center_d3 <= '0;
      p_center_d1    <= '0; p_center_d2 <= '0; p_center_d3 <= '0;
      m_center_d1    <= '0; m_center_d2 <= '0; m_center_d3 <= '0;
      decay_q8_8_d1  <= '0; decay_q8_8_d2 <= '0; decay_q8_8_d3 <= '0;
      vld_d1         <= 1'b0; vld_d2 <= 1'b0; vld_d3 <= 1'b0;
      tlast_d1       <= 1'b0; tlast_d2 <= 1'b0; tlast_d3 <= 1'b0;

      m_axis_tdata  <= '0;
      m_axis_tvalid <= 1'b0;
      m_axis_tlast  <= 1'b0;
    end else begin
      if (pipe_ce) begin
        vld_d3       <= vld_d2;
        vld_d2       <= vld_d1;
        vld_d1       <= fire_in;
        tlast_d3     <= tlast_d2;
        tlast_d2     <= tlast_d1;
        tlast_d1     <= s_axis_tlast;
        s_center_d3  <= s_center_d2;
        s_center_d2  <= s_center_d1;
        p_center_d3  <= p_center_d2;
        p_center_d2  <= p_center_d1;
        m_center_d3  <= m_center_d2;
        m_center_d2  <= m_center_d1;
        decay_q8_8_d3<= decay_q8_8_d2;
        decay_q8_8_d2<= decay_q8_8_d1;

        mul_comb_reg  <= $signed(mul_s_b_reg) * $signed(mul_sat_nb_reg);            // Stage 2
        mul_final_reg <= $signed(mul_comb_reg) * $signed(K_GROWTH_Q8_8);            // Stage 3
        growth_q8_8   <= $signed(mul_final_reg) >>> 32;

        if (vld_d3) begin
          m_next_wide = $signed(m_center_d3) + $signed(growth_q8_8) - $signed(decay_q8_8_d3);
          m_next_q8_8 = clip_nonneg_q8_8(m_next_wide);
          m_axis_tdata  <= {s_center_d3[15:0], p_center_d3[15:0], m_next_q8_8[15:0]};
          m_axis_tvalid <= 1'b1;
          m_axis_tlast  <= tlast_d3;
        end else begin
          m_axis_tvalid <= 1'b0;
        end
      end

      if (fire_in) begin
        tap_top = linebuf0[col_cnt];
        tap_mid = linebuf1[col_cnt];
        tap_bot = s_axis_tdata;

        linebuf0[col_cnt] <= linebuf1[col_cnt];
        linebuf1[col_cnt] <= s_axis_tdata;

        top_l <= top_c;
        top_c <= top_r;
        top_r <= tap_top;

        mid_l <= mid_c;
        mid_c <= mid_r;
        mid_r <= tap_mid;

        bot_l <= bot_c;
        bot_c <= bot_r;
        bot_r <= tap_bot;

        out_col_valid = (col_cnt != 0);
        out_row_valid = (row_cnt != 0);
        // Architect Fix: Synchronize physical coordinates with line buffer 2-cycle latency
        out_col       = col_cnt - 7'd2;
        out_row       = row_cnt - 7'd1;

        s_center = fs(mid_c);
        p_center = fp(mid_c);
        m_center = fm(mid_c);

        p_up = ((out_row_valid && (out_row != 0))          ? fp(top_c) : 16'sd0);
        p_dn = ((out_row_valid && (out_row != (GRID_H-1))) ? fp(bot_c) : 16'sd0);
        p_lt = ((out_col_valid && (out_col != 0))          ? fp(mid_l) : 16'sd0);
        p_rt = ((out_col_valid && (out_col != (GRID_W-1))) ? fp(mid_r) : 16'sd0);

        m_up = ((out_row_valid && (out_row != 0))          ? fm(top_c) : 16'sd0);
        m_dn = ((out_row_valid && (out_row != (GRID_H-1))) ? fm(bot_c) : 16'sd0);
        m_lt = ((out_col_valid && (out_col != 0))          ? fm(mid_l) : 16'sd0);
        m_rt = ((out_col_valid && (out_col != (GRID_W-1))) ? fm(mid_r) : 16'sd0);

        // boundary = max(P_center - avg(P_neighbors), 0)
        p_nb_sum4   = $signed(p_up) + $signed(p_dn) + $signed(p_lt) + $signed(p_rt);
        p_nb_avg    = p_nb_sum4[19:2]; // divide by 4
        boundary_raw = $signed(p_center) - $signed(p_nb_avg);
        if (boundary_raw > 0) begin
          boundary_q8_8 = boundary_raw[15:0];
        end else begin
          boundary_q8_8 = 16'sd0;
        end

        // sat_inhibit = max(1.0 - M_center, 0)
        sat_raw = $signed(Q8_8_ONE) - $signed(m_center);
        if (sat_raw > 0) begin
          sat_inhibit_q8_8 = sat_raw[15:0];
        end else begin
          sat_inhibit_q8_8 = 16'sd0;
        end

        // nb_inhibit = max(1.0 - avg(M_neighbors), 0)
        m_nb_sum4 = $signed(m_up) + $signed(m_dn) + $signed(m_lt) + $signed(m_rt);
        m_nb_avg  = m_nb_sum4[19:2];
        nb_raw    = $signed(Q8_8_ONE) - $signed(m_nb_avg);
        if (nb_raw > 0) begin
          nb_inhibit_q8_8 = nb_raw[15:0];
        end else begin
          nb_inhibit_q8_8 = 16'sd0;
        end

        // decay = K_DECAY_M * M_center
        decay_mul   = $signed(K_DECAY_M_Q8_8) * $signed(m_center);            // Q16.16
        decay_q8_8  = $signed(decay_mul) >>> 8;                                // Q8.8

        // Stage 1: register products and aligned center fields for 3-cycle pipeline
        mul_s_b_reg     <= $signed(s_center) * $signed(boundary_q8_8);              // Q16.16
        mul_sat_nb_reg  <= $signed(sat_inhibit_q8_8) * $signed(nb_inhibit_q8_8);    // Q16.16
        s_center_d1     <= s_center;
        p_center_d1     <= p_center;
        m_center_d1     <= m_center;
        decay_q8_8_d1   <= decay_q8_8;

        if (col_cnt == GRID_W-1) begin
          col_cnt <= 7'd0;
          if (row_cnt == GRID_H-1) begin
            row_cnt <= 7'd0;
          end else begin
            row_cnt <= row_cnt + 7'd1;
          end
        end else begin
          col_cnt <= col_cnt + 7'd1;
        end
      end
    end
  end

endmodule
