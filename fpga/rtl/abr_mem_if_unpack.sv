// abr_mem_if_unpack.sv — unpacks abr_mem_if into flat wire signals.
//
// Bridges the SystemVerilog abr_mem_if interface (resp modport) to a set of
// flat logic ports compatible with plain Verilog memory modules.
//
// Port naming follows the module-port convention: _o signals are outputs from
// this module (control signals driven into the memory) and _i signals are
// inputs to this module (read data returned from the memory).
//
// Usage: instantiate in place of abr_mem_fpga, connect abr_memory_export to
// the abr_fpga_top interface, then connect the flat ports to a Verilog memory.

module abr_mem_if_unpack
    import abr_params_pkg::*;
    import abr_ctrl_pkg::*;
(
    abr_mem_if.resp abr_memory_export,

    // -----------------------------------------------------------------------
    // w1_mem
    // -----------------------------------------------------------------------
    output logic                             w1_mem_we_o,
    output logic [ABR_MEM_W1_ADDR_W-1:0]    w1_mem_waddr_o,
    output logic [ABR_MEM_W1_DATA_W-1:0]    w1_mem_wdata_o,
    output logic                             w1_mem_re_o,
    output logic [ABR_MEM_W1_ADDR_W-1:0]    w1_mem_raddr_o,
    input  logic [ABR_MEM_W1_DATA_W-1:0]    w1_mem_rdata_i,

    // -----------------------------------------------------------------------
    // mem_inst0_bank0
    // -----------------------------------------------------------------------
    output logic                             mem_inst0_bank0_we_o,
    output logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank0_waddr_o,
    output logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank0_wdata_o,
    output logic                             mem_inst0_bank0_re_o,
    output logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank0_raddr_o,
    input  logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank0_rdata_i,

    // -----------------------------------------------------------------------
    // mem_inst0_bank1
    // -----------------------------------------------------------------------
    output logic                             mem_inst0_bank1_we_o,
    output logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank1_waddr_o,
    output logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank1_wdata_o,
    output logic                             mem_inst0_bank1_re_o,
    output logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank1_raddr_o,
    input  logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank1_rdata_i,

    // -----------------------------------------------------------------------
    // mem_inst1
    // -----------------------------------------------------------------------
    output logic                             mem_inst1_we_o,
    output logic [ABR_MEM_INST1_ADDR_W-1:0] mem_inst1_waddr_o,
    output logic [ABR_MEM_INST1_DATA_W-1:0] mem_inst1_wdata_o,
    output logic                             mem_inst1_re_o,
    output logic [ABR_MEM_INST1_ADDR_W-1:0] mem_inst1_raddr_o,
    input  logic [ABR_MEM_INST1_DATA_W-1:0] mem_inst1_rdata_i,

    // -----------------------------------------------------------------------
    // mem_inst2
    // -----------------------------------------------------------------------
    output logic                             mem_inst2_we_o,
    output logic [ABR_MEM_INST2_ADDR_W-1:0] mem_inst2_waddr_o,
    output logic [ABR_MEM_INST2_DATA_W-1:0] mem_inst2_wdata_o,
    output logic                             mem_inst2_re_o,
    output logic [ABR_MEM_INST2_ADDR_W-1:0] mem_inst2_raddr_o,
    input  logic [ABR_MEM_INST2_DATA_W-1:0] mem_inst2_rdata_i,

    // -----------------------------------------------------------------------
    // mem_inst3  (masked data path — wide)
    // -----------------------------------------------------------------------
    output logic                             mem_inst3_we_o,
    output logic [ABR_MEM_INST3_ADDR_W-1:0] mem_inst3_waddr_o,
    output logic [ABR_MEM_INST3_DATA_W-1:0] mem_inst3_wdata_o,
    output logic                             mem_inst3_re_o,
    output logic [ABR_MEM_INST3_ADDR_W-1:0] mem_inst3_raddr_o,
    input  logic [ABR_MEM_INST3_DATA_W-1:0] mem_inst3_rdata_i,

    // -----------------------------------------------------------------------
    // sk_mem_bank0
    // -----------------------------------------------------------------------
    output logic                             sk_mem_bank0_we_o,
    output logic [SK_MEM_BANK_ADDR_W-1:0]   sk_mem_bank0_waddr_o,
    output logic [SK_MEM_BANK_DATA_W-1:0]   sk_mem_bank0_wdata_o,
    output logic                             sk_mem_bank0_re_o,
    output logic [SK_MEM_BANK_ADDR_W-1:0]   sk_mem_bank0_raddr_o,
    input  logic [SK_MEM_BANK_DATA_W-1:0]   sk_mem_bank0_rdata_i,

    // -----------------------------------------------------------------------
    // sk_mem_bank1
    // -----------------------------------------------------------------------
    output logic                             sk_mem_bank1_we_o,
    output logic [SK_MEM_BANK_ADDR_W-1:0]   sk_mem_bank1_waddr_o,
    output logic [SK_MEM_BANK_DATA_W-1:0]   sk_mem_bank1_wdata_o,
    output logic                             sk_mem_bank1_re_o,
    output logic [SK_MEM_BANK_ADDR_W-1:0]   sk_mem_bank1_raddr_o,
    input  logic [SK_MEM_BANK_DATA_W-1:0]   sk_mem_bank1_rdata_i,

    // -----------------------------------------------------------------------
    // sig_z_mem  (byte-enable)
    // -----------------------------------------------------------------------
    output logic                             sig_z_mem_we_o,
    output logic [SIG_Z_MEM_ADDR_W-1:0]     sig_z_mem_waddr_o,
    output logic [SIG_Z_MEM_DATA_W-1:0]     sig_z_mem_wdata_o,
    output logic [SIG_Z_MEM_WSTROBE_W-1:0]  sig_z_mem_wstrobe_o,
    output logic                             sig_z_mem_re_o,
    output logic [SIG_Z_MEM_ADDR_W-1:0]     sig_z_mem_raddr_o,
    input  logic [SIG_Z_MEM_DATA_W-1:0]     sig_z_mem_rdata_i,

    // -----------------------------------------------------------------------
    // pk_mem  (byte-enable)
    // -----------------------------------------------------------------------
    output logic                             pk_mem_we_o,
    output logic [PK_MEM_ADDR_W-1:0]        pk_mem_waddr_o,
    output logic [PK_MEM_DATA_W-1:0]        pk_mem_wdata_o,
    output logic [PK_MEM_WSTROBE_W-1:0]     pk_mem_wstrobe_o,
    output logic                             pk_mem_re_o,
    output logic [PK_MEM_ADDR_W-1:0]        pk_mem_raddr_o,
    input  logic [PK_MEM_DATA_W-1:0]        pk_mem_rdata_i
);

    // -----------------------------------------------------------------------
    // w1_mem
    // -----------------------------------------------------------------------
    assign w1_mem_we_o                        = abr_memory_export.w1_mem_we_i;
    assign w1_mem_waddr_o                     = abr_memory_export.w1_mem_waddr_i;
    assign w1_mem_wdata_o                     = abr_memory_export.w1_mem_wdata_i;
    assign w1_mem_re_o                        = abr_memory_export.w1_mem_re_i;
    assign w1_mem_raddr_o                     = abr_memory_export.w1_mem_raddr_i;
    assign abr_memory_export.w1_mem_rdata_o   = w1_mem_rdata_i;

    // -----------------------------------------------------------------------
    // mem_inst0_bank0
    // -----------------------------------------------------------------------
    assign mem_inst0_bank0_we_o                        = abr_memory_export.mem_inst0_bank0_we_i;
    assign mem_inst0_bank0_waddr_o                     = abr_memory_export.mem_inst0_bank0_waddr_i;
    assign mem_inst0_bank0_wdata_o                     = abr_memory_export.mem_inst0_bank0_wdata_i;
    assign mem_inst0_bank0_re_o                        = abr_memory_export.mem_inst0_bank0_re_i;
    assign mem_inst0_bank0_raddr_o                     = abr_memory_export.mem_inst0_bank0_raddr_i;
    assign abr_memory_export.mem_inst0_bank0_rdata_o   = mem_inst0_bank0_rdata_i;

    // -----------------------------------------------------------------------
    // mem_inst0_bank1
    // -----------------------------------------------------------------------
    assign mem_inst0_bank1_we_o                        = abr_memory_export.mem_inst0_bank1_we_i;
    assign mem_inst0_bank1_waddr_o                     = abr_memory_export.mem_inst0_bank1_waddr_i;
    assign mem_inst0_bank1_wdata_o                     = abr_memory_export.mem_inst0_bank1_wdata_i;
    assign mem_inst0_bank1_re_o                        = abr_memory_export.mem_inst0_bank1_re_i;
    assign mem_inst0_bank1_raddr_o                     = abr_memory_export.mem_inst0_bank1_raddr_i;
    assign abr_memory_export.mem_inst0_bank1_rdata_o   = mem_inst0_bank1_rdata_i;

    // -----------------------------------------------------------------------
    // mem_inst1
    // -----------------------------------------------------------------------
    assign mem_inst1_we_o                      = abr_memory_export.mem_inst1_we_i;
    assign mem_inst1_waddr_o                   = abr_memory_export.mem_inst1_waddr_i;
    assign mem_inst1_wdata_o                   = abr_memory_export.mem_inst1_wdata_i;
    assign mem_inst1_re_o                      = abr_memory_export.mem_inst1_re_i;
    assign mem_inst1_raddr_o                   = abr_memory_export.mem_inst1_raddr_i;
    assign abr_memory_export.mem_inst1_rdata_o = mem_inst1_rdata_i;

    // -----------------------------------------------------------------------
    // mem_inst2
    // -----------------------------------------------------------------------
    assign mem_inst2_we_o                      = abr_memory_export.mem_inst2_we_i;
    assign mem_inst2_waddr_o                   = abr_memory_export.mem_inst2_waddr_i;
    assign mem_inst2_wdata_o                   = abr_memory_export.mem_inst2_wdata_i;
    assign mem_inst2_re_o                      = abr_memory_export.mem_inst2_re_i;
    assign mem_inst2_raddr_o                   = abr_memory_export.mem_inst2_raddr_i;
    assign abr_memory_export.mem_inst2_rdata_o = mem_inst2_rdata_i;

    // -----------------------------------------------------------------------
    // mem_inst3
    // -----------------------------------------------------------------------
    assign mem_inst3_we_o                      = abr_memory_export.mem_inst3_we_i;
    assign mem_inst3_waddr_o                   = abr_memory_export.mem_inst3_waddr_i;
    assign mem_inst3_wdata_o                   = abr_memory_export.mem_inst3_wdata_i;
    assign mem_inst3_re_o                      = abr_memory_export.mem_inst3_re_i;
    assign mem_inst3_raddr_o                   = abr_memory_export.mem_inst3_raddr_i;
    assign abr_memory_export.mem_inst3_rdata_o = mem_inst3_rdata_i;

    // -----------------------------------------------------------------------
    // sk_mem_bank0
    // -----------------------------------------------------------------------
    assign sk_mem_bank0_we_o                      = abr_memory_export.sk_mem_bank0_we_i;
    assign sk_mem_bank0_waddr_o                   = abr_memory_export.sk_mem_bank0_waddr_i;
    assign sk_mem_bank0_wdata_o                   = abr_memory_export.sk_mem_bank0_wdata_i;
    assign sk_mem_bank0_re_o                      = abr_memory_export.sk_mem_bank0_re_i;
    assign sk_mem_bank0_raddr_o                   = abr_memory_export.sk_mem_bank0_raddr_i;
    assign abr_memory_export.sk_mem_bank0_rdata_o = sk_mem_bank0_rdata_i;

    // -----------------------------------------------------------------------
    // sk_mem_bank1
    // -----------------------------------------------------------------------
    assign sk_mem_bank1_we_o                      = abr_memory_export.sk_mem_bank1_we_i;
    assign sk_mem_bank1_waddr_o                   = abr_memory_export.sk_mem_bank1_waddr_i;
    assign sk_mem_bank1_wdata_o                   = abr_memory_export.sk_mem_bank1_wdata_i;
    assign sk_mem_bank1_re_o                      = abr_memory_export.sk_mem_bank1_re_i;
    assign sk_mem_bank1_raddr_o                   = abr_memory_export.sk_mem_bank1_raddr_i;
    assign abr_memory_export.sk_mem_bank1_rdata_o = sk_mem_bank1_rdata_i;

    // -----------------------------------------------------------------------
    // sig_z_mem
    // -----------------------------------------------------------------------
    assign sig_z_mem_we_o                       = abr_memory_export.sig_z_mem_we_i;
    assign sig_z_mem_waddr_o                    = abr_memory_export.sig_z_mem_waddr_i;
    assign sig_z_mem_wdata_o                    = abr_memory_export.sig_z_mem_wdata_i;
    assign sig_z_mem_wstrobe_o                  = abr_memory_export.sig_z_mem_wstrobe_i;
    assign sig_z_mem_re_o                       = abr_memory_export.sig_z_mem_re_i;
    assign sig_z_mem_raddr_o                    = abr_memory_export.sig_z_mem_raddr_i;
    assign abr_memory_export.sig_z_mem_rdata_o  = sig_z_mem_rdata_i;

    // -----------------------------------------------------------------------
    // pk_mem
    // -----------------------------------------------------------------------
    assign pk_mem_we_o                         = abr_memory_export.pk_mem_we_i;
    assign pk_mem_waddr_o                      = abr_memory_export.pk_mem_waddr_i;
    assign pk_mem_wdata_o                      = abr_memory_export.pk_mem_wdata_i;
    assign pk_mem_wstrobe_o                    = abr_memory_export.pk_mem_wstrobe_i;
    assign pk_mem_re_o                         = abr_memory_export.pk_mem_re_i;
    assign pk_mem_raddr_o                      = abr_memory_export.pk_mem_raddr_i;
    assign abr_memory_export.pk_mem_rdata_o    = pk_mem_rdata_i;

endmodule
