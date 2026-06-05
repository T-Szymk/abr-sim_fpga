// abr_ram_array.sv - RAM array module to allow byte-writes on A-ports and 
// word-reads on B-ports of true dual-port BRAMs. This is necessary to support 
// byte accesses of USB side and 32b accesses on ABR side. CDC also occurs over 
// the memory interface, so this module also serves as a convenient boundary.

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
  input  logic                    clk_b_i, // pll
  input  logic [B_ADDR_WIDTH-1:0] addr_b_i,
  input  logic [B_DATA_WIDTH-1:0] wdata_b_i,
  input  logic [  B_WE_WIDTH-1:0] we_b_i,
  output logic [B_DATA_WIDTH-1:0] rdata_b_o
);

  timeunit 1ns / 1ps;

  /* Parameters and types */

  localparam int unsigned RamSelectWidth   = $clog2(RAM_COUNT); // Number of bits needed to select among RAM_COUNT parallel RAMs
  localparam int unsigned FullRamAddrWidth = RamSelectWidth + RAM_ADDR_WIDTH; // Total address width of the combined RAM array, including bits to select RAM and bits for address within each RAM

  typedef logic [RAM_COUNT-1:0][A_DATA_WIDTH-1:0] ram_data_packed_t; // Packed array type for the data read from each RAM, indexed by RAM number
 
  /* Signal declarations */

  logic [  A_DATA_WIDTH-1:0]                   ram_a_rdata_muxed;
  ram_data_packed_t                            a_rdata_concat;

  logic [RamSelectWidth-1:0]                   ram_a_select;
  logic [RAM_ADDR_WIDTH-1:0]                   ram_a_addr;
  logic [     RAM_COUNT-1:0]                   ram_a_we;
  logic [  A_DATA_WIDTH-1:0]                   ram_a_wdata;

  ram_data_packed_t                            ram_b_wdata;
  ram_data_packed_t                            ram_b_rdata;

  logic ram_a_en;
  logic ram_b_en;

  /* assignments */
  assign ram_a_select = addr_a_i[               RamSelectWidth-1:0]; // Select RAM based on address bits above the byte offset
  assign ram_a_addr   = addr_a_i[FullRamAddrWidth-1:RamSelectWidth]; // RAM address is the upper bits of the address, excluding the byte offset and RAM select bits
  assign ram_a_wdata  = wdata_a_i;                                 // wdata can be broadcast to all RAMs since it is gated by the write-enable
  assign rdata_a_o    = ram_a_rdata_muxed;                             // Mux the read data from the selected RAM to the output

  assign ram_b_wdata  = ram_data_packed_t'(wdata_b_i); // Transfer the B-port write data to all RAMs since word-writes are expected
  assign rdata_b_o    = B_DATA_WIDTH'(ram_b_rdata);    // Since all RAMs should have the same data for the B-port, we can take the read data from any RAM (e.g. the first one)

  assign ram_a_en = 1'b1; // Enable RAMs on A-port
  assign ram_b_en = 1'b1; // Enable RAMs on B-port

  /* logic */

  // mux the read data and write enables from A interface of the selected RAM to the output
  always_comb begin
    // default assignments
    ram_a_rdata_muxed = '0;
    ram_a_we          = '0;

    case (ram_a_select)
      0: begin 
        ram_a_rdata_muxed   = a_rdata_concat[0];
        ram_a_we[0]       = we_a_i;
      end
      1: begin 
        ram_a_rdata_muxed = a_rdata_concat[1];
        ram_a_we[1]       = we_a_i;
      end
      2: begin 
        ram_a_rdata_muxed = a_rdata_concat[2];
        ram_a_we[2]       = we_a_i;
      end
      3: begin 
        ram_a_rdata_muxed = a_rdata_concat[3];
        ram_a_we[3]       = we_a_i;
      end
      default begin
        ram_a_rdata_muxed = '0;
        ram_a_we[3]       = '0;
      end
    endcase

  end

  // instantiate RAM_COUNT parallel RAMs, each with its own write enable and 
  // shared address and data inputs. The read data from each RAM is concatenated into a packed array for muxing to the A-port output.
  genvar ram_idx;
  generate
    for (ram_idx = 0; ram_idx < RAM_COUNT; ram_idx = ram_idx+1) begin: ram_gen
      
      // Instantiate RAM_COUNT parallel RAMs
      amd_tdp_bram #(
        .NB_COL    ( NB_COL                  ),
        .COL_WIDTH ( COL_WIDTH               ),
        .RAM_DEPTH ( RAM_DEPTH               )
      ) ram_inst (
        .addr_a_i  ( ram_a_addr              ),
        .addr_b_i  ( addr_b_i                ),
        .wdata_a_i ( ram_a_wdata             ),
        .wdata_b_i ( ram_b_wdata[ram_idx]    ),
        .clk_a_i   ( clk_a_i                 ),
        .clk_b_i   ( clk_b_i                 ),
        .we_a_i    ( ram_a_we[ram_idx]       ),
        .we_b_i    ( we_b_i[ram_idx]         ),
        .en_a_i    ( ram_a_en                ),
        .en_b_i    ( ram_b_en                ),
        .rdata_a_o ( a_rdata_concat[ram_idx] ),
        .rdata_b_o ( ram_b_rdata[ram_idx]    )
      );
      
    end
  endgenerate

endmodule : ram_array