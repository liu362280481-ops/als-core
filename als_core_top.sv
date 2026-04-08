`timescale 1ns/1ps

// als_core_top.sv — 三引擎串联顶层
// Diffusion → Reaction → Membrane
// 数据流：s_axis → diffusion_engine → reaction_engine → membrane_update → m_axis

module als_core_top (
  input  logic        aclk,
  input  logic        aresetn,

  input  logic [47:0] s_axis_tdata,
  input  logic        s_axis_tvalid,
  output logic        s_axis_tready,
  input  logic        s_axis_tlast,

  output logic [47:0] m_axis_tdata,
  output logic        m_axis_tvalid,
  input  logic        m_axis_tready,
  output logic        m_axis_tlast
);

  // ===== Diffusion → Reaction 中间互联 =====
  logic [47:0] diff_m_axis_tdata;
  logic        diff_m_axis_tvalid;
  logic        diff_m_axis_tready;
  logic        diff_m_axis_tlast;

  // ===== Reaction → Membrane 中间互联 =====
  logic [47:0] react_m_axis_tdata;
  logic        react_m_axis_tvalid;
  logic        react_m_axis_tready;
  logic        react_m_axis_tlast;

  // ===== Stage 1: Diffusion Engine =====
  diffusion_engine u_diffusion (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .s_axis_tdata   (s_axis_tdata),
    .s_axis_tvalid  (s_axis_tvalid),
    .s_axis_tready  (s_axis_tready),
    .s_axis_tlast   (s_axis_tlast),
    .m_axis_tdata   (diff_m_axis_tdata),
    .m_axis_tvalid  (diff_m_axis_tvalid),
    .m_axis_tready  (diff_m_axis_tready),
    .m_axis_tlast   (diff_m_axis_tlast)
  );

  // ===== Stage 2: Reaction Engine =====
  reaction_engine u_reaction (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .s_axis_tdata   (diff_m_axis_tdata),
    .s_axis_tvalid  (diff_m_axis_tvalid),
    .s_axis_tready  (diff_m_axis_tready),
    .s_axis_tlast   (diff_m_axis_tlast),
    .m_axis_tdata   (react_m_axis_tdata),
    .m_axis_tvalid  (react_m_axis_tvalid),
    .m_axis_tready  (react_m_axis_tready),
    .m_axis_tlast   (react_m_axis_tlast)
  );

  // ===== Stage 3: Membrane Update Engine =====
  membrane_update u_membrane (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .s_axis_tdata   (react_m_axis_tdata),
    .s_axis_tvalid  (react_m_axis_tvalid),
    .s_axis_tready  (react_m_axis_tready),
    .s_axis_tlast   (react_m_axis_tlast),
    .m_axis_tdata   (m_axis_tdata),
    .m_axis_tvalid  (m_axis_tvalid),
    .m_axis_tready  (m_axis_tready),
    .m_axis_tlast   (m_axis_tlast)
  );

endmodule
