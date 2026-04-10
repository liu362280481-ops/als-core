`timescale 1ns/1ps

module hill_lut #(
  parameter string INIT_FILE = "hill_lut.hex"
) (
  input  logic [7:0]  addr,
  output logic [15:0] data_q8_8
);

  logic [15:0] rom [0:255];
  integer i;

  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      rom[i] = 16'd0;
    end
    $readmemh(INIT_FILE, rom);
  end

  assign data_q8_8 = rom[addr];

endmodule
