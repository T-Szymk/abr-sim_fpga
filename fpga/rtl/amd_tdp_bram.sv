
//  Xilinx True Dual Port RAM Byte Write, Write First Dual Clock RAM
//  This code implements a parameterizable true dual port memory (both ports can read and write).
//  The behavior of this RAM is when data is written, the new memory contents at the write
//  address are presented on the output port.

module amd_tdp_bram #(
  parameter NB_COL = 1,      // Specify number of columns (number of bytes)
  parameter COL_WIDTH = 8,   // Specify column width (byte width, typically 8 or 9)
  parameter RAM_DEPTH = 512  // Specify RAM depth (number of entries)
)(
  input  logic [$clog2(RAM_DEPTH-1)-1:0] addr_a_i,  // Port A address bus, width determined from RAM_DEPTH
  input  logic [$clog2(RAM_DEPTH-1)-1:0] addr_b_i,  // Port B address bus, width determined from RAM_DEPTH
  input  logic [ (NB_COL*COL_WIDTH)-1:0] wdata_a_i, // Port A RAM input data
  input  logic [ (NB_COL*COL_WIDTH)-1:0] wdata_b_i, // Port B RAM input data
  input  logic                           clk_a_i,   // Port A clock
  input  logic                           clk_b_i,   // Port B clock
  input  logic [             NB_COL-1:0] we_a_i,    // Port A write enable
  input  logic [             NB_COL-1:0] we_b_i,    // Port B write enable
  input  logic                           en_a_i,    // Port A RAM Enable, for additional power savings, disable BRAM when not in use
  input  logic                           en_b_i,    // Port B RAM Enable, for additional power savings, disable BRAM when not in use

  output logic [(NB_COL*COL_WIDTH)-1:0] rdata_a_o,  // Port A RAM output data
  output logic [(NB_COL*COL_WIDTH)-1:0] rdata_b_o   // Port B RAM output data

);

  timeunit 1ns/1ps;

  logic [(NB_COL*COL_WIDTH)-1:0] ram [RAM_DEPTH-1:0];

  logic [(NB_COL*COL_WIDTH)-1:0] ram_rdata_a;
  logic [(NB_COL*COL_WIDTH)-1:0] ram_rdata_b;

  integer ram_index;
  
  // initialise RAM contents to zero
  initial begin
    for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1) begin
      ram[ram_index] = {(NB_COL*COL_WIDTH){1'b0}};
    end
  end

  generate
  genvar i;
     for (i = 0; i < NB_COL; i = i+1) begin: byte_write
       always @(posedge clk_a_i)
         if (en_a_i)
           if (we_a_i[i]) begin
             ram[addr_a_i][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= wdata_a_i[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
             ram_rdata_a[(i+1)*COL_WIDTH-1:i*COL_WIDTH]   <= wdata_a_i[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
           end else begin
             ram_rdata_a[(i+1)*COL_WIDTH-1:i*COL_WIDTH]    <= ram[addr_a_i][(i+1)*COL_WIDTH-1:i*COL_WIDTH];
           end

       always @(posedge clk_b_i)
         if (en_b_i)
           if (we_b_i[i]) begin
             ram[addr_b_i][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= wdata_b_i[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
             ram_rdata_b[(i+1)*COL_WIDTH-1:i*COL_WIDTH]   <= wdata_b_i[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
           end else begin
             ram_rdata_b[(i+1)*COL_WIDTH-1:i*COL_WIDTH]   <= ram[addr_b_i][(i+1)*COL_WIDTH-1:i*COL_WIDTH];
           end
     end
  endgenerate

  assign rdata_a_o = ram_rdata_a;
  assign rdata_b_o = ram_rdata_b;

endmodule : amd_tdp_bram