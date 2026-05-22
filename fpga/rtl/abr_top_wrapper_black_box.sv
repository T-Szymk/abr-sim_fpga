// abr_top_wrapper_black_box.sv
// Black-box stub for abr_top_wrapper.  All port widths are given as explicit
// numeric literals (derived from abr_params_pkg / abr_ctrl_pkg at the values
// current as of adams-bridge v2.0.3).  No package imports required, and all
// outputs are tied to zero.

module abr_top_wrapper #(
  parameter AHB_ADDR_WIDTH    = 32,
  parameter AHB_DATA_WIDTH    = 64,
  parameter CLIENT_DATA_WIDTH = 32
) (
  input  wire clk,
  input  wire rst_b,

`ifdef RV_FPGA_SCA
  output wire NTT_trigger,
  output wire PWM_trigger,
  output wire PWA_trigger,
  output wire INTT_trigger,
`endif

  //ahb input
  input wire  [AHB_ADDR_WIDTH-1:0] haddr_i,
  input wire  [AHB_DATA_WIDTH-1:0] hwdata_i,
  input wire                       hsel_i,
  input wire                       hwrite_i,
  input wire                       hready_i,
  input wire  [1:0]                htrans_i,
  input wire  [2:0]                hsize_i,

  //ahb output
  output wire                      hresp_o,
  output wire                      hreadyout_o,
  output wire [AHB_DATA_WIDTH-1:0] hrdata_o,

  input wire debugUnlock_or_scan_mode_switch,

  output wire                      busy_o,

  output wire                      error_intr,
  output wire                      notif_intr,

  // -----------------------------------------------------------------------
  // w1_mem  (ABR_MEM_W1_ADDR_W=9, ABR_MEM_W1_DATA_W=4)
  // -----------------------------------------------------------------------
  output wire        w1_mem_we_o,
  output wire [8:0]  w1_mem_waddr_o,
  output wire [3:0]  w1_mem_wdata_o,
  output wire        w1_mem_re_o,
  output wire [8:0]  w1_mem_raddr_o,
  input  wire [3:0]  w1_mem_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst0_bank0  (ABR_MEM_INST0_ADDR_W=10, ABR_MEM_INST0_DATA_W=96)
  // -----------------------------------------------------------------------
  output wire         mem_inst0_bank0_we_o,
  output wire [9:0]   mem_inst0_bank0_waddr_o,
  output wire [95:0]  mem_inst0_bank0_wdata_o,
  output wire         mem_inst0_bank0_re_o,
  output wire [9:0]   mem_inst0_bank0_raddr_o,
  input  wire [95:0]  mem_inst0_bank0_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst0_bank1  (ABR_MEM_INST0_ADDR_W=10, ABR_MEM_INST0_DATA_W=96)
  // -----------------------------------------------------------------------
  output wire         mem_inst0_bank1_we_o,
  output wire [9:0]   mem_inst0_bank1_waddr_o,
  output wire [95:0]  mem_inst0_bank1_wdata_o,
  output wire         mem_inst0_bank1_re_o,
  output wire [9:0]   mem_inst0_bank1_raddr_o,
  input  wire [95:0]  mem_inst0_bank1_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst1  (ABR_MEM_INST1_ADDR_W=10, ABR_MEM_INST1_DATA_W=96)
  // -----------------------------------------------------------------------
  output wire         mem_inst1_we_o,
  output wire [9:0]   mem_inst1_waddr_o,
  output wire [95:0]  mem_inst1_wdata_o,
  output wire         mem_inst1_re_o,
  output wire [9:0]   mem_inst1_raddr_o,
  input  wire [95:0]  mem_inst1_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst2  (ABR_MEM_INST2_ADDR_W=11, ABR_MEM_INST2_DATA_W=96)
  // -----------------------------------------------------------------------
  output wire         mem_inst2_we_o,
  output wire [10:0]  mem_inst2_waddr_o,
  output wire [95:0]  mem_inst2_wdata_o,
  output wire         mem_inst2_re_o,
  output wire [10:0]  mem_inst2_raddr_o,
  input  wire [95:0]  mem_inst2_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst3  (ABR_MEM_INST3_ADDR_W=6, ABR_MEM_INST3_DATA_W=384)
  // -----------------------------------------------------------------------
  output wire          mem_inst3_we_o,
  output wire [5:0]    mem_inst3_waddr_o,
  output wire [383:0]  mem_inst3_wdata_o,
  output wire          mem_inst3_re_o,
  output wire [5:0]    mem_inst3_raddr_o,
  input  wire [383:0]  mem_inst3_rdata_i,

  // -----------------------------------------------------------------------
  // sk_mem_bank0  (SK_MEM_BANK_ADDR_W=10, SK_MEM_BANK_DATA_W=32)
  // -----------------------------------------------------------------------
  output wire         sk_mem_bank0_we_o,
  output wire [9:0]   sk_mem_bank0_waddr_o,
  output wire [31:0]  sk_mem_bank0_wdata_o,
  output wire         sk_mem_bank0_re_o,
  output wire [9:0]   sk_mem_bank0_raddr_o,
  input  wire [31:0]  sk_mem_bank0_rdata_i,

  // -----------------------------------------------------------------------
  // sk_mem_bank1  (SK_MEM_BANK_ADDR_W=10, SK_MEM_BANK_DATA_W=32)
  // -----------------------------------------------------------------------
  output wire         sk_mem_bank1_we_o,
  output wire [9:0]   sk_mem_bank1_waddr_o,
  output wire [31:0]  sk_mem_bank1_wdata_o,
  output wire         sk_mem_bank1_re_o,
  output wire [9:0]   sk_mem_bank1_raddr_o,
  input  wire [31:0]  sk_mem_bank1_rdata_i,

  // -----------------------------------------------------------------------
  // sig_z_mem  (SIG_Z_MEM_ADDR_W=8, SIG_Z_MEM_DATA_W=160, SIG_Z_MEM_WSTROBE_W=20)
  // -----------------------------------------------------------------------
  output wire          sig_z_mem_we_o,
  output wire [7:0]    sig_z_mem_waddr_o,
  output wire [159:0]  sig_z_mem_wdata_o,
  output wire [19:0]   sig_z_mem_wstrobe_o,
  output wire          sig_z_mem_re_o,
  output wire [7:0]    sig_z_mem_raddr_o,
  input  wire [159:0]  sig_z_mem_rdata_i,

  // -----------------------------------------------------------------------
  // pk_mem  (PK_MEM_ADDR_W=6, PK_MEM_DATA_W=320, PK_MEM_WSTROBE_W=40)
  // -----------------------------------------------------------------------
  output wire          pk_mem_we_o,
  output wire [5:0]    pk_mem_waddr_o,
  output wire [319:0]  pk_mem_wdata_o,
  output wire [39:0]   pk_mem_wstrobe_o,
  output wire          pk_mem_re_o,
  output wire [5:0]    pk_mem_raddr_o,
  input  wire [319:0]  pk_mem_rdata_i
);

