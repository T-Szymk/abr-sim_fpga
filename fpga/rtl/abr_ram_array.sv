// abr_ram_array.sv - RAM array module to allow byte-writes on A-ports and 
// word-reads on B-ports of true dual-port BRAMs. This is necessary to support 
// byte accesses of USB side and 32b accesses on ABR side. CDC also occurs over 
// the memory interface, so this module also serves as a convenient boundary 
// for synchronizers and CDC verification.

// <wire_or_reg> [clogb2(RAM_DEPTH-1)-1:0] <addra>;  // Port A address bus, width determined from RAM_DEPTH
//   <wire_or_reg> [clogb2(RAM_DEPTH-1)-1:0] <addrb>;  // Port B address bus, width determined from RAM_DEPTH
//   <wire_or_reg> [(NB_COL*COL_WIDTH)-1:0] <dina>;  // Port A RAM input data
//   <wire_or_reg> [(NB_COL*COL_WIDTH)-1:0] <dinb>;  // Port B RAM input data
//   <wire_or_reg> <clka>;                           // Port A clock
//   <wire_or_reg> <clkb>;                           // Port B clock
//   <wire_or_reg> [NB_COL-1:0] <wea>;               // Port A write enable
//   <wire_or_reg> [NB_COL-1:0] <web>;		  // Port B write enable
//   <wire_or_reg> <ena>;                            // Port A RAM Enable, for additional power savings, disable BRAM when not in use
//   <wire_or_reg> <enb>;                            // Port B RAM Enable, for additional power savings, disable BRAM when not in use
//   <wire_or_reg> <rsta>;                           // Port A output reset (does not affect memory contents)
//   <wire_or_reg> <rstb>;                           // Port B output reset (does not affect memory contents)
//   <wire_or_reg> <regcea>;                         // Port A output register enable
//   <wire_or_reg> <regceb>;                         // Port B output register enable
//   wire [(NB_COL*COL_WIDTH)-1:0] <douta>; // Port A RAM output data
//   wire [(NB_COL*COL_WIDTH)-1:0] <doutb>; // Port B RAM output data



module ram_array 
  import abr_fpga_pkg::*;
(
  // Port A: byte-write port for USB side
  input  logic                    clk_a_i, // usb clk
  input  logic [A_ADDR_WIDTH-1:0] addr_a_i,
  input  logic [A_DATA_WIDTH-1:0] wdata_a_i,
  input  logic                    we_a_i,
  output logic [A_DATA_WIDTH-1:0] rdata_a_o,

  // Port B: word-read port for ABR side
  input  logic                    clk_b_i,
  input  logic [B_ADDR_WIDTH-1:0] addr_b_i,
  input  logic [B_DATA_WIDTH-1:0] wdata_b_i,
  input  logic [  B_WE_WIDTH-1:0] we_b_i,
  output logic [B_DATA_WIDTH-1:0] rdata_b_o
);

  timeunit 1ns / 1ps;

  localparam int unsigned RamSelectWidth = $clog2(RAM_COUNT); // Number of bits needed to select among RAM_COUNT parallel RAMs
  localparam int unsigned RamAddrWidth   = RAM_ADDR_WIDTH - RamSelectWidth; // Address width for each individual RAM, after accounting for the bits used to select among parallel RAMs

  /* Signal declarations */

  logic [  A_DATA_WIDTH-1:0]                   a_rdata_muxed;
  logic [     RAM_COUNT-1:0][A_DATA_WIDTH-1:0] a_rdata_concat;

  logic [RamSelectWidth-1:0]                   a_ram_select;
  logic [  RamAddrWidth-1:0]                   a_ram_addr;
  logic [     RAM_COUNT-1:0]                   a_ram_we;
  logic [  A_DATA_WIDTH-1:0]                   a_ram_wdata;

  logic [     RAM_COUNT-1:0][A_DATA_WIDTH-1:0] b_ram_wdata;

  /* assignments */
  assign a_ram_select = addr_a_i[             RamSelectWidth-1:0]; // Select RAM based on address bits above the byte offset
  assign a_ram_addr   = addr_a_i[RAM_ADDR_WIDTH-1:RamSelectWidth]; // RAM address is the upper bits of the address, excluding the byte offset and RAM select bits
  assign a_ram_wdata  = wdata_a_i; // wdata can be broadcast to all RAMs since it is gated by the write-enable

  assign b_ram_wdata  = wdata_b_i; // Transfer the B-port write data to all RAMs since word-writes are expected

  /* logic */

  // mux the read data and write enables from the selected RAM to the output
  always_comb begin
    // default assignments
    rdata_a_o = '0;
    a_ram_we      = '0;

    unique case (a_ram_select)
      0: begin 
        rdata_a_o   = a_rdata_concat[0];
        a_ram_we[0] = we_a_i;
      end
      1: begin 
        rdata_a_o = a_rdata_concat[1];
        a_ram_we[1] = we_a_i;
      end
      2: begin 
        rdata_a_o = a_rdata_concat[2];
        a_ram_we[2] = we_a_i;
      end
      3: begin 
        rdata_a_o = a_rdata_concat[3];
        a_ram_we[3] = we_a_i;
      end
    endcase

  end

endmodule : ram_array