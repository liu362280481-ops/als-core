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

  localparam logic signed [15:0] K_REACT_Q8_8 = 16'sd2;
  localparam logic signed [15:0] P_DECAY_Q8_8 = 16'sd1;

  logic [15:0] s_cur_u, p_cur_u, m_cur_u;
  logic [7:0]  hill_addr, addr_raw;
  logic [15:0] hill_q8_8_u;

  logic signed [31:0] mul_s_hill_comb, mul_s_hill_reg, s_hill_q8_8;
  logic signed [31:0] mul_growth_gain, p_growth_wide;
  logic signed [31:0] mul_decay, p_decay_wide;
  logic signed [31:0] s_next_wide, p_next_wide;

  logic [15:0] s_next_u, p_next_u;
  logic [15:0] s_cur_u_d1, p_cur_u_d1, m_cur_u_d1;
  logic        s_axis_tlast_d1;
  logic        stage1_valid;

  logic fire_in, pipe_ce;

  hill_lut u_hill_lut (.addr(hill_addr), .data_q8_8(hill_q8_8_u));

  function automatic logic [15:0] clip_u16_nonneg_q8_8(input logic signed [31:0] v);
    begin
      if (v < 0)              clip_u16_nonneg_q8_8 = 16'd0;
      else if (v > 32'sd32767) clip_u16_nonneg_q8_8 = 16'h7fff;
      else                    clip_u16_nonneg_q8_8 = v[15:0];
    end
  endfunction

  assign s_cur_u = s_axis_tdata[47:32];
  assign p_cur_u = s_axis_tdata[31:16];
  assign m_cur_u = s_axis_tdata[15:0];

  // 高精度饱和寻址：截取1位整数+7位小数，过载时饱和到255
  assign addr_raw = p_cur_u[14:7];
  assign hill_addr = (p_cur_u[15] || (p_cur_u[15:8] >= 8'd2)) ? 8'd255 : addr_raw;

  assign pipe_ce = (~m_axis_tvalid) | m_axis_tready;
  assign s_axis_tready = pipe_ce;
  assign fire_in = s_axis_tvalid & s_axis_tready;

  always_comb begin
    mul_s_hill_comb = $signed({1'b0, s_cur_u}) * $signed({1'b0, hill_q8_8_u});
    s_hill_q8_8     = mul_s_hill_reg >>> 8;
    mul_growth_gain = s_hill_q8_8 * $signed(K_REACT_Q8_8);
    p_growth_wide   = mul_growth_gain >>> 8;

    mul_decay     = $signed({1'b0, p_cur_u_d1}) * $signed(P_DECAY_Q8_8);
    p_decay_wide  = mul_decay >>> 8;

    s_next_wide   = $signed({1'b0, s_cur_u_d1}) - p_growth_wide;
    p_next_wide   = $signed({1'b0, p_cur_u_d1}) + p_growth_wide - p_decay_wide;

    s_next_u      = clip_u16_nonneg_q8_8(s_next_wide);
    p_next_u      = clip_u16_nonneg_q8_8(p_next_wide);
  end

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      mul_s_hill_reg <= '0;
      s_cur_u_d1 <= '0; p_cur_u_d1 <= '0; m_cur_u_d1 <= '0;
      s_axis_tlast_d1 <= 1'b0; stage1_valid <= 1'b0;
      m_axis_tdata <= '0; m_axis_tvalid <= 1'b0; m_axis_tlast <= 1'b0;
    end else if (pipe_ce) begin
      m_axis_tvalid <= stage1_valid;
      stage1_valid  <= fire_in;

      if (fire_in) begin
        mul_s_hill_reg <= mul_s_hill_comb;
        s_cur_u_d1 <= s_cur_u; p_cur_u_d1 <= p_cur_u; m_cur_u_d1 <= m_cur_u;
        s_axis_tlast_d1 <= s_axis_tlast;
      end

      if (stage1_valid) begin
        m_axis_tdata <= {s_next_u, p_next_u, m_cur_u_d1};
        m_axis_tlast <= s_axis_tlast_d1;
      end
    end
  end

endmodule