//`ifdef RV_FPGA_SCA
//    assign NTT_trigger = '0;
//    assign PWM_trigger = '0;
//    assign PWA_trigger = '0;
//    assign INTT_trigger = '0;
//`endif
//
//    assign hresp_o    = '0;
//    assign hreadyout_o = '0;
//    assign hrdata_o   = '0;
//    assign busy_o     = '0;
//    assign error_intr = '0;
//    assign notif_intr = '0;
//
//    assign w1_mem_we_o    = '0;
//    assign w1_mem_waddr_o = '0;
//    assign w1_mem_wdata_o = '0;
//    assign w1_mem_re_o    = '0;
//    assign w1_mem_raddr_o = '0;
//
//    assign mem_inst0_bank0_we_o    = '0;
//    assign mem_inst0_bank0_waddr_o = '0;
//    assign mem_inst0_bank0_wdata_o = '0;
//    assign mem_inst0_bank0_re_o    = '0;
//    assign mem_inst0_bank0_raddr_o = '0;
//
//    assign mem_inst0_bank1_we_o    = '0;
//    assign mem_inst0_bank1_waddr_o = '0;
//    assign mem_inst0_bank1_wdata_o = '0;
//    assign mem_inst0_bank1_re_o    = '0;
//    assign mem_inst0_bank1_raddr_o = '0;
//
//    assign mem_inst1_we_o    = '0;
//    assign mem_inst1_waddr_o = '0;
//    assign mem_inst1_wdata_o = '0;
//    assign mem_inst1_re_o    = '0;
//    assign mem_inst1_raddr_o = '0;
//
//    assign mem_inst2_we_o    = '0;
//    assign mem_inst2_waddr_o = '0;
//    assign mem_inst2_wdata_o = '0;
//    assign mem_inst2_re_o    = '0;
//    assign mem_inst2_raddr_o = '0;
//
//    assign mem_inst3_we_o    = '0;
//    assign mem_inst3_waddr_o = '0;
//    assign mem_inst3_wdata_o = '0;
//    assign mem_inst3_re_o    = '0;
//    assign mem_inst3_raddr_o = '0;
//
//    assign sk_mem_bank0_we_o    = '0;
//    assign sk_mem_bank0_waddr_o = '0;
//    assign sk_mem_bank0_wdata_o = '0;
//    assign sk_mem_bank0_re_o    = '0;
//    assign sk_mem_bank0_raddr_o = '0;
//
//    assign sk_mem_bank1_we_o    = '0;
//    assign sk_mem_bank1_waddr_o = '0;
//    assign sk_mem_bank1_wdata_o = '0;
//    assign sk_mem_bank1_re_o    = '0;
//    assign sk_mem_bank1_raddr_o = '0;
//
//    assign sig_z_mem_we_o      = '0;
//    assign sig_z_mem_waddr_o   = '0;
//    assign sig_z_mem_wdata_o   = '0;
//    assign sig_z_mem_wstrobe_o = '0;
//    assign sig_z_mem_re_o      = '0;
//    assign sig_z_mem_raddr_o   = '0;
//
//    assign pk_mem_we_o      = '0;
//    assign pk_mem_waddr_o   = '0;
//    assign pk_mem_wdata_o   = '0;
//    assign pk_mem_wstrobe_o = '0;
//    assign pk_mem_re_o      = '0;
//    assign pk_mem_raddr_o   = '0;

endmodule

