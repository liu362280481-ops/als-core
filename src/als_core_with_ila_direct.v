// als_core_with_ila_direct.v
// 直接在 RTL 层面例化 ILA，避免 BD TCL 接口连接问题
// Probes: s_axis (input from DMA) + m_axis (output to BRAM)

`timescale 1ns/1ps

module als_core_with_ila_direct (
    input wire aclk,
    input wire aresetn,

    // Slave AXI-Stream (来自 DMA/BRAM)
    input  wire [47:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,

    // Master AXI-Stream (送往 BRAM)
    output wire [47:0] m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
);

    // ================================================================
    // ILA Debug Core - 捕获 AXI-Stream 信号
    // ================================================================
    wire [13:0] dbg_pixel_count;
    wire        dbg_flush_mode;

    (* MARK_DEBUG = "true" *) wire [47:0] dbg_s_tdata  = s_axis_tdata;
    (* MARK_DEBUG = "true" *) wire        dbg_s_valid = s_axis_tvalid;
    (* MARK_DEBUG = "true" *) wire        dbg_s_ready = s_axis_tready;
    (* MARK_DEBUG = "true" *) wire        dbg_s_last  = s_axis_tlast;
    (* MARK_DEBUG = "true" *) wire [47:0] dbg_m_tdata  = m_axis_tdata;
    (* MARK_DEBUG = "true" *) wire        dbg_m_valid = m_axis_tvalid;
    (* MARK_DEBUG = "true" *) wire        dbg_m_ready = m_axis_tready;
    (* MARK_DEBUG = "true" *) wire        dbg_m_last  = m_axis_tlast;

    // ================================================================
    // ALS Core
    // ================================================================
    als_core_v1 #(
        .GRID_W(128),
        .GRID_H(128)
    ) u_als_core (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        .s_axis_tlast   (s_axis_tlast),
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tlast   (m_axis_tlast)
    );

endmodule
