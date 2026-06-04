// abr_fpga_top.sv — FPGA top-level wrapper for abr_top (ML-DSA accelerator).
//
// Instantiates:
//   • abr_top        — the Adams Bridge ML-DSA/ML-KEM RTL core
//   • abr_mem_fpga   — BRAM-backed memory subsystem
//   • ahb_mgr        — AHB-Lite manager driving abr_top's subordinate port
//
// An internal FSM loads static test-vector data from abr_fpga_pkg into the
// core's register map over AHB, triggers the selected operation, and waits
// for completion.
//
// Compile-time parameter:
//   OPERATION — one of the abr_fpga_pkg::op_e values:
//                 OP_KEYGEN | OP_SIGN | OP_VERIFY | OP_KGSIGN
//
// AHB data width is 64 bits (abr_top default).  All register accesses are
// 32-bit (HSIZE=010).  Lane placement follows addr[2]: upper lane when
// addr[2]=1, lower lane when addr[2]=0.
//
// Reset protocol: rst_ni is the external active-low reset.  The FSM drives
// abr_top's rst_b low for RESET_CYCLES then releases it.

`include "abr_config_defines.svh"
`include "abr_prim_assert.sv"

module abr_fpga_top
  import abr_fpga_pkg::*;
  import abr_params_pkg::*;
  import abr_ctrl_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,      // active-low board/PLL reset

