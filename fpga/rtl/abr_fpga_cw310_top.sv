// abr_fpga_cw310_top.vs - Top-level module for the ABR FPGA CW310 design

(* DONT_TOUCH = "yes" *)
module abr_fpga_cw310_top 
  import abr_fpga_pkg::*; 
#(
  parameter integer unsigned pBYTECNT_SIZE =   2,
  parameter integer unsigned pADDR_WIDTH   =  20
) (
  input  wire                      PLL_CLK_1,   // clk
  output wire                      CWIO_HS1,    // output clock for scope triggering    
  input  wire                      CWIO_HS2,

  input  wire                      USRDIP0,        // DIP switch 0
  input  wire                      USRDIP1,        // DIP switch 1
  input  wire                      USRSW0,         // active-low reset
  output wire [     LED_COUNT-1:0] USRLED,         // user LEDs TODO: Wire to debug signals
  output wire                      CWIO_IO4,       // IO used for trigger  
  // USB Interface
  input  wire                      usb_clk,        // Clock
  inout  wire [USB_DATA_WIDTH-1:0] USB_D,          // Data for write/read
  input  wire [USB_ADDR_WIDTH-1:0] USB_A,          // Address
  input  wire                      USB_nRD,        // !RD, low when addr valid for read
  input  wire                      USB_nWR,        // !WR, low when data+addr valid for write
  input  wire                      USB_nCE,        // !CE, active low chip enable
  input  wire                      usb_trigger     // High when trigger requested
);

  timeunit 1ns/1ps;

  /* Constants and type definitions */

  localparam integer unsigned SyncStages = 3;

  /* Signals and Logic */

  // Internal signals for resets  
  logic reset_ext; // External reset
  logic usb_reset; // USB reset
  logic reset_int; // mmcm lock
  logic rst_n;     // reset to FPGA logic
  logic dut_rstn;  // reset to ABR

  logic clk_int;     // output from mmcm
  logic usb_clk_buf; // buffered USB clocks


  // Debug counter for LED toggling
  logic [25:0] dbg_cntr_fpga;
  logic [25:0] dbg_cntr_usb;

  logic [SyncStages-1:0] fpga_rstn_sync_ff;
  logic [SyncStages-1:0] usb_rstn_sync_ff;
  logic [SyncStages-1:0] dut_rstn_sync_ff;

  

  // Generate active-high reset signal
  assign reset_ext = ~USRSW0;

  // debug LEDs
  assign USRLED[0] = ~usb_reset;
  assign USRLED[1] = dbg_cntr_usb[25];
  assign USRLED[2] = rst_n;
  assign USRLED[3] = dbg_cntr_fpga[25];
  assign USRLED[4] = dut_rstn;
  

  assign USRLED[LED_COUNT-1:5] = '0;

  // ---------------------------------------------------------------------------
  // Clock Generation
  // ---------------------------------------------------------------------------
`ifndef SYNTHESIS

  const int unsigned reset_delay_cycles_c = 5;
  int unsigned       reset_counter;

  assign clk_int = PLL_CLK_1;

  // delay lock signal generation
  always_ff @(posedge clk_int or negedge reset_ext) begin
    if (reset_ext) begin
      reset_int     <= 1'b0;
      reset_counter <= 0;
    end else begin
      if (reset_counter >= reset_delay_cycles_c) begin
        reset_int <= 1'b1;
      end else begin
        reset_counter <= reset_counter + 1;
      end
    end
  end
  
`else

  ip_top_clk top_clk (
    .clk_in1  ( PLL_CLK_1  ), // input  external clock in
    .clk_out  ( clk_int    ), // output clk_out
    .reset    ( reset_ext  ), // input  reset
    .clk_lock ( reset_int  )  // output clk_lock    
  );

