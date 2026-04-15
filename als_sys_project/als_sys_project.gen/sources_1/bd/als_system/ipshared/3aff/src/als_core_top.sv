`timescale 1ns/1ps

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

  wire internal_start = 1'b1;

  logic [47:0] diff_m_axis_tdata, diff2react_tdata, react_m_axis_tdata, react2memb_tdata;
  logic diff_m_axis_tvalid, diff2react_tvalid, react_m_axis_tvalid, react2memb_tvalid;
  logic diff_m_axis_tready, diff2react_tready, react_m_axis_tready, react2memb_tready;
  logic diff_m_axis_tlast, diff2react_tlast, react_m_axis_tlast, react2memb_tlast;

  diffusion_engine u_diffusion (
    .aclk(aclk), .aresetn(aresetn),
    .s_axis_tdata(s_axis_tdata), .s_axis_tvalid(s_axis_tvalid), .s_axis_tready(s_axis_tready), .s_axis_tlast(s_axis_tlast),
    .m_axis_tdata(diff_m_axis_tdata), .m_axis_tvalid(diff_m_axis_tvalid), .m_axis_tready(diff_m_axis_tready), .m_axis_tlast(diff_m_axis_tlast)
  );

  axis_skid_buffer u_skid_diff2react (
    .aclk(aclk), .aresetn(aresetn),
    .s_axis_tdata(diff_m_axis_tdata), .s_axis_tvalid(diff_m_axis_tvalid), .s_axis_tready(diff_m_axis_tready), .s_axis_tlast(diff_m_axis_tlast),
    .m_axis_tdata(diff2react_tdata), .m_axis_tvalid(diff2react_tvalid), .m_axis_tready(diff2react_tready), .m_axis_tlast(diff2react_tlast)
  );

  reaction_engine u_reaction (
    .aclk(aclk), .aresetn(aresetn),
    .s_axis_tdata(diff2react_tdata), .s_axis_tvalid(diff2react_tvalid), .s_axis_tready(diff2react_tready), .s_axis_tlast(diff2react_tlast),
    .m_axis_tdata(react_m_axis_tdata), .m_axis_tvalid(react_m_axis_tvalid), .m_axis_tready(react_m_axis_tready), .m_axis_tlast(react_m_axis_tlast)
  );

  axis_skid_buffer u_skid_react2memb (
    .aclk(aclk), .aresetn(aresetn),
    .s_axis_tdata(react_m_axis_tdata), .s_axis_tvalid(react_m_axis_tvalid), .s_axis_tready(react_m_axis_tready), .s_axis_tlast(react_m_axis_tlast),
    .m_axis_tdata(react2memb_tdata), .m_axis_tvalid(react2memb_tvalid), .m_axis_tready(react2memb_tready), .m_axis_tlast(react2memb_tlast)
  );

  membrane_update u_membrane (
    .aclk(aclk), .aresetn(aresetn),
    .s_axis_tdata(react2memb_tdata), .s_axis_tvalid(react2memb_tvalid), 
    .s_axis_tready(react2memb_tready),  // <--- 【已绝对修正】
    .s_axis_tlast(react2memb_tlast),
    .m_axis_tdata(m_axis_tdata), .m_axis_tvalid(m_axis_tvalid), .m_axis_tready(m_axis_tready), .m_axis_tlast(m_axis_tlast)
  );

endmodule
