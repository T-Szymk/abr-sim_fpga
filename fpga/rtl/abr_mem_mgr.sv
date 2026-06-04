// ahb_mem_mgr.sv — BRAM memory manager
// Drives accesses to a BRAM interface with a simple req/ready handshake.
// Back-to-back transfers are supported: assert req_i while ready_o is high.
//
//   module xilinx_true_dual_port_write_first_byte_write_2_clock_ram #(
//     parameter NB_COL = 4,                           // Specify number of columns (number of bytes)
//     parameter COL_WIDTH = 9,                        // Specify column width (byte width, typically 8 or 9)
//     parameter RAM_DEPTH = 1024,                     // Specify RAM depth (number of entries)
//     parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE", // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
//     parameter INIT_FILE = ""                        // Specify name/location of RAM initialization file if using one (leave blank if not)
//   ) (
//     input [clogb2(RAM_DEPTH-1)-1:0] addra,   // Port A address bus, width determined from RAM_DEPTH
//     input [(NB_COL*COL_WIDTH)-1:0] dina,   // Port A RAM input data
//     input clka,                            // Port A clock
//     input [NB_COL-1:0] wea,                // Port A write enable
//     input ena,                             // Port A RAM Enable, for additional power savings, disable BRAM when not in use
//     input rsta,                            // Port A output reset (does not affect memory contents)
//     input regcea,                          // Port A output register enable
//     output [(NB_COL*COL_WIDTH)-1:0] douta, // Port A RAM output data
//   );


module abr_mem_mgr 
  import abr_fpga_pkg::*;
#(
    parameter  int unsigned MEM_ADDR_WIDTH    = 32, // TODO: This should be a constant in a package
    parameter  int unsigned MEM_DATA_WIDTH    = 32, // TODO: This should be a constant in a package
    localparam int unsigned MemDataWidthBytes = (MEM_DATA_WIDTH / 8)
) (
  // Request interface
  input  logic                          req_i,    // initiate a transfer
  input  logic                          write_i,  // 1 = write, 0 = read
  input  logic [               2:0]     size_i,   // HSIZE: 000=8b 001=16b 010=32b 011=64b
  input  logic [MEM_ADDR_WIDTH-1:0]     addr_i,
  input  logic [MEM_DATA_WIDTH-1:0]     wdata_i,
  output logic                          ready_o,  // manager ready for new request

  // Response interface (valid for one cycle when transfer completes)
  output logic                          done_o,   // transfer accepted by subordinate
  output logic [MEM_DATA_WIDTH-1:0]     rdata_o,  // read data (valid when done_o & !write)
  output logic                          error_o,  // subordinate returned HRESP ERROR

  // Memory interface
  output logic [   MEM_ADDR_WIDTH-1:0] addr_o,   // Mem Port address bus, width determined from RAM_DEPTH
  output logic [   MEM_DATA_WIDTH-1:0] wdata_o,  // Mem Port RAM input data
  output logic [MemDataWidthBytes-1:0] we_o,     // Mem Port write enable
  input  logic [   MEM_DATA_WIDTH-1:0] rdata_i   // Mem Port RAM output data
);

  timeunit 1ns / 1ps;

  assign addr_o  = addr_i;
  assign wdata_o = (req_i & write_i) ? wdata_i : '0;
  assign rdata_o = rdata_i;

  assign ready_o = 1'b1;                                   // Always ready to accept requests
  assign done_o  = req_i;                                  // Transfer completes in the same cycle as request
  assign error_o = 1'b0;                                   // No error conditions in this simple manager
  assign we_o    = (req_i & write_i) ? (1 << size_i) : '0; // Generate byte enables based on size

  /* Assertions */
  
  // Size must be valid and not exceed the data width
  if (MEM_DATA_WIDTH != 64) begin : g_check_data_width
    initial begin
      $error("abr_mem_mgr currently only supports MEM_DATA_WIDTH of 64 bits");
      $finish;
    end
  end

endmodule : abr_mem_mgr

