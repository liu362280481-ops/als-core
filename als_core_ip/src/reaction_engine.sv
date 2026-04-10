`timescale 1ns/1ps

module reaction_engine (
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

  // Q8.8 reaction coefficients
  // Effective growth gain (K1*DT ~= 0.006 -> ~2/256)
  localparam logic signed [15:0] K_REACT_Q8_8 = 16'sd2;
  // Effective decay gain (P_DECAY*DT ~= 0.005 -> ~1/256)
  localparam logic signed [15:0] P_DECAY_Q8_8 = 16'sd1;

  logic [15:0] s_cur_u;
  logic [15:0] p_cur_u;
  logic [15:0] m_cur_u;

  logic [7:0]  hill_addr;
  logic [15:0] hill_q8_8_u;

  logic signed [31:0] mul_s_hill_comb;
  logic signed [31:0] mul_s_hill_reg;
  logic signed [31:0] s_hill_q8_8;
  logic signed [31:0] mul_growth_gain;
  logic signed [31:0] p_growth_wide;

  logic signed [31:0] mul_decay;
  logic signed [31:0] p_decay_wide;

  logic signed [31:0] s_next_wide;
  logic signed [31:0] p_next_wide;

  logic [15:0] s_next_u;
  logic [15:0] p_next_u;

  logic [15:0] s_cur_u_d1;
  logic [15:0] p_cur_u_d1;
  logic [15:0] m_cur_u_d1;
  logic        s_axis_tlast_d1;
  logic        stage1_valid;

  logic fire_in;

  hill_lut u_hill_lut (
    .addr     (hill_addr),
    .data_q8_8(hill_q8_8_u)
  );

  function automatic logic [15:0] clip_u16_nonneg_q8_8(input logic signed [31:0] v);
    begin
      if (v < 0) begin
        clip_u16_nonneg_q8_8 = 16'd0;
      end else if (v > 32'sd32767) begin
        clip_u16_nonneg_q8_8 = 16'h7fff;
      end else begin
        clip_u16_nonneg_q8_8 = v[15:0];
      end
    end
  endfunction

  assign s_cur_u = s_axis_tdata[47:32];
  assign p_cur_u = s_axis_tdata[31:16];
  assign m_cur_u = s_axis_tdata[15:0];

  // Architect Fix: Map fractional part [7:0] to 256-depth ROM, saturate at 1.0 (255)
  assign hill_addr = p_cur_u[15] ? 8'd0 : (p_cur_u >= 16'h0100) ? 8'd255 : p_cur_u[7:0];
  assign fire_in = s_axis_tvalid & s_axis_tready;

  // Backpressure-safe causality: accept new input only when output can advance.
  assign s_axis_tready = (~m_axis_tvalid) | m_axis_tready;

  always_comb begin
    mul_s_hill_comb = $signed({1'b0, s_cur_u}) * $signed({1'b0, hill_q8_8_u});    // Q16.16
    s_hill_q8_8     = mul_s_hill_reg >>> 8;                                         // Q8.8
    mul_growth_gain = s_hill_q8_8 * $signed(K_REACT_Q8_8);                         // Q16.16
    p_growth_wide   = mul_growth_gain >>> 8;                                        // Q8.8

    mul_decay     = $signed({1'b0, p_cur_u_d1}) * $signed(P_DECAY_Q8_8);           // Q16.16
    p_decay_wide  = mul_decay >>> 8;                                                // Q8.8

    s_next_wide   = $signed({1'b0, s_cur_u_d1}) - p_growth_wide;                    // Q8.8
    p_next_wide   = $signed({1'b0, p_cur_u_d1}) + p_growth_wide - p_decay_wide;     // Q8.8

    s_next_u      = clip_u16_nonneg_q8_8(s_next_wide);
    p_next_u      = clip_u16_nonneg_q8_8(p_next_wide);
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      mul_s_hill_reg <= '0;
      s_cur_u_d1     <= '0;
      p_cur_u_d1     <= '0;
      m_cur_u_d1     <= '0;
      s_axis_tlast_d1<= 1'b0;
      stage1_valid   <= 1'b0;
      m_axis_tdata  <= '0;
      m_axis_tvalid <= 1'b0;
      m_axis_tlast  <= 1'b0;
    end else begin
      if (m_axis_tvalid && m_axis_tready) begin
        m_axis_tvalid <= 1'b0;
      end

      if (fire_in) begin
        mul_s_hill_reg  <= mul_s_hill_comb;
        s_cur_u_d1      <= s_cur_u;
        p_cur_u_d1      <= p_cur_u;
        m_cur_u_d1      <= m_cur_u;
        s_axis_tlast_d1 <= s_axis_tlast;
        stage1_valid    <= 1'b1;
      end

      if (stage1_valid && ((~m_axis_tvalid) || m_axis_tready)) begin
        m_axis_tdata  <= {s_next_u, p_next_u, m_cur_u_d1};
        m_axis_tvalid <= 1'b1;
        m_axis_tlast  <= s_axis_tlast_d1;
        stage1_valid  <= 1'b0;
      end
    end
  end

endmodule
