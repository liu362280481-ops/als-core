`timescale 1ns/1ps

// als_core_top.sv — 三引擎串联顶层
// Diffusion → Reaction → Membrane
// 数据流：s_axis → diffusion_engine → reaction_engine → membrane_update → m_axis

module als_core_top (
  input  logic        aclk,
  input  logic        aresetn,

  input  logic [47:0] s_axis_tdata,
  (* MARK_DEBUG = "true" *) input  logic        s_axis_tvalid,
  (* MARK_DEBUG = "true" *) output logic        s_axis_tready,
  (* MARK_DEBUG = "true" *) input  logic        s_axis_tlast,

  (* MARK_DEBUG = "true" *) output logic [47:0] m_axis_tdata,
  (* MARK_DEBUG = "true" *) output logic        m_axis_tvalid,
  (* MARK_DEBUG = "true" *) input  logic        m_axis_tready,
  (* MARK_DEBUG = "true" *) output logic        m_axis_tlast
);

  // Step 1 — 无离散 ap_start：子模块仅由 AXI-Stream 握手推进。以下信号焊死为常 1，
  // 标明顶层从不做软件门控；行为上仍以 s_axis_tvalid/tready 为实际“油门”。
  wire internal_start = 1'b1;

  // ===== Diffusion → Reaction 中间互联 =====
  logic [47:0] diff_m_axis_tdata;
  logic        diff_m_axis_tvalid;
  logic        diff_m_axis_tready;
  logic        diff_m_axis_tlast;
  logic [47:0] diff2react_tdata;
  logic        diff2react_tvalid;
  logic        diff2react_tready;
  logic        diff2react_tlast;

  // ===== Reaction → Membrane 中间互联 =====
  logic [47:0] react_m_axis_tdata;
  logic        react_m_axis_tvalid;
  logic        react_m_axis_tready;
  logic        react_m_axis_tlast;
  logic [47:0] react2memb_tdata;
  logic        react2memb_tvalid;
  logic        react2memb_tready;
  logic        react2memb_tlast;

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

  axis_skid_buffer u_skid_diff2react (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .s_axis_tdata   (diff_m_axis_tdata),
    .s_axis_tvalid  (diff_m_axis_tvalid),
    .s_axis_tready  (diff_m_axis_tready),
    .s_axis_tlast   (diff_m_axis_tlast),
    .m_axis_tdata   (diff2react_tdata),
    .m_axis_tvalid  (diff2react_tvalid),
    .m_axis_tready  (diff2react_tready),
    .m_axis_tlast   (diff2react_tlast)
  );

  // ===== Stage 2: Reaction Engine =====
  reaction_engine u_reaction (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .s_axis_tdata   (diff2react_tdata),
    .s_axis_tvalid  (diff2react_tvalid),
    .s_axis_tready  (diff2react_tready),
    .s_axis_tlast   (diff2react_tlast),
    .m_axis_tdata   (react_m_axis_tdata),
    .m_axis_tvalid  (react_m_axis_tvalid),
    .m_axis_tready  (react_m_axis_tready),
    .m_axis_tlast   (react_m_axis_tlast)
  );

  axis_skid_buffer u_skid_react2memb (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .s_axis_tdata   (react_m_axis_tdata),
    .s_axis_tvalid  (react_m_axis_tvalid),
    .s_axis_tready  (react_m_axis_tready),
    .s_axis_tlast   (react_m_axis_tlast),
    .m_axis_tdata   (react2memb_tdata),
    .m_axis_tvalid  (react2memb_tvalid),
    .m_axis_tready  (react2memb_tready),
    .m_axis_tlast   (react2memb_tlast)
  );

  // ===== Stage 3: Membrane Update Engine =====
  membrane_update u_membrane (
    .aclk           (aclk),
    .aresetn        (aresetn),
    .s_axis_tdata   (react2memb_tdata),
    .s_axis_tvalid  (react2memb_tvalid),
    .s_axis_tready  (react2memb_tready),
    .s_axis_tlast   (react2memb_tlast),
    .m_axis_tdata   (m_axis_tdata),
    .m_axis_tvalid  (m_axis_tvalid),
    .m_axis_tready  (m_axis_tready),
    .m_axis_tlast   ()  // 断开，改为顶层生成
  );

  // ===== 因果律句号：TLAST 帧结束脉冲发生器 (128x128=16384) =====
  reg [13:0] pixel_cnt;
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      pixel_cnt <= 14'd0;
    end else if (m_axis_tvalid && m_axis_tready) begin
      if (pixel_cnt == 14'd16383)
        pixel_cnt <= 14'd0;
      else
        pixel_cnt <= pixel_cnt + 1'b1;
    end
  end
  assign m_axis_tlast = (pixel_cnt == 14'd16383);

endmodule
