`timescale 1ns/1ps

module axis_skid_buffer #(
  parameter type TDATA_T = logic [47:0]
) (
  input  logic         aclk,
  input  logic         aresetn,

  input  TDATA_T       s_axis_tdata,
  input  logic         s_axis_tvalid,
  output logic         s_axis_tready,
  input  logic         s_axis_tlast,

  output TDATA_T       m_axis_tdata,
  output logic         m_axis_tvalid,
  input  logic         m_axis_tready,
  output logic         m_axis_tlast
);

  // Storage for a single beat + its tlast
  TDATA_T beat_data;
  logic   beat_last;
  logic   has_beat;

  logic   m_axis_tready_q;
  logic   pop_out;
  logic   fire_in;

  assign pop_out = has_beat & m_axis_tready_q;
  assign fire_in = s_axis_tvalid & s_axis_tready;

  // Backpressure: stop accepting when we already have a beat stored
  assign s_axis_tready = ~has_beat;

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      beat_data  <= '0;
      beat_last  <= 1'b0;
      has_beat   <= 1'b0;
      m_axis_tready_q <= 1'b0;
    end else begin
      m_axis_tready_q <= m_axis_tready;

      if (pop_out) begin
        // Downstream consumed the beat — clear storage
        has_beat   <= 1'b0;
      end

      if (fire_in) begin
        // Accept new beat: store data + TLAST together (they are ONE atomic unit)
        beat_data  <= s_axis_tdata;
        beat_last  <= s_axis_tlast;
        has_beat   <= 1'b1;
      end
    end
  end

  // Output: only valid when we have a beat ready
  assign m_axis_tvalid = has_beat;
  assign m_axis_tdata  = beat_data;
  assign m_axis_tlast  = beat_last;  // TLAST is ALWAYS atomic with its beat

endmodule
