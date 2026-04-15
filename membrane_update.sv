`timescale 1ns/1ps

module membrane_update #(
  parameter int GRID_W = 128,
  parameter int GRID_H = 128,
  parameter logic signed [15:0] K_GROWTH_Q8_8  = 16'sd384,
  parameter logic signed [15:0] K_DECAY_M_Q8_8 = 16'sd26
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

  localparam int NUM_CELLS = GRID_W * GRID_H; // 16384

  localparam logic signed [15:0] Q8_8_ONE = 16'sd256;

  // === LINE BUFFERS ===
  logic [47:0] linebuf0 [0:GRID_W-1];
  logic [47:0] linebuf1 [0:GRID_W-1];

  // === SHIFT REGISTERS ===
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

  // === PIPELINE REGISTERS ===
  logic signed [31:0] mul_s_b_reg;
  logic signed [31:0] mul_sat_nb_reg;
  logic signed [63:0] mul_comb_reg;
  logic signed [63:0] mul_final_reg;
  logic signed [31:0] growth_q8_8;
  logic signed [31:0] decay_q8_8_comb;
  logic signed [31:0] decay_q8_8_d1, decay_q8_8_d2, decay_q8_8_d3;

  logic signed [15:0] s_center_d1, s_center_d2, s_center_d3;
  logic signed [15:0] p_center_d1, p_center_d2, p_center_d3;
  logic signed [15:0] m_center_d1, m_center_d2, m_center_d3;

  logic               vld_d1, vld_d2, vld_d3;
  logic               tlast_d1, tlast_d2, tlast_d3;

  // === COMBINATORIAL ARITHMETIC ===
  logic signed [15:0] s_center, p_center, m_center;
  logic signed [15:0] p_up, p_dn, p_lt, p_rt;
  logic signed [15:0] m_up, m_dn, m_lt, m_rt;
  logic signed [19:0] p_nb_sum4, m_nb_sum4;
  logic signed [15:0] p_nb_avg, m_nb_avg;
  logic signed [15:0] boundary_q8_8;
  logic signed [15:0] sat_inhibit_q8_8;
  logic signed [15:0] nb_inhibit_q8_8;
  logic signed [31:0] decay_mul;
  logic signed [31:0] m_next_wide;
  logic signed [15:0] m_next_q8_8;

  logic               pipe_ce;
  logic               fire_in;

  // === FLUSH STATE MACHINE (NEW) ===
  logic               flush_mode;
  logic [13:0]       out_pixel_cnt;  // 0..16383

  // === INTERMEDIATE CORE OUTPUTS ===
  logic               core_valid_out;
  logic [47:0]       core_data_out;

  // === FUNCTIONS ===
  function automatic logic signed [15:0] clip_nonneg_q8_8(input logic signed [31:0] v);
    begin
      if (v < 0)              clip_nonneg_q8_8 = 16'sd0;
      else if (v > 32'sd32767) clip_nonneg_q8_8 = 16'h7fff;
      else if (v < 32'sd1)   clip_nonneg_q8_8 = 16'sd0;
      else                    clip_nonneg_q8_8 = v[15:0];
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

  // === CONTROL ===
  assign pipe_ce = (~m_axis_tvalid) | m_axis_tready;
  assign s_axis_tready = pipe_ce;
  assign fire_in = s_axis_tvalid & s_axis_tready;

  // === COMBINATORIAL: pure arithmetic, no storage ===
  always_comb begin
    out_col_valid = (col_cnt != 0);
    out_row_valid = (row_cnt != 0);
    out_col       = col_cnt - 7'd2;
    out_row       = row_cnt - 7'd1;

    tap_top = linebuf0[col_cnt];
    tap_mid = linebuf1[col_cnt];
    tap_bot = s_axis_tdata;

    s_center = fs(mid_c);
    p_center = fp(mid_c);
    m_center = fm(mid_c);

    p_up = (out_row_valid && out_row != 0)            ? fp(top_c) : 16'sd0;
    p_dn = (out_row_valid && out_row != (GRID_H-1))   ? fp(bot_c) : 16'sd0;
    p_lt = (out_col_valid && out_col != 0)            ? fp(mid_l) : 16'sd0;
    p_rt = (out_col_valid && out_col != (GRID_W-1))    ? fp(mid_r) : 16'sd0;

    m_up = (out_row_valid && out_row != 0)            ? fm(top_c) : 16'sd0;
    m_dn = (out_row_valid && out_row != (GRID_H-1))   ? fm(bot_c) : 16'sd0;
    m_lt = (out_col_valid && out_col != 0)            ? fm(mid_l) : 16'sd0;
    m_rt = (out_col_valid && out_col != (GRID_W-1))    ? fm(mid_r) : 16'sd0;

    p_nb_sum4    = $signed(p_up) + $signed(p_dn) + $signed(p_lt) + $signed(p_rt);
    p_nb_avg     = p_nb_sum4[19:2];
    boundary_q8_8 = (p_center > p_nb_avg) ? (p_center - p_nb_avg) : 16'sd0;

    sat_inhibit_q8_8 = (Q8_8_ONE > m_center) ? (Q8_8_ONE - m_center) : 16'sd0;

    m_nb_sum4    = $signed(m_up) + $signed(m_dn) + $signed(m_lt) + $signed(m_rt);
    m_nb_avg     = m_nb_sum4[19:2];
    nb_inhibit_q8_8 = (Q8_8_ONE > m_nb_avg) ? (Q8_8_ONE - m_nb_avg) : 16'sd0;

    decay_mul       = $signed(K_DECAY_M_Q8_8) * $signed(m_center);
    decay_q8_8_comb = decay_mul >>> 8;

    m_next_wide = $signed(m_center_d3) + $signed(growth_q8_8) - $signed(decay_q8_8_d3);
    m_next_q8_8 = clip_nonneg_q8_8(m_next_wide);
  end

  // === INTERMEDIATE CORE OUTPUT (captured at pipe_ce) ===
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      core_valid_out <= 1'b0;
      core_data_out  <= '0;
    end else if (pipe_ce) begin
      if (vld_d3) begin
        core_valid_out <= 1'b1;
        core_data_out  <= {s_center_d3[15:0], p_center_d3[15:0], m_next_q8_8[15:0]};
      end else begin
        core_valid_out <= 1'b0;
        core_data_out  <= '0;
      end
    end
  end

  // === FLUSH STATE MACHINE ===
  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      flush_mode     <= 1'b0;
      out_pixel_cnt  <= 14'd0;
    end else begin
      // Catch the last input beat: input tvalid + tready + tlast
      if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
        flush_mode <= 1'b1;
      end

      // On successful output handshake
      if (m_axis_tvalid && m_axis_tready) begin
        if (out_pixel_cnt == 14'd16383) begin
          out_pixel_cnt  <= 14'd0;
          flush_mode     <= 1'b0;  // Drain complete, loop closed
        end else begin
          out_pixel_cnt <= out_pixel_cnt + 1'b1;
        end
      end
    end
  end

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

      mul_s_b_reg    <= '0;
      mul_sat_nb_reg <= '0;
      mul_comb_reg   <= '0;
      mul_final_reg  <= '0;
      growth_q8_8    <= '0;

      s_center_d1 <= '0; s_center_d2 <= '0; s_center_d3 <= '0;
      p_center_d1 <= '0; p_center_d2 <= '0; p_center_d3 <= '0;
      m_center_d1 <= '0; m_center_d2 <= '0; m_center_d3 <= '0;
      decay_q8_8_d1 <= '0; decay_q8_8_d2 <= '0; decay_q8_8_d3 <= '0;
      vld_d1 <= 1'b0; vld_d2 <= 1'b0; vld_d3 <= 1'b0;
      tlast_d1 <= 1'b0; tlast_d2 <= 1'b0; tlast_d3 <= 1'b0;

      // NOTE: m_axis_tdata/tvalid/tlast are NO LONGER driven here.
      // They are now driven by module-level assign statements (see below).

    end else begin
      // ---- Line buffer updates (on fire_in) ----
      if (fire_in) begin
        linebuf0[col_cnt] <= linebuf1[col_cnt];
        linebuf1[col_cnt] <= s_axis_tdata;

        top_l <= top_c;  top_c <= top_r;  top_r <= tap_top;
        mid_l <= mid_c;  mid_c <= mid_r;  mid_r <= tap_mid;
        bot_l <= bot_c;  bot_c <= bot_r;  bot_r <= tap_bot;

        mul_s_b_reg     <= $signed(s_center) * $signed(boundary_q8_8);
        mul_sat_nb_reg  <= $signed(sat_inhibit_q8_8) * $signed(nb_inhibit_q8_8);
        s_center_d1     <= s_center;
        p_center_d1     <= p_center;
        m_center_d1     <= m_center;
        decay_q8_8_d1  <= decay_q8_8_comb;

        if (col_cnt == (GRID_W-1)) begin
          col_cnt <= 7'd0;
          row_cnt <= (row_cnt == (GRID_H-1)) ? 7'd0 : row_cnt + 7'd1;
        end else begin
          col_cnt <= col_cnt + 7'd1;
        end
      end

      // ---- Pipeline advances (on pipe_ce) ----
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

        mul_comb_reg  <= $signed(mul_s_b_reg) * $signed(mul_sat_nb_reg);
        mul_final_reg <= $signed(mul_comb_reg) * $signed(K_GROWTH_Q8_8);
        growth_q8_8   <= mul_final_reg[63:32];

        // NOTE: Output driving has been MOVED to module-level assign statements.
        // The always_ff block no longer drives m_axis_* signals.
      end
    end
  end

  //=== ABSOLUTE LAW: Output binding (replaces procedural assignments) ===
  // TLAST: asserted on the very last pixel of the drain sequence
  assign m_axis_tlast  = (out_pixel_cnt == 14'd16383);

  // TVALID: asserted when either core has data OR flush mode is active
  assign m_axis_tvalid = core_valid_out | flush_mode;

  // TDATA: core data when available, otherwise zero-padding during flush
  assign m_axis_tdata  = (flush_mode && !core_valid_out) ? 48'd0 : core_data_out;

endmodule
