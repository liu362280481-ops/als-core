// als_core_with_ila.v
// ALS Core + Integrated ILA Debug Hub
// Probes: s_axis_tvalid/tready/tlast/tdata, m_axis_tvalid/tready/tlast/tdata

`timescale 1ns/1ps

module als_core_with_ila (
    input wire aclk,
    input wire aresetn,

    // Master AXI-Stream (output to DMA)
    output wire [47:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input wire         m_axis_tready,
    output wire        m_axis_tlast,

    // Slave AXI-Stream (input from DMA/BRAM)
    input wire [47:0]  s_axis_tdata,
    input wire          s_axis_tvalid,
    output wire         s_axis_tready,
    input wire          s_axis_tlast
);

    // ============================================================
    // ILA Debug Core - 捕获 AXI-Stream 总线时序
    // ============================================================
    (* MARK_DEBUG="true" *) wire [47:0] dbg_s_tdata;
    (* MARK_DEBUG="true" *) wire        dbg_s_tvalid;
    (* MARK_DEBUG="true" *) wire        dbg_s_tready;
    (* MARK_DEBUG="true" *) wire        dbg_s_tlast;
    (* MARK_DEBUG="true" *) wire [47:0] dbg_m_tdata;
    (* MARK_DEBUG="true" *) wire        dbg_m_tvalid;
    (* MARK_DEBUG="true" *) wire        dbg_m_tready;
    (* MARK_DEBUG="true" *) wire        dbg_m_tlast;
    (* MARK_DEBUG="true" *) wire        dbg_aclk;

    assign dbg_aclk    = aclk;
    assign dbg_s_tdata  = s_axis_tdata;
    assign dbg_s_tvalid = s_axis_tvalid;
    assign dbg_s_tready = s_axis_tready;
    assign dbg_s_tlast  = s_axis_tlast;
    assign dbg_m_tdata  = m_axis_tdata;
    assign dbg_m_tvalid = m_axis_tvalid;
    assign dbg_m_tready = m_axis_tready;
    assign dbg_m_tlast  = m_axis_tlast;

    // ILA IP - 会由 Vivado synthesis 根据 MARK_DEBUG 自动例化
    // 触发条件: m_axis_tvalid 下降沿 (输出停止时触发)
    // 采样深度: 4096

    // ============================================================
    // ALS Core 实例
    // ============================================================
    als_core_v1 #(
        .GRID_W(128),
        .GRID_H(128)
    ) als_core_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast)
    );

endmodule