`endif

  // ---------------------------------------------------------------------------
  // Reset Synchroniser for USB logic
  // ---------------------------------------------------------------------------

  // n-stage ACTIVE-HIGH reset synchronizer
  always_ff @(posedge usb_clk_buf or posedge reset_ext) begin
    if (reset_ext) begin
      usb_rstn_sync_ff <= '1; // Set all stages to 0 on reset
    end else begin
      usb_rstn_sync_ff <= {usb_rstn_sync_ff[SyncStages-2:0], ~reset_int}; // Shift in the async reset
    end
  end

  assign usb_reset = usb_rstn_sync_ff[SyncStages-1];

  // ---------------------------------------------------------------------------
  // Debug Counter for USB logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge usb_clk_buf or posedge usb_reset) begin
    if (usb_reset) begin
      dbg_cntr_usb <= 0;
    end else begin
      dbg_cntr_usb <= dbg_cntr_usb + 1;
    end
  end

  // ---------------------------------------------------------------------------
  // Reset Synchroniser for FPGA logic
  // ---------------------------------------------------------------------------

  // n-stage ACTIVE-LOW reset synchronizer
  always_ff @(posedge clk_int or posedge reset_ext) begin
    if (reset_ext) begin
      fpga_rstn_sync_ff <= '0; // Set all stages to 0 on reset
    end else begin
      fpga_rstn_sync_ff <= {fpga_rstn_sync_ff[SyncStages-2:0], reset_int}; // Shift in the async reset
    end
  end

  assign rst_n = fpga_rstn_sync_ff[SyncStages-1];

  // ---------------------------------------------------------------------------
  // Debug Counter for FPGA logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_int or negedge rst_n) begin
    if (~rst_n) begin
      dbg_cntr_fpga <= 0;
    end else begin
      dbg_cntr_fpga <= dbg_cntr_fpga + 1;
    end
  end
  
  logic                             isout;
  logic [       USB_DATA_WIDTH-1:0] usb_dout;

  logic [  USB_WORD_ADDR_WIDTH-1:0] reg_address;
  logic [      USB_BCOUNT_SIZE-1:0] reg_bytecnt;
  logic                             reg_addrvalid;
  logic [       USB_DATA_WIDTH-1:0] write_data;
  logic [       USB_DATA_WIDTH-1:0] read_data;
  logic                             reg_read;
  logic                             reg_write;
  logic [   CLK_SETTINGS_WIDTH-1:0] clk_settings;
  logic                             crypt_clk;

  assign USB_D        = isout ? usb_dout : 'Z;
  assign clk_settings = '0; // Use DIP switches for clock settings

  // ---------------------------------------------------------------------------
  // Clock Selection
  // ---------------------------------------------------------------------------
  
  clocks i_cw_clocks (
    .usb_clk     ( usb_clk      ),
    .usb_clk_buf ( usb_clk_buf  ),
    .I_j16_sel   ( USRDIP0      ),
    .I_k16_sel   ( USRDIP1      ),
    .I_clock_reg ( clk_settings ),
    .I_cw_clkin  ( CWIO_HS2     ), // unused, we only use top_clk
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

  logic [      pADDR_WIDTH-1:0] buff_addr_a;
  logic [     A_DATA_WIDTH-1:0] buff_wdata_a;
  logic                         buff_we_a;
  logic [     A_DATA_WIDTH-1:0] buff_rdata_a;

  logic [CW_REG_DATA_WIDTH-1:0] abr_instr;
  logic [CW_REG_DATA_WIDTH-1:0] dut_ctrl0;
  logic [CW_REG_DATA_WIDTH-1:0] dut_ctrl1;
  logic [CW_REG_DATA_WIDTH-1:0] dut_stat0;
  logic [CW_REG_DATA_WIDTH-1:0] dut_stat1;

  (* ASYNC_REG = "TRUE" *) logic [SyncStages-1:0][CW_REG_DATA_WIDTH-1:0] dut_ctrl0_ff;
  (* ASYNC_REG = "TRUE" *) logic [SyncStages-1:0][CW_REG_DATA_WIDTH-1:0] dut_ctrl1_ff;
  (* ASYNC_REG = "TRUE" *) logic [SyncStages-1:0][CW_REG_DATA_WIDTH-1:0] abr_instr_ff;

  (* ASYNC_REG = "TRUE" *) logic [SyncStages-1:0][CW_REG_DATA_WIDTH-1:0] dut_stat0_ff;
  (* ASYNC_REG = "TRUE" *) logic [SyncStages-1:0][CW_REG_DATA_WIDTH-1:0] dut_stat1_ff;

  logic [CW_REG_DATA_WIDTH-1:0] abr_instr_sync;
  logic [CW_REG_DATA_WIDTH-1:0] dut_ctrl0_sync;
  logic [CW_REG_DATA_WIDTH-1:0] dut_ctrl1_sync;
  logic [CW_REG_DATA_WIDTH-1:0] dut_stat0_sync;
  logic [CW_REG_DATA_WIDTH-1:0] dut_stat1_sync;

  abr_cw310_reg #(
    .pBYTECNT_SIZE  ( pBYTECNT_SIZE ),
    .pADDR_WIDTH    ( pADDR_WIDTH   )
  ) i_cw_reg_abr (
    // USB register interface
    .reset_i        ( usb_reset      ),
    .usb_clk        ( usb_clk_buf    ),
    .reg_address    ( reg_address    ),
    .reg_bytecnt    ( reg_bytecnt    ),
    .read_data      ( read_data      ),
    .write_data     ( write_data     ),
    .reg_read       ( reg_read       ),
    .reg_write      ( reg_write      ),
    .reg_addrvalid  ( reg_addrvalid  ),
    // Unconnected — to be wired to DUT logic
    .dut_ctrl0_o    ( dut_ctrl0      ),
    .dut_ctrl1_o    ( dut_ctrl1      ),
    .abr_instr_o    ( abr_instr      ),
    .dut_stat0_i    ( dut_stat0_sync ),
    .dut_stat1_i    ( dut_stat1_sync ),
    .buf_addr_o     ( buff_addr_a    ),
    .buf_wdata_o    ( buff_wdata_a   ),
    .buf_wr_o       ( buff_we_a      ),
    .buf_rdata_i    ( buff_rdata_a   )
  );

  // ---------------------------------------------------------------------------
  // ABR Instruction and Register Decode
  // ---------------------------------------------------------------------------
  
  logic [   AHB_ADDR_WIDTH-1:0] m_xfer_b_addr;
  logic [M_XFER_BLEN_WIDTH-1:0] m_xfer_b_len;
  logic                         m_xfer_op;
  logic                         m_xfer_start;
  logic                         m_xfer_start_pulse;
  logic                         m_xfer_busy;
  logic                         m_xfer_err;

  logic                         dut_rstn_reg;

  logic                         dut_busy;  

  /////////////////////////
  // CDC SYNCHRONISATION //
  /////////////////////////

  // n-stage synchronizer from USB -> PLL domains
  always_ff @(posedge crypt_clk or negedge rst_n) begin
    if (~rst_n) begin
      dut_ctrl0_ff <= '0; // Set all stages to 0 on reset
      dut_ctrl1_ff <= '0;
      abr_instr_ff <= '0;
    end else begin
      dut_ctrl0_ff <= {dut_ctrl0_ff[SyncStages-2:0], dut_ctrl0}; // Shift in the async reset
      dut_ctrl1_ff <= {dut_ctrl1_ff[SyncStages-2:0], dut_ctrl1};
      abr_instr_ff <= {abr_instr_ff[SyncStages-2:0], abr_instr};
    end
  end

  assign abr_instr_sync = abr_instr_ff[SyncStages-1];
  assign dut_ctrl0_sync = dut_ctrl0_ff[SyncStages-1];
  assign dut_ctrl1_sync = dut_ctrl1_ff[SyncStages-1];

  // n-stage synchronizer from PLL -> USB domains
  always_ff @(posedge usb_clk_buf or posedge usb_reset) begin
    if (usb_reset) begin
      dut_stat0_ff <= '0; // Set all stages to 0 on reset
      dut_stat1_ff <= '0;
    end else begin
      dut_stat0_ff <= {dut_stat0_ff[SyncStages-2:0], dut_stat0}; // Shift in the async reset
      dut_stat1_ff <= {dut_stat1_ff[SyncStages-2:0], dut_stat1};
    end
  end

  assign dut_stat0_sync = dut_stat0_ff[SyncStages-1];
  assign dut_stat1_sync = dut_stat1_ff[SyncStages-1];

  ////////////
  // CTRL 0 //
  ////////////
  assign dut_rstn_reg = dut_ctrl0_sync[0];

  ////////////
  // CTRL 1 //
  ////////////
  assign m_xfer_start = dut_ctrl1_sync[0]; // INSTR_RUN triggers start of memory transfer

  ////////////
  // STAT 0 //
  ////////////
  assign dut_stat0[   0] = dut_rstn;
  assign dut_stat0[   1] = dut_busy;
  assign dut_stat0[31:2] = '0;

  // use busy signal for trigger
  assign CWIO_IO4 = dut_busy;

  ////////////
  // STAT 1 //
  ////////////
  assign dut_stat1[   0] = m_xfer_busy;
  assign dut_stat1[   1] = m_xfer_err;
  assign dut_stat1[31:2] = '0;

  // ---------------------------------------------------------------------------
  // ABR Instruction Decoder
  // ---------------------------------------------------------------------------
  abr_instr_decode #(
  ) i_abr_instr_decode (
    .abr_instr_i    ( abr_instr_sync ),
    .m_xfer_b_addr_o( m_xfer_b_addr  ),
    .m_xfer_b_len_o ( m_xfer_b_len   ),
    .m_xfer_op_o    ( m_xfer_op      )
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

  abr_edge_to_pulse i_abr_edge_to_pulse (
    .clk_i  ( crypt_clk          ),
    .rstn_i ( rst_n              ),
    .edge_i ( m_xfer_start       ),
    .pulse_o( m_xfer_start_pulse )
  );

  abr_memory_transfer_controller #(
    .A_DATA_WIDTH( B_DATA_WIDTH   )
  ) abr_memory_transfer_controller (
    .clk_i    ( crypt_clk          ),
    .rst_ni   ( rst_n              ),
    // controller interface
    .start_i  ( m_xfer_start_pulse ),
    .b_addr_i ( m_xfer_b_addr      ),
    .b_len_i  ( m_xfer_b_len       ),
    .op_i     ( m_xfer_op          ),
    // interface to mem mgr
    .a_req_o  ( mem_mgr_req        ),
    .a_write_o( mem_mgr_write      ),
    .a_size_o ( mem_mgr_size       ),
    .a_addr_o ( mem_mgr_addr       ),
    .a_wdata_o( mem_mgr_wdata      ),
    .a_rdata_i( mem_mgr_rdata      ),
    .a_ready_i( mem_mgr_ready      ),
    // interface to AHB manager
    .b_req_o  ( ahb_mgr_req        ),
    .b_write_o( ahb_mgr_write      ),
    .b_size_o ( ahb_mgr_size       ),
    .b_addr_o ( ahb_mgr_addr       ),
    .b_wdata_o( ahb_mgr_wdata      ),
    .b_rdata_i( ahb_mgr_rdata      ),
    .b_ready_i( ahb_mgr_ready      ),
    .busy_o   ( m_xfer_busy        ),
    .error_o  ( m_xfer_err         )
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
    .rst_ni     ( rst_n         ),
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
  // Reset Synchroniser for ABR
  // ---------------------------------------------------------------------------
  
  // n-stage reset synchronizer
  always_ff @(posedge crypt_clk or posedge reset_ext) begin
    if (reset_ext) begin
      dut_rstn_sync_ff <= '0; // Set all stages to 0 on reset
    end else begin
      dut_rstn_sync_ff <= {dut_rstn_sync_ff[SyncStages-2:0], dut_rstn_reg}; // Shift in the async reset
    end
  end

  assign dut_rstn = dut_rstn_sync_ff[SyncStages-1];

  // ---------------------------------------------------------------------------
  // ABR Instance (DUT)
  // ---------------------------------------------------------------------------
  
`ifdef USE_ABR_SIM_MODEL

  // To prevent long simulations when testing the FPGA infrastructure, a simple
  // simulation model of ABR can be used which reports AHB accesses and responds
  // to reads with dummy data (containing the address)
  abr_fpga_top_sim  i_abr_fpga_top_sim (
    .clk_i        ( crypt_clk     ),
    .rst_ni       ( dut_rstn      ),
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
    .busy_o       ( dut_busy      ),
    .error_intr_o (               ),
    .notif_intr_o (               )
  );

`else

  abr_fpga_top  i_abr_fpga_top (
    .clk_i        ( crypt_clk     ),
    .rst_ni       ( dut_rstn      ),
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
    .busy_o       ( dut_busy      ),
    .error_intr_o (               ),
    .notif_intr_o (               )
  );

`endif

endmodule
