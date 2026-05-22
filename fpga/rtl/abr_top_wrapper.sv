// abr_top_wrapper.sv
// Top-level wrapper for abr_top, which breaks out the memory interface into
// separate ports for each bank to allow OOC synthesis of the memory arrays.

module abr_top_wrapper #(
  parameter AHB_ADDR_WIDTH    = 32,
  parameter AHB_DATA_WIDTH    = 64,
  parameter CLIENT_DATA_WIDTH = 32
) (
  input  logic clk,
  input  logic rst_b,

`ifdef RV_FPGA_SCA
  output wire NTT_trigger,
  output wire PWM_trigger,
  output wire PWA_trigger,
  output wire INTT_trigger,
`endif

  //ahb input
  input logic  [AHB_ADDR_WIDTH-1:0] haddr_i,
  input logic  [AHB_DATA_WIDTH-1:0] hwdata_i,
  input logic                       hsel_i,
  input logic                       hwrite_i,
  input logic                       hready_i,
  input logic  [1:0]                htrans_i,
  input logic  [2:0]                hsize_i,

  //ahb output
  output logic                      hresp_o,
  output logic                      hreadyout_o,
  output logic [AHB_DATA_WIDTH-1:0] hrdata_o,

  input logic debugUnlock_or_scan_mode_switch,

  output logic                      busy_o,

  output logic                      error_intr,
  output logic                      notif_intr,

  // -----------------------------------------------------------------------
  // w1_mem  (ABR_MEM_W1_ADDR_W=9, ABR_MEM_W1_DATA_W=4)
  // -----------------------------------------------------------------------
  output logic        w1_mem_we_o,
  output logic [8:0]  w1_mem_waddr_o,
  output logic [3:0]  w1_mem_wdata_o,
  output logic        w1_mem_re_o,
  output logic [8:0]  w1_mem_raddr_o,
  input  logic [3:0]  w1_mem_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst0_bank0  (ABR_MEM_INST0_ADDR_W=10, ABR_MEM_INST0_DATA_W=96)
  // -----------------------------------------------------------------------
  output logic         mem_inst0_bank0_we_o,
  output logic [9:0]   mem_inst0_bank0_waddr_o,
  output logic [95:0]  mem_inst0_bank0_wdata_o,
  output logic         mem_inst0_bank0_re_o,
  output logic [9:0]   mem_inst0_bank0_raddr_o,
  input  logic [95:0]  mem_inst0_bank0_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst0_bank1  (ABR_MEM_INST0_ADDR_W=10, ABR_MEM_INST0_DATA_W=96)
  // -----------------------------------------------------------------------
  output logic         mem_inst0_bank1_we_o,
  output logic [9:0]   mem_inst0_bank1_waddr_o,
  output logic [95:0]  mem_inst0_bank1_wdata_o,
  output logic         mem_inst0_bank1_re_o,
  output logic [9:0]   mem_inst0_bank1_raddr_o,
  input  logic [95:0]  mem_inst0_bank1_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst1  (ABR_MEM_INST1_ADDR_W=10, ABR_MEM_INST1_DATA_W=96)
  // -----------------------------------------------------------------------
  output logic         mem_inst1_we_o,
  output logic [9:0]   mem_inst1_waddr_o,
  output logic [95:0]  mem_inst1_wdata_o,
  output logic         mem_inst1_re_o,
  output logic [9:0]   mem_inst1_raddr_o,
  input  logic [95:0]  mem_inst1_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst2  (ABR_MEM_INST2_ADDR_W=11, ABR_MEM_INST2_DATA_W=96)
  // -----------------------------------------------------------------------
  output logic         mem_inst2_we_o,
  output logic [10:0]  mem_inst2_waddr_o,
  output logic [95:0]  mem_inst2_wdata_o,
  output logic         mem_inst2_re_o,
  output logic [10:0]  mem_inst2_raddr_o,
  input  logic [95:0]  mem_inst2_rdata_i,

  // -----------------------------------------------------------------------
  // mem_inst3  (ABR_MEM_INST3_ADDR_W=6, ABR_MEM_INST3_DATA_W=384)
  // -----------------------------------------------------------------------
  output logic          mem_inst3_we_o,
  output logic [5:0]    mem_inst3_waddr_o,
  output logic [383:0]  mem_inst3_wdata_o,
  output logic          mem_inst3_re_o,
  output logic [5:0]    mem_inst3_raddr_o,
  input  logic [383:0]  mem_inst3_rdata_i,

  // -----------------------------------------------------------------------
  // sk_mem_bank0  (SK_MEM_BANK_ADDR_W=10, SK_MEM_BANK_DATA_W=32)
  // -----------------------------------------------------------------------
  output logic         sk_mem_bank0_we_o,
  output logic [9:0]   sk_mem_bank0_waddr_o,
  output logic [31:0]  sk_mem_bank0_wdata_o,
  output logic         sk_mem_bank0_re_o,
  output logic [9:0]   sk_mem_bank0_raddr_o,
  input  logic [31:0]  sk_mem_bank0_rdata_i,

  // -----------------------------------------------------------------------
  // sk_mem_bank1  (SK_MEM_BANK_ADDR_W=10, SK_MEM_BANK_DATA_W=32)
  // -----------------------------------------------------------------------
  output logic         sk_mem_bank1_we_o,
  output logic [9:0]   sk_mem_bank1_waddr_o,
  output logic [31:0]  sk_mem_bank1_wdata_o,
  output logic         sk_mem_bank1_re_o,
  output logic [9:0]   sk_mem_bank1_raddr_o,
  input  logic [31:0]  sk_mem_bank1_rdata_i,

  // -----------------------------------------------------------------------
  // sig_z_mem  (SIG_Z_MEM_ADDR_W=8, SIG_Z_MEM_DATA_W=160, SIG_Z_MEM_WSTROBE_W=20)
  // -----------------------------------------------------------------------
  output logic          sig_z_mem_we_o,
  output logic [7:0]    sig_z_mem_waddr_o,
  output logic [159:0]  sig_z_mem_wdata_o,
  output logic [19:0]   sig_z_mem_wstrobe_o,
  output logic          sig_z_mem_re_o,
  output logic [7:0]    sig_z_mem_raddr_o,
  input  logic [159:0]  sig_z_mem_rdata_i,

  // -----------------------------------------------------------------------
  // pk_mem  (PK_MEM_ADDR_W=6, PK_MEM_DATA_W=320, PK_MEM_WSTROBE_W=40)
  // -----------------------------------------------------------------------
  output logic          pk_mem_we_o,
  output logic [5:0]    pk_mem_waddr_o,
  output logic [319:0]  pk_mem_wdata_o,
  output logic [39:0]   pk_mem_wstrobe_o,
  output logic          pk_mem_re_o,
  output logic [5:0]    pk_mem_raddr_o,
  input  logic [319:0]  pk_mem_rdata_i
);

    // -----------------------------------------------------------------------
    // Memory interface
    // -----------------------------------------------------------------------
    abr_mem_if abr_memory_export();

    abr_mem_if_unpack i_abr_mem_if_unpack
