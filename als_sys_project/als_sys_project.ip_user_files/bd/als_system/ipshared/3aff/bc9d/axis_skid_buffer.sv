`timescale 1ns/1ps

module axis_skid_buffer (
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

  logic m_axis_tready_q;
  logic pop_out;

  assign pop_out = m_axis_tvalid & m_axis_tready_q;
  assign s_axis_tready = (~m_axis_tvalid) | pop_out;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      m_axis_tdata   <= '0;
      m_axis_tvalid  <= 1'b0;
      m_axis_tlast   <= 1'b0;
      m_axis_tready_q<= 1'b0;
    end else begin
      m_axis_tready_q <= m_axis_tready;

      if (pop_out) begin
        m_axis_tvalid <= 1'b0;
      end

      if (s_axis_tvalid && s_axis_tready) begin
        m_axis_tdata  <= s_axis_tdata;
        m_axis_tvalid <= 1'b1;
        m_axis_tlast  <= s_axis_tlast;
      end
    end
  end

endmodule
