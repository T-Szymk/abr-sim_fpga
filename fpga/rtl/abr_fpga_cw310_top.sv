// abr_fpga_cw310_top.vs - Top-level module for the ABR FPGA CW310 design

(* DONT_TOUCH = "yes" *)
module abr_fpga_cw310_top 
  import abr_fpga_pkg::*; 
#(
  parameter integer unsigned pBYTECNT_SIZE =   7,
  parameter integer unsigned pADDR_WIDTH   =  20,
  parameter integer unsigned pPT_WIDTH     = 128,
  parameter integer unsigned pCT_WIDTH     = 128,
  parameter integer unsigned pKEY_WIDTH    = 128
) (
  input  wire                   PLL_CLK_1,   // clk
  output wire                   CWIO_HS1,    // output clock for scope triggering    
  input  wire                   CWIO_HS2,

  input  wire                   USRDIP0,        // DIP switch 0
  input  wire                   USRDIP1,        // DIP switch 1
  input  wire                   USRSW0,         // active-low reset
  output wire [            5:0] USRLED,         // user LEDs
  output wire                   CWIO_IO4,       // IO used for trigger  
  // USB Interface
  input  wire                   usb_clk,        // Clock
  inout  wire [            7:0] USB_D,          // Data for write/read
  input  wire [pADDR_WIDTH-1:0] USB_A,          // Address
  input  wire                   USB_nRD,        // !RD, low when addr valid for read
  input  wire                   USB_nWR,        // !WR, low when data+addr valid for write
  input  wire                   USB_nCE,        // !CE, active low chip enable
  input  wire                   usb_trigger     // High when trigger requested

);

  timeunit 1ns/1ps;

  /* Constants and type definitions */

  localparam integer unsigned ResetSyncStages = 3;

  /* Signals and Logic */

  // Internal signal for reset
  logic reset_ext;
  logic reset_int;
  logic rst_n;
  logic clk_int;


  // Debug counter for LED toggling
  logic [25:0] debug_counter;

  logic [ResetSyncStages-1:0] resetn_sync_ff;

  // Generate active-high reset signal
  assign reset_ext = ~USRSW0;
  assign rst_n     = resetn_sync_ff[ResetSyncStages-1];


  // ---------------------------------------------------------------------------
  // Reset Synchroniser
  // ---------------------------------------------------------------------------

  // n-stage reset synchronizer
  always_ff @(posedge clk_int or posedge reset_ext) begin
    if (reset_ext) begin
      resetn_sync_ff <= '0; // Set all stages to 0 on reset
    end else begin
      resetn_sync_ff <= {resetn_sync_ff[ResetSyncStages-2:0], reset_int}; // Shift in the async reset
    end
  end

  // ---------------------------------------------------------------------------
  // Debug Counter
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_int or negedge rst_n) begin
    if (!rst_n) begin
      debug_counter <= 0;
    end else begin
      debug_counter <= debug_counter + 1;
    end
  end

  
  logic                                 usb_reset;
  logic                                 usb_clk_buf;
  logic                                 isout;
  logic [                          7:0] usb_dout;

  logic [pADDR_WIDTH-pBYTECNT_SIZE-1:0] reg_address;
  logic [            pBYTECNT_SIZE-1:0] reg_bytecnt;
  logic                                 reg_addrvalid;
  logic [                          7:0] write_data;
  logic [                          7:0] read_data;
  logic                                 reg_read;
  logic                                 reg_write;
  logic [                          4:0] clk_settings;
  logic                                 crypt_clk;

  assign usb_reset    = !reset_int; // Use inverted synchronized reset for USB logic
  assign USB_D        = isout? usb_dout : 8'bZ;
  assign clk_settings = '0; // Use DIP switches for clock settings

  // ---------------------------------------------------------------------------
  // Clock Generation and Selection
  // ---------------------------------------------------------------------------
  ip_top_clk top_clk (
    .clk_in1  ( PLL_CLK_1  ), // input  external clock in
    .clk_out  ( clk_int    ), // output clk_out
    .reset    ( reset_ext  ), // input  reset
    .clk_lock ( reset_int  )  // output clk_lock    
  );
  
  clocks i_cw_clocks (
    .usb_clk     ( usb_clk      ),
    .usb_clk_buf ( usb_clk_buf  ),
    .I_j16_sel   ( USRDIP0      ),
    .I_k16_sel   ( USRDIP1      ),
    .I_clock_reg ( clk_settings ),
    .I_cw_clkin  ( '0           ), // unused, we only use top_clk
    .I_pll_clk1  ( clk_int      ),
    .O_cw_clkout ( CWIO_HS1     ),
    .O_cryptoclk ( crypt_clk    )
  );

  // ---------------------------------------------------------------------------
  // USB Front-End to Register Interface
  // ---------------------------------------------------------------------------
  cw310_usb_reg_fe #(
    .pBYTECNT_SIZE ( pBYTECNT_SIZE    ),
    .pADDR_WIDTH   ( pADDR_WIDTH      )
  ) i_cw_usb_reg_fe (
    .rst           ( usb_reset        ),
    .usb_clk       ( usb_clk_buf      ), 
    .usb_din       ( USB_D            ), 
    .usb_dout      ( usb_dout         ), 
    .usb_rdn       ( USB_nRD          ), 
    .usb_wrn       ( USB_nWR          ),
    .usb_cen       ( USB_nCE          ),
    .usb_alen      ( 1'b0             ),
    .usb_addr      ( USB_A            ),
    .usb_isout     ( isout            ), 
    .reg_address   ( reg_address      ), 
    .reg_bytecnt   ( reg_bytecnt      ), 
    .reg_datao     ( write_data       ), 
    .reg_datai     ( read_data        ),
    .reg_read      ( reg_read         ), 
    .reg_write     ( reg_write        ), 
    .reg_addrvalid ( reg_addrvalid    )
  );

  logic [ pADDR_WIDTH-1:0] buff_addr_a;
  logic [A_DATA_WIDTH-1:0] buff_wdata_a;
  logic                    buff_we_a;
  logic [A_DATA_WIDTH-1:0] buff_rdata_a;

  abr_cw310_reg #(
    .pBYTECNT_SIZE  ( pBYTECNT_SIZE ),
    .pADDR_WIDTH    ( pADDR_WIDTH   )
  ) i_cw_reg_abr (
    // USB register interface
    .reset_i        ( usb_reset     ),
    .usb_clk        ( usb_clk_buf   ),
    .reg_address    ( reg_address   ),
    .reg_bytecnt    ( reg_bytecnt   ),
    .read_data      ( read_data     ),
    .write_data     ( write_data    ),
    .reg_read       ( reg_read      ),
    .reg_write      ( reg_write     ),
    .reg_addrvalid  ( reg_addrvalid ),
    // Unconnected — to be wired to DUT logic
    .dut_ctrl0_o    (               ),
    .dut_ctrl1_o    (               ),
    .abr_instr_o    (               ),
    .dut_stat0_i    ( '0            ),
    .dut_stat1_i    ( '0            ),
    .buf_addr_o     ( buff_addr_a   ),
    .buf_wdata_o    ( buff_wdata_a  ),
    .buf_wr_o       ( buff_we_a     ),
    .buf_rdata_i    ( buff_rdata_a  )
  );

  // ---------------------------------------------------------------------------
  // ABR Data Buffer
  // ---------------------------------------------------------------------------

  logic [B_ADDR_WIDTH-1:0] buff_addr_b;
  logic [B_DATA_WIDTH-1:0] buff_wdata_b;
  logic [  B_WE_WIDTH-1:0] buff_we_b;
  logic [B_DATA_WIDTH-1:0] buff_rdata_b;

  ram_array i_ram_array (
    .clk_a_i   ( usb_clk_buf   ),
    .addr_a_i  ( buff_addr_a   ),
    .wdata_a_i ( buff_wdata_a  ),
    .we_a_i    ( buff_we_a     ),
    .rdata_a_o ( buff_rdata_a  ),

    .clk_b_i   ( crypt_clk     ),
    .addr_b_i  ( buff_addr_b   ),
    .wdata_b_i ( buff_wdata_b  ),
    .we_b_i    ( buff_we_b     ),
    .rdata_b_o ( buff_rdata_b  )
  );

  logic                      mem_mgr_req;
  logic                      mem_mgr_write;
  logic [               2:0] mem_mgr_size;

  logic [  B_DATA_WIDTH-1:0] mem_mgr_wdata;
  logic                      mem_mgr_ready;
  // Response interface (valid for one cycle when transfer completes)
  logic [  B_DATA_WIDTH-1:0] mem_mgr_rdata;

  // slice address from memory manager to match BRAM address width
  logic [  B_ADDR_WIDTH-1:0] mem_mgr_addr_ram;
  logic [AHB_ADDR_WIDTH-1:0] mem_mgr_addr;

  assign mem_mgr_addr_ram = mem_mgr_addr[B_ADDR_WIDTH-1:0];

  // ---------------------------------------------------------------------------
  // ABR Memory <-> AHB Transfer Logic
  // ---------------------------------------------------------------------------

  abr_mem_mgr #(
    .MEM_ADDR_WIDTH   ( B_ADDR_WIDTH ),
    .MEM_DATA_WIDTH   ( B_DATA_WIDTH )
   ) abr_mem_mgr (
    // Request Interface
    .req_i   ( mem_mgr_req      ),
    .write_i ( mem_mgr_write    ),
    .size_i  ( mem_mgr_size     ),
    .addr_i  ( mem_mgr_addr_ram ),
    .wdata_i ( mem_mgr_wdata    ),
    .ready_o ( mem_mgr_ready    ),
    // Response Interface
    .done_o  (                  ),
    .rdata_o ( mem_mgr_rdata    ),
    .error_o (                  ),
    // mem interface
    .addr_o  ( buff_addr_b      ),
    .wdata_o ( buff_wdata_b     ),
    .we_o    ( buff_we_b        ),
    .rdata_i ( buff_rdata_b     )
  );

  logic                      ahb_mgr_req;    // initiate a transfer
  logic                      ahb_mgr_write;  // 1 = write, 0 = read
  logic [               2:0] ahb_mgr_size;   // HSIZE: 000=8b 001=16b 010=32b 011=64b
  logic [AHB_ADDR_WIDTH-1:0] ahb_mgr_addr;
  logic [AHB_DATA_WIDTH-1:0] ahb_mgr_wdata;
  logic                      ahb_mgr_ready;  // manager ready for new request

  // Response interface (valid for one cycle when transfer completes)
  logic [AHB_DATA_WIDTH-1:0] ahb_mgr_rdata;  // read data (valid when done_o & !write)

  abr_memory_transfer_controller #(
    .ADDR_WIDTH  ( AHB_ADDR_WIDTH ),
    .DATA_WIDTH  ( AHB_DATA_WIDTH ),
    .A_DATA_WIDTH( B_DATA_WIDTH   )
  ) abr_memory_transfer_controller (
    .clk_i    ( crypt_clk     ),
    .rst_ni   ( reset_ext     ),
    // controller interface
    .start_i  ( '0            ),
    .b_addr_i ( '0            ),
    .b_len_i  ( '0            ),
    .op_i     ( '0            ),
    // interface to mem mgr
    .a_req_o  ( mem_mgr_req   ),
    .a_write_o( mem_mgr_write ),
    .a_size_o ( mem_mgr_size  ),
    .a_addr_o ( mem_mgr_addr  ),
    .a_wdata_o( mem_mgr_wdata ),
    .a_rdata_i( mem_mgr_rdata ),
    .a_ready_i( mem_mgr_ready ),
    // interface to AHB manager
    .b_req_o  ( ahb_mgr_req   ),
    .b_write_o( ahb_mgr_write ),
    .b_size_o ( ahb_mgr_size  ),
    .b_addr_o ( ahb_mgr_addr  ),
    .b_wdata_o( ahb_mgr_wdata ),
    .b_rdata_i( ahb_mgr_rdata ),
    .b_ready_i( ahb_mgr_ready ),
    .busy_o   (  ),
    .error_o  (  )
  );

  // AHB-Lite manager port
  logic [AHB_ADDR_WIDTH-1:0] ahb_haddr;
  logic [AHB_DATA_WIDTH-1:0] ahb_hwdata;
  logic                      ahb_hsel;
  logic                      ahb_hwrite;
  logic                      ahb_hready;  // fed back from hreadyout_i
  logic [               1:0] ahb_htrans;
  logic [               2:0] ahb_hsize;
  logic                      ahb_hresp;
  logic                      ahb_hreadyout;
  logic [AHB_DATA_WIDTH-1:0] ahb_hrdata;

  abr_ahb_mgr #(
    .AHB_ADDR_WIDTH( AHB_ADDR_WIDTH ),
    .AHB_DATA_WIDTH( AHB_DATA_WIDTH )
   ) abr_ahb_mgr (
    .clk_i      ( crypt_clk     ),
    .rst_ni     ( reset_ext     ),
    // Memory Transfer Controller Interface
    .req_i      ( ahb_mgr_req   ),
    .write_i    ( ahb_mgr_write ),
    .size_i     ( ahb_mgr_size  ),
    .addr_i     ( ahb_mgr_addr  ),
    .wdata_i    ( ahb_mgr_wdata ),
    .ready_o    ( ahb_mgr_ready ),
    .done_o     (               ),
    .rdata_o    ( ahb_mgr_rdata ),
    .error_o    (               ),
    // AHB interface
    .haddr_o    ( ahb_haddr     ),
    .hwdata_o   ( ahb_hwdata    ),
    .hsel_o     ( ahb_hsel      ),
    .hwrite_o   ( ahb_hwrite    ),
    .hready_o   ( ahb_hready    ),
    .htrans_o   ( ahb_htrans    ),
    .hsize_o    ( ahb_hsize     ),
    .hresp_i    ( ahb_hresp     ),
    .hreadyout_i( ahb_hreadyout ),
    .hrdata_i   ( ahb_hrdata    )
  );

  // ---------------------------------------------------------------------------
  // ABR Instance (DUT)
  // ---------------------------------------------------------------------------

  /* ToDo: Create simulation version which reports received AHB values and 
          returns data following a request. */
  abr_fpga_top  abr_fpga_top (
    .clk_i        ( crypt_clk     ),
    .rst_ni       ( reset_ext     ),
    .haddr_i      ( ahb_haddr     ),
    .hwdata_i     ( ahb_hwdata    ),
    .hsel_i       ( ahb_hsel      ),
    .hwrite_i     ( ahb_hwrite    ),
    .hready_i     ( ahb_hready    ),
    .htrans_i     ( ahb_htrans    ),
    .hsize_i      ( ahb_hsize     ),
    .hresp_o      ( ahb_hresp     ),
    .hreadyout_o  ( ahb_hreadyout ),
    .hrdata_o     ( ahb_hrdata    ),
    .busy_o       (               ),
    .error_intr_o (               ),
    .notif_intr_o (               )
  );

endmodule