(
    .abr_memory_export       ( abr_memory_export       ),
    .w1_mem_we_o             ( w1_mem_we_o             ),
    .w1_mem_waddr_o          ( w1_mem_waddr_o          ),
    .w1_mem_wdata_o          ( w1_mem_wdata_o          ),
    .w1_mem_re_o             ( w1_mem_re_o             ),
    .w1_mem_raddr_o          ( w1_mem_raddr_o          ),
    .w1_mem_rdata_i          ( w1_mem_rdata_i          ),
    .mem_inst0_bank0_we_o    ( mem_inst0_bank0_we_o    ),
    .mem_inst0_bank0_waddr_o ( mem_inst0_bank0_waddr_o ),
    .mem_inst0_bank0_wdata_o ( mem_inst0_bank0_wdata_o ),
    .mem_inst0_bank0_re_o    ( mem_inst0_bank0_re_o    ),
    .mem_inst0_bank0_raddr_o ( mem_inst0_bank0_raddr_o ),
    .mem_inst0_bank0_rdata_i ( mem_inst0_bank0_rdata_i ),
    .mem_inst0_bank1_we_o    ( mem_inst0_bank1_we_o    ),
    .mem_inst0_bank1_waddr_o ( mem_inst0_bank1_waddr_o ),
    .mem_inst0_bank1_wdata_o ( mem_inst0_bank1_wdata_o ),
    .mem_inst0_bank1_re_o    ( mem_inst0_bank1_re_o    ),
    .mem_inst0_bank1_raddr_o ( mem_inst0_bank1_raddr_o ),
    .mem_inst0_bank1_rdata_i ( mem_inst0_bank1_rdata_i ),
    .mem_inst1_we_o          ( mem_inst1_we_o          ),
    .mem_inst1_waddr_o       ( mem_inst1_waddr_o       ),
    .mem_inst1_wdata_o       ( mem_inst1_wdata_o       ),
    .mem_inst1_re_o          ( mem_inst1_re_o          ),
    .mem_inst1_raddr_o       ( mem_inst1_raddr_o       ),
    .mem_inst1_rdata_i       ( mem_inst1_rdata_i       ),
    .mem_inst2_we_o          ( mem_inst2_we_o          ),
    .mem_inst2_waddr_o       ( mem_inst2_waddr_o       ),
    .mem_inst2_wdata_o       ( mem_inst2_wdata_o       ),
    .mem_inst2_re_o          ( mem_inst2_re_o          ),
    .mem_inst2_raddr_o       ( mem_inst2_raddr_o       ),
    .mem_inst2_rdata_i       ( mem_inst2_rdata_i       ),
    .mem_inst3_we_o          ( mem_inst3_we_o          ),
    .mem_inst3_waddr_o       ( mem_inst3_waddr_o       ),
    .mem_inst3_wdata_o       ( mem_inst3_wdata_o       ),
    .mem_inst3_re_o          ( mem_inst3_re_o          ),
    .mem_inst3_raddr_o       ( mem_inst3_raddr_o       ),
    .mem_inst3_rdata_i       ( mem_inst3_rdata_i       ),
    .sk_mem_bank0_we_o       ( sk_mem_bank0_we_o       ),
    .sk_mem_bank0_waddr_o    ( sk_mem_bank0_waddr_o    ),
    .sk_mem_bank0_wdata_o    ( sk_mem_bank0_wdata_o    ),
    .sk_mem_bank0_re_o       ( sk_mem_bank0_re_o       ),
    .sk_mem_bank0_raddr_o    ( sk_mem_bank0_raddr_o    ),
    .sk_mem_bank0_rdata_i    ( sk_mem_bank0_rdata_i    ),
    .sk_mem_bank1_we_o       ( sk_mem_bank1_we_o       ),
    .sk_mem_bank1_waddr_o    ( sk_mem_bank1_waddr_o    ),
    .sk_mem_bank1_wdata_o    ( sk_mem_bank1_wdata_o    ),
    .sk_mem_bank1_re_o       ( sk_mem_bank1_re_o       ),
    .sk_mem_bank1_raddr_o    ( sk_mem_bank1_raddr_o    ),
    .sk_mem_bank1_rdata_i    ( sk_mem_bank1_rdata_i    ),
    .sig_z_mem_we_o          ( sig_z_mem_we_o          ),
    .sig_z_mem_waddr_o       ( sig_z_mem_waddr_o       ),
    .sig_z_mem_wdata_o       ( sig_z_mem_wdata_o       ),
    .sig_z_mem_wstrobe_o     ( sig_z_mem_wstrobe_o     ),
    .sig_z_mem_re_o          ( sig_z_mem_re_o          ),
    .sig_z_mem_raddr_o       ( sig_z_mem_raddr_o       ),
    .sig_z_mem_rdata_i       ( sig_z_mem_rdata_i       ),
    .pk_mem_we_o             ( pk_mem_we_o             ),
    .pk_mem_waddr_o          ( pk_mem_waddr_o          ),
    .pk_mem_wdata_o          ( pk_mem_wdata_o          ),
    .pk_mem_wstrobe_o        ( pk_mem_wstrobe_o        ),
    .pk_mem_re_o             ( pk_mem_re_o             ),
    .pk_mem_raddr_o          ( pk_mem_raddr_o          ),
    .pk_mem_rdata_i          ( pk_mem_rdata_i          )
);

    // -----------------------------------------------------------------------
    // abr_top instantiation
    // -----------------------------------------------------------------------
    (* DONT_TOUCH = "yes" *)
    abr_top #(
        .AHB_ADDR_WIDTH    ( AHB_ADDR_WIDTH    ),
        .AHB_DATA_WIDTH    ( AHB_DATA_WIDTH    ),
        .CLIENT_DATA_WIDTH ( CLIENT_DATA_WIDTH )
    ) i_abr_top (
        .clk                             ( clk                            ),
        .rst_b                           ( rst_b                          ),
`ifdef RV_FPGA_SCA
        .NTT_trigger                     ( NTT_trigger                    ),
        .PWM_trigger                     ( PWM_trigger                    ),
        .PWA_trigger                     ( PWA_trigger                    ),
        .INTT_trigger                    ( INTT_trigger                   ),
`endif
        .haddr_i                         ( haddr_i                        ),
        .hwdata_i                        ( hwdata_i                       ),
        .hsel_i                          ( hsel_i                         ),
        .hwrite_i                        ( hwrite_i                       ),
        .hready_i                        ( hready_i                       ),
        .htrans_i                        ( htrans_i                       ),
        .hsize_i                         ( hsize_i                        ),
        .hresp_o                         ( hresp_o                        ),
        .hreadyout_o                     ( hreadyout_o                    ),
        .hrdata_o                        ( hrdata_o                       ),
        .abr_memory_export               ( abr_memory_export              ),
        .debugUnlock_or_scan_mode_switch (debugUnlock_or_scan_mode_switch ),
        .busy_o                          ( busy_o                         ),
        .error_intr                      ( error_intr                     ),
        .notif_intr                      ( notif_intr                     )
    );

endmodule: abr_top_wrapper