`ifdef RV_FPGA_SCA
  output wire NTT_trigger,
  output wire PWM_trigger,
  output wire PWA_trigger,
  output wire INTT_trigger,
`endif

  //ahb input
  input  wire  [AHB_ADDR_WIDTH-1:0] haddr_i,
  input  wire  [AHB_DATA_WIDTH-1:0] hwdata_i,
  input  wire                       hsel_i,
  input  wire                       hwrite_i,
  input  wire                       hready_i,
  input  wire  [               1:0] htrans_i,
  input  wire  [               2:0] hsize_i,
  //ahb output
  output wire                       hresp_o,
  output wire                       hreadyout_o,
  output wire  [AHB_DATA_WIDTH-1:0] hrdata_o,
  // abr_top status pass-through
  output logic                      busy_o,
  output logic                      error_intr_o,
  output logic                      notif_intr_o
);

  timeunit 1ns/1ps;

  // -----------------------------------------------------------------------
  // AHB bus parameters
  // -----------------------------------------------------------------------
  localparam int unsigned AHB_ADDR_W = 32;
  localparam int unsigned AHB_DATA_W = 64;  // abr_top default

  // -----------------------------------------------------------------------
  // Memory interface
  // -----------------------------------------------------------------------
  abr_mem_if abr_memory_export();

  // Flat signals connecting abr_top_wrapper ↔ abr_mem_if_pack
  logic                            w1_mem_we,       w1_mem_re;
  logic [   ABR_MEM_W1_ADDR_W-1:0] w1_mem_waddr,    w1_mem_raddr;
  logic [   ABR_MEM_W1_DATA_W-1:0] w1_mem_wdata,    w1_mem_rdata;

  logic                            mem_inst0_bank0_we,    mem_inst0_bank0_re;
  logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank0_waddr, mem_inst0_bank0_raddr;
  logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank0_wdata, mem_inst0_bank0_rdata;

  logic                            mem_inst0_bank1_we,    mem_inst0_bank1_re;
  logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank1_waddr, mem_inst0_bank1_raddr;
  logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank1_wdata, mem_inst0_bank1_rdata;

  logic                            mem_inst1_we,    mem_inst1_re;
  logic [ABR_MEM_INST1_ADDR_W-1:0] mem_inst1_waddr, mem_inst1_raddr;
  logic [ABR_MEM_INST1_DATA_W-1:0] mem_inst1_wdata, mem_inst1_rdata;

  logic                            mem_inst2_we,    mem_inst2_re;
  logic [ABR_MEM_INST2_ADDR_W-1:0] mem_inst2_waddr, mem_inst2_raddr;
  logic [ABR_MEM_INST2_DATA_W-1:0] mem_inst2_wdata, mem_inst2_rdata;

  logic                            mem_inst3_we,    mem_inst3_re;
  logic [ABR_MEM_INST3_ADDR_W-1:0] mem_inst3_waddr, mem_inst3_raddr;
  logic [ABR_MEM_INST3_DATA_W-1:0] mem_inst3_wdata, mem_inst3_rdata;

  logic                            sk_mem_bank0_we,    sk_mem_bank0_re;
  logic [ SK_MEM_BANK_ADDR_W-1:0]  sk_mem_bank0_waddr, sk_mem_bank0_raddr;
  logic [ SK_MEM_BANK_DATA_W-1:0]  sk_mem_bank0_wdata, sk_mem_bank0_rdata;

  logic                            sk_mem_bank1_we,    sk_mem_bank1_re;
  logic [ SK_MEM_BANK_ADDR_W-1:0]  sk_mem_bank1_waddr, sk_mem_bank1_raddr;
  logic [ SK_MEM_BANK_DATA_W-1:0]  sk_mem_bank1_wdata, sk_mem_bank1_rdata;

  logic                            sig_z_mem_we,    sig_z_mem_re;
  logic [   SIG_Z_MEM_ADDR_W-1:0]  sig_z_mem_waddr, sig_z_mem_raddr;
  logic [   SIG_Z_MEM_DATA_W-1:0]  sig_z_mem_wdata, sig_z_mem_rdata;
  logic [SIG_Z_MEM_WSTROBE_W-1:0]  sig_z_mem_wstrobe;

  logic                            pk_mem_we,    pk_mem_re;
  logic [      PK_MEM_ADDR_W-1:0]  pk_mem_waddr, pk_mem_raddr;
  logic [      PK_MEM_DATA_W-1:0]  pk_mem_wdata, pk_mem_rdata;
  logic [   PK_MEM_WSTROBE_W-1:0]  pk_mem_wstrobe;

  // -----------------------------------------------------------------------
  // abr_mem_fpga instantiation
  // -----------------------------------------------------------------------
  abr_mem_fpga mem_inst (
    .clk_i             ( clk_i             ),
    .abr_memory_export ( abr_memory_export )
  );

  // -----------------------------------------------------------------------
  // abr_top instantiation
  // -----------------------------------------------------------------------
  abr_top_wrapper #(
    .AHB_ADDR_WIDTH    (AHB_ADDR_W),
    .AHB_DATA_WIDTH    (AHB_DATA_W),
    .CLIENT_DATA_WIDTH (32)
  ) i_abr_top_wrapper (
    .clk                             ( clk_i                  ),
    .rst_b                           ( rst_ni                 ),
`ifdef RV_FPGA_SCA
    .NTT_trigger                     ( NTT_trigger            ),
    .PWM_trigger                     ( PWM_trigger            ),
    .PWA_trigger                     ( PWA_trigger            ),
    .INTT_trigger                    ( INTT_trigger           ),
`endif
    .haddr_i                         ( haddr_i                ),
    .hwdata_i                        ( hwdata_i               ),
    .hsel_i                          ( hsel_i                 ),
    .hwrite_i                        ( hwrite_i               ),
    .hready_i                        ( hready_i               ),
    .htrans_i                        ( htrans_i               ),
    .hsize_i                         ( hsize_i                ),
    .hresp_o                         ( hresp_o                ),
    .hreadyout_o                     ( hreadyout_o            ),
    .hrdata_o                        ( hrdata_o               ),
    .debugUnlock_or_scan_mode_switch ('0                      ),
    .busy_o                          ( busy_o                 ),
    .error_intr                      ( error_intr_o           ),
    .notif_intr                      ( notif_intr_o           ),

    .w1_mem_we_o                     ( w1_mem_we             ),
    .w1_mem_waddr_o                  ( w1_mem_waddr          ),
    .w1_mem_wdata_o                  ( w1_mem_wdata          ),
    .w1_mem_re_o                     ( w1_mem_re             ),
    .w1_mem_raddr_o                  ( w1_mem_raddr          ),
    .w1_mem_rdata_i                  ( w1_mem_rdata          ),
    .mem_inst0_bank0_we_o            ( mem_inst0_bank0_we    ),
    .mem_inst0_bank0_waddr_o         ( mem_inst0_bank0_waddr ),
    .mem_inst0_bank0_wdata_o         ( mem_inst0_bank0_wdata ),
    .mem_inst0_bank0_re_o            ( mem_inst0_bank0_re    ),
    .mem_inst0_bank0_raddr_o         ( mem_inst0_bank0_raddr ),
    .mem_inst0_bank0_rdata_i         ( mem_inst0_bank0_rdata ),
    .mem_inst0_bank1_we_o            ( mem_inst0_bank1_we    ),
    .mem_inst0_bank1_waddr_o         ( mem_inst0_bank1_waddr ),
    .mem_inst0_bank1_wdata_o         ( mem_inst0_bank1_wdata ),
    .mem_inst0_bank1_re_o            ( mem_inst0_bank1_re    ),
    .mem_inst0_bank1_raddr_o         ( mem_inst0_bank1_raddr ),
    .mem_inst0_bank1_rdata_i         ( mem_inst0_bank1_rdata ),
    .mem_inst1_we_o                  ( mem_inst1_we          ),
    .mem_inst1_waddr_o               ( mem_inst1_waddr       ),
    .mem_inst1_wdata_o               ( mem_inst1_wdata       ),
    .mem_inst1_re_o                  ( mem_inst1_re          ),
    .mem_inst1_raddr_o               ( mem_inst1_raddr       ),
    .mem_inst1_rdata_i               ( mem_inst1_rdata       ),
    .mem_inst2_we_o                  ( mem_inst2_we          ),
    .mem_inst2_waddr_o               ( mem_inst2_waddr       ),
    .mem_inst2_wdata_o               ( mem_inst2_wdata       ),
    .mem_inst2_re_o                  ( mem_inst2_re          ),
    .mem_inst2_raddr_o               ( mem_inst2_raddr       ),
    .mem_inst2_rdata_i               ( mem_inst2_rdata       ),
    .mem_inst3_we_o                  ( mem_inst3_we          ),
    .mem_inst3_waddr_o               ( mem_inst3_waddr       ),
    .mem_inst3_wdata_o               ( mem_inst3_wdata       ),
    .mem_inst3_re_o                  ( mem_inst3_re          ),
    .mem_inst3_raddr_o               ( mem_inst3_raddr       ),
    .mem_inst3_rdata_i               ( mem_inst3_rdata       ),
    .sk_mem_bank0_we_o               ( sk_mem_bank0_we       ),
    .sk_mem_bank0_waddr_o            ( sk_mem_bank0_waddr    ),
    .sk_mem_bank0_wdata_o            ( sk_mem_bank0_wdata    ),
    .sk_mem_bank0_re_o               ( sk_mem_bank0_re       ),
    .sk_mem_bank0_raddr_o            ( sk_mem_bank0_raddr    ),
    .sk_mem_bank0_rdata_i            ( sk_mem_bank0_rdata    ),
    .sk_mem_bank1_we_o               ( sk_mem_bank1_we       ),
    .sk_mem_bank1_waddr_o            ( sk_mem_bank1_waddr    ),
    .sk_mem_bank1_wdata_o            ( sk_mem_bank1_wdata    ),
    .sk_mem_bank1_re_o               ( sk_mem_bank1_re       ),
    .sk_mem_bank1_raddr_o            ( sk_mem_bank1_raddr    ),
    .sk_mem_bank1_rdata_i            ( sk_mem_bank1_rdata    ),
    .sig_z_mem_we_o                  ( sig_z_mem_we          ),
    .sig_z_mem_waddr_o               ( sig_z_mem_waddr       ),
    .sig_z_mem_wdata_o               ( sig_z_mem_wdata       ),
    .sig_z_mem_wstrobe_o             ( sig_z_mem_wstrobe     ),
    .sig_z_mem_re_o                  ( sig_z_mem_re          ),
    .sig_z_mem_raddr_o               ( sig_z_mem_raddr       ),
    .sig_z_mem_rdata_i               ( sig_z_mem_rdata       ),
    .pk_mem_we_o                     ( pk_mem_we             ),
    .pk_mem_waddr_o                  ( pk_mem_waddr          ),
    .pk_mem_wdata_o                  ( pk_mem_wdata          ),
    .pk_mem_wstrobe_o                ( pk_mem_wstrobe        ),
    .pk_mem_re_o                     ( pk_mem_re             ),
    .pk_mem_raddr_o                  ( pk_mem_raddr          ),
    .pk_mem_rdata_i                  ( pk_mem_rdata          )
  );

  // -----------------------------------------------------------------------
  // abr_mem_if_pack instantiation — packs the abr_memory_export interface
  // signals from abr_top_wrapper
  // -----------------------------------------------------------------------
  abr_mem_if_pack mem_pack (
      .abr_memory_export       ( abr_memory_export      ),
      .w1_mem_we_i             ( w1_mem_we              ),
      .w1_mem_waddr_i          ( w1_mem_waddr           ),
      .w1_mem_wdata_i          ( w1_mem_wdata           ),
      .w1_mem_re_i             ( w1_mem_re              ),
      .w1_mem_raddr_i          ( w1_mem_raddr           ),
      .w1_mem_rdata_o          ( w1_mem_rdata           ),
      .mem_inst0_bank0_we_i    ( mem_inst0_bank0_we     ),
      .mem_inst0_bank0_waddr_i ( mem_inst0_bank0_waddr  ),
      .mem_inst0_bank0_wdata_i ( mem_inst0_bank0_wdata  ),
      .mem_inst0_bank0_re_i    ( mem_inst0_bank0_re     ),
      .mem_inst0_bank0_raddr_i ( mem_inst0_bank0_raddr  ),
      .mem_inst0_bank0_rdata_o ( mem_inst0_bank0_rdata  ),
      .mem_inst0_bank1_we_i    ( mem_inst0_bank1_we     ),
      .mem_inst0_bank1_waddr_i ( mem_inst0_bank1_waddr  ),
      .mem_inst0_bank1_wdata_i ( mem_inst0_bank1_wdata  ),
      .mem_inst0_bank1_re_i    ( mem_inst0_bank1_re     ),
      .mem_inst0_bank1_raddr_i ( mem_inst0_bank1_raddr  ),
      .mem_inst0_bank1_rdata_o ( mem_inst0_bank1_rdata  ),
      .mem_inst1_we_i          ( mem_inst1_we           ),
      .mem_inst1_waddr_i       ( mem_inst1_waddr        ),
      .mem_inst1_wdata_i       ( mem_inst1_wdata        ),
      .mem_inst1_re_i          ( mem_inst1_re           ),
      .mem_inst1_raddr_i       ( mem_inst1_raddr        ),
      .mem_inst1_rdata_o       ( mem_inst1_rdata        ),
      .mem_inst2_we_i          ( mem_inst2_we           ),
      .mem_inst2_waddr_i       ( mem_inst2_waddr        ),
      .mem_inst2_wdata_i       ( mem_inst2_wdata        ),
      .mem_inst2_re_i          ( mem_inst2_re           ),
      .mem_inst2_raddr_i       ( mem_inst2_raddr        ),
      .mem_inst2_rdata_o       ( mem_inst2_rdata        ),
      .mem_inst3_we_i          ( mem_inst3_we           ),
      .mem_inst3_waddr_i       ( mem_inst3_waddr        ),
      .mem_inst3_wdata_i       ( mem_inst3_wdata        ),
      .mem_inst3_re_i          ( mem_inst3_re           ),
      .mem_inst3_raddr_i       ( mem_inst3_raddr        ),
      .mem_inst3_rdata_o       ( mem_inst3_rdata        ),
      .sk_mem_bank0_we_i       ( sk_mem_bank0_we        ),
      .sk_mem_bank0_waddr_i    ( sk_mem_bank0_waddr     ),
      .sk_mem_bank0_wdata_i    ( sk_mem_bank0_wdata     ),
      .sk_mem_bank0_re_i       ( sk_mem_bank0_re        ),
      .sk_mem_bank0_raddr_i    ( sk_mem_bank0_raddr     ),
      .sk_mem_bank0_rdata_o    ( sk_mem_bank0_rdata     ),
      .sk_mem_bank1_we_i       ( sk_mem_bank1_we        ),
      .sk_mem_bank1_waddr_i    ( sk_mem_bank1_waddr     ),
      .sk_mem_bank1_wdata_i    ( sk_mem_bank1_wdata     ),
      .sk_mem_bank1_re_i       ( sk_mem_bank1_re        ),
      .sk_mem_bank1_raddr_i    ( sk_mem_bank1_raddr     ),
      .sk_mem_bank1_rdata_o    ( sk_mem_bank1_rdata     ),
      .sig_z_mem_we_i          ( sig_z_mem_we           ),
      .sig_z_mem_waddr_i       ( sig_z_mem_waddr        ),
      .sig_z_mem_wdata_i       ( sig_z_mem_wdata        ),
      .sig_z_mem_wstrobe_i     ( sig_z_mem_wstrobe      ),
      .sig_z_mem_re_i          ( sig_z_mem_re           ),
      .sig_z_mem_raddr_i       ( sig_z_mem_raddr        ),
      .sig_z_mem_rdata_o       ( sig_z_mem_rdata        ),
      .pk_mem_we_i             ( pk_mem_we              ),
      .pk_mem_waddr_i          ( pk_mem_waddr           ),
      .pk_mem_wdata_i          ( pk_mem_wdata           ),
      .pk_mem_wstrobe_i        ( pk_mem_wstrobe         ),
      .pk_mem_re_i             ( pk_mem_re              ),
      .pk_mem_raddr_i          ( pk_mem_raddr           ),
      .pk_mem_rdata_o          ( pk_mem_rdata           )
  );

endmodule
