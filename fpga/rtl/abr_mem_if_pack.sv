// abr_mem_if_pack.sv — packs flat wire signals into abr_mem_if.
//
// Reverse of abr_mem_if_unpack: accepts flat logic ports from a plain Verilog
// module acting as the memory requester and drives them into the req modport
// of abr_mem_if, which can then be connected to a SystemVerilog memory.
//
// Port naming follows the interface convention: _i signals are inputs to the
// memory (inputs to this module from the Verilog requester) and _o signals
// are outputs from the memory (outputs from this module to the Verilog
// requester).

module abr_mem_if_pack
    import abr_params_pkg::*;
    import abr_ctrl_pkg::*;
(
    abr_mem_if.req abr_memory_export,

    // -----------------------------------------------------------------------
    // w1_mem
    // -----------------------------------------------------------------------
    input  logic                             w1_mem_we_i,
    input  logic [ABR_MEM_W1_ADDR_W-1:0]    w1_mem_waddr_i,
    input  logic [ABR_MEM_W1_DATA_W-1:0]    w1_mem_wdata_i,
    input  logic                             w1_mem_re_i,
    input  logic [ABR_MEM_W1_ADDR_W-1:0]    w1_mem_raddr_i,
    output logic [ABR_MEM_W1_DATA_W-1:0]    w1_mem_rdata_o,

    // -----------------------------------------------------------------------
    // mem_inst0_bank0
    // -----------------------------------------------------------------------
    input  logic                             mem_inst0_bank0_we_i,
    input  logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank0_waddr_i,
    input  logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank0_wdata_i,
    input  logic                             mem_inst0_bank0_re_i,
    input  logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank0_raddr_i,
    output logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank0_rdata_o,

    // -----------------------------------------------------------------------
    // mem_inst0_bank1
    // -----------------------------------------------------------------------
    input  logic                             mem_inst0_bank1_we_i,
    input  logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank1_waddr_i,
    input  logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank1_wdata_i,
    input  logic                             mem_inst0_bank1_re_i,
    input  logic [ABR_MEM_INST0_ADDR_W-1:0] mem_inst0_bank1_raddr_i,
    output logic [ABR_MEM_INST0_DATA_W-1:0] mem_inst0_bank1_rdata_o,

    // -----------------------------------------------------------------------
    // mem_inst1
    // -----------------------------------------------------------------------
    input  logic                             mem_inst1_we_i,
    input  logic [ABR_MEM_INST1_ADDR_W-1:0] mem_inst1_waddr_i,
    input  logic [ABR_MEM_INST1_DATA_W-1:0] mem_inst1_wdata_i,
    input  logic                             mem_inst1_re_i,
    input  logic [ABR_MEM_INST1_ADDR_W-1:0] mem_inst1_raddr_i,
    output logic [ABR_MEM_INST1_DATA_W-1:0] mem_inst1_rdata_o,

    // -----------------------------------------------------------------------
    // mem_inst2
    // -----------------------------------------------------------------------
    input  logic                             mem_inst2_we_i,
    input  logic [ABR_MEM_INST2_ADDR_W-1:0] mem_inst2_waddr_i,
    input  logic [ABR_MEM_INST2_DATA_W-1:0] mem_inst2_wdata_i,
    input  logic                             mem_inst2_re_i,
    input  logic [ABR_MEM_INST2_ADDR_W-1:0] mem_inst2_raddr_i,
    output logic [ABR_MEM_INST2_DATA_W-1:0] mem_inst2_rdata_o,

    // -----------------------------------------------------------------------
    // mem_inst3  (masked data path — wide)
    // -----------------------------------------------------------------------
    input  logic                             mem_inst3_we_i,
    input  logic [ABR_MEM_INST3_ADDR_W-1:0] mem_inst3_waddr_i,
    input  logic [ABR_MEM_INST3_DATA_W-1:0] mem_inst3_wdata_i,
    input  logic                             mem_inst3_re_i,
    input  logic [ABR_MEM_INST3_ADDR_W-1:0] mem_inst3_raddr_i,
    output logic [ABR_MEM_INST3_DATA_W-1:0] mem_inst3_rdata_o,

    // -----------------------------------------------------------------------
    // sk_mem_bank0
    // -----------------------------------------------------------------------
    input  logic                             sk_mem_bank0_we_i,
    input  logic [SK_MEM_BANK_ADDR_W-1:0]   sk_mem_bank0_waddr_i,
    input  logic [SK_MEM_BANK_DATA_W-1:0]   sk_mem_bank0_wdata_i,
    input  logic                             sk_mem_bank0_re_i,
    input  logic [SK_MEM_BANK_ADDR_W-1:0]   sk_mem_bank0_raddr_i,
    output logic [SK_MEM_BANK_DATA_W-1:0]   sk_mem_bank0_rdata_o,

    // -----------------------------------------------------------------------
    // sk_mem_bank1
    // -----------------------------------------------------------------------
    input  logic                             sk_mem_bank1_we_i,
    input  logic [SK_MEM_BANK_ADDR_W-1:0]   sk_mem_bank1_waddr_i,
    input  logic [SK_MEM_BANK_DATA_W-1:0]   sk_mem_bank1_wdata_i,
    input  logic                             sk_mem_bank1_re_i,
    input  logic [SK_MEM_BANK_ADDR_W-1:0]   sk_mem_bank1_raddr_i,
    output logic [SK_MEM_BANK_DATA_W-1:0]   sk_mem_bank1_rdata_o,

    // -----------------------------------------------------------------------
    // sig_z_mem  (byte-enable)
    // -----------------------------------------------------------------------
    input  logic                             sig_z_mem_we_i,
    input  logic [SIG_Z_MEM_ADDR_W-1:0]     sig_z_mem_waddr_i,
    input  logic [SIG_Z_MEM_DATA_W-1:0]     sig_z_mem_wdata_i,
    input  logic [SIG_Z_MEM_WSTROBE_W-1:0]  sig_z_mem_wstrobe_i,
    input  logic                             sig_z_mem_re_i,
    input  logic [SIG_Z_MEM_ADDR_W-1:0]     sig_z_mem_raddr_i,
    output logic [SIG_Z_MEM_DATA_W-1:0]     sig_z_mem_rdata_o,

    // -----------------------------------------------------------------------
    // pk_mem  (byte-enable)
    // -----------------------------------------------------------------------
    input  logic                             pk_mem_we_i,
    input  logic [PK_MEM_ADDR_W-1:0]        pk_mem_waddr_i,
    input  logic [PK_MEM_DATA_W-1:0]        pk_mem_wdata_i,
    input  logic [PK_MEM_WSTROBE_W-1:0]     pk_mem_wstrobe_i,
    input  logic                             pk_mem_re_i,
    input  logic [PK_MEM_ADDR_W-1:0]        pk_mem_raddr_i,
    output logic [PK_MEM_DATA_W-1:0]        pk_mem_rdata_o
);

    // -----------------------------------------------------------------------
    // w1_mem
    // -----------------------------------------------------------------------
    assign abr_memory_export.w1_mem_we_i    = w1_mem_we_i;
    assign abr_memory_export.w1_mem_waddr_i = w1_mem_waddr_i;
    assign abr_memory_export.w1_mem_wdata_i = w1_mem_wdata_i;
    assign abr_memory_export.w1_mem_re_i    = w1_mem_re_i;
    assign abr_memory_export.w1_mem_raddr_i = w1_mem_raddr_i;
    assign w1_mem_rdata_o                   = abr_memory_export.w1_mem_rdata_o;

    // -----------------------------------------------------------------------
    // mem_inst0_bank0
    // -----------------------------------------------------------------------
    assign abr_memory_export.mem_inst0_bank0_we_i    = mem_inst0_bank0_we_i;
    assign abr_memory_export.mem_inst0_bank0_waddr_i = mem_inst0_bank0_waddr_i;
    assign abr_memory_export.mem_inst0_bank0_wdata_i = mem_inst0_bank0_wdata_i;
    assign abr_memory_export.mem_inst0_bank0_re_i    = mem_inst0_bank0_re_i;
    assign abr_memory_export.mem_inst0_bank0_raddr_i = mem_inst0_bank0_raddr_i;
    assign mem_inst0_bank0_rdata_o                   = abr_memory_export.mem_inst0_bank0_rdata_o;

    // -----------------------------------------------------------------------
    // mem_inst0_bank1
    // -----------------------------------------------------------------------
    assign abr_memory_export.mem_inst0_bank1_we_i    = mem_inst0_bank1_we_i;
    assign abr_memory_export.mem_inst0_bank1_waddr_i = mem_inst0_bank1_waddr_i;
    assign abr_memory_export.mem_inst0_bank1_wdata_i = mem_inst0_bank1_wdata_i;
    assign abr_memory_export.mem_inst0_bank1_re_i    = mem_inst0_bank1_re_i;
    assign abr_memory_export.mem_inst0_bank1_raddr_i = mem_inst0_bank1_raddr_i;
    assign mem_inst0_bank1_rdata_o                   = abr_memory_export.mem_inst0_bank1_rdata_o;

    // -----------------------------------------------------------------------
    // mem_inst1
    // -----------------------------------------------------------------------
    assign abr_memory_export.mem_inst1_we_i    = mem_inst1_we_i;
    assign abr_memory_export.mem_inst1_waddr_i = mem_inst1_waddr_i;
    assign abr_memory_export.mem_inst1_wdata_i = mem_inst1_wdata_i;
    assign abr_memory_export.mem_inst1_re_i    = mem_inst1_re_i;
    assign abr_memory_export.mem_inst1_raddr_i = mem_inst1_raddr_i;
    assign mem_inst1_rdata_o                   = abr_memory_export.mem_inst1_rdata_o;

    // -----------------------------------------------------------------------
    // mem_inst2
    // -----------------------------------------------------------------------
    assign abr_memory_export.mem_inst2_we_i    = mem_inst2_we_i;
    assign abr_memory_export.mem_inst2_waddr_i = mem_inst2_waddr_i;
    assign abr_memory_export.mem_inst2_wdata_i = mem_inst2_wdata_i;
    assign abr_memory_export.mem_inst2_re_i    = mem_inst2_re_i;
    assign abr_memory_export.mem_inst2_raddr_i = mem_inst2_raddr_i;
    assign mem_inst2_rdata_o                   = abr_memory_export.mem_inst2_rdata_o;

    // -----------------------------------------------------------------------
    // mem_inst3
    // -----------------------------------------------------------------------
    assign abr_memory_export.mem_inst3_we_i    = mem_inst3_we_i;
    assign abr_memory_export.mem_inst3_waddr_i = mem_inst3_waddr_i;
    assign abr_memory_export.mem_inst3_wdata_i = mem_inst3_wdata_i;
    assign abr_memory_export.mem_inst3_re_i    = mem_inst3_re_i;
    assign abr_memory_export.mem_inst3_raddr_i = mem_inst3_raddr_i;
    assign mem_inst3_rdata_o                   = abr_memory_export.mem_inst3_rdata_o;

    // -----------------------------------------------------------------------
    // sk_mem_bank0
    // -----------------------------------------------------------------------
    assign abr_memory_export.sk_mem_bank0_we_i    = sk_mem_bank0_we_i;
    assign abr_memory_export.sk_mem_bank0_waddr_i = sk_mem_bank0_waddr_i;
    assign abr_memory_export.sk_mem_bank0_wdata_i = sk_mem_bank0_wdata_i;
    assign abr_memory_export.sk_mem_bank0_re_i    = sk_mem_bank0_re_i;
    assign abr_memory_export.sk_mem_bank0_raddr_i = sk_mem_bank0_raddr_i;
    assign sk_mem_bank0_rdata_o                   = abr_memory_export.sk_mem_bank0_rdata_o;

    // -----------------------------------------------------------------------
    // sk_mem_bank1
    // -----------------------------------------------------------------------
    assign abr_memory_export.sk_mem_bank1_we_i    = sk_mem_bank1_we_i;
    assign abr_memory_export.sk_mem_bank1_waddr_i = sk_mem_bank1_waddr_i;
    assign abr_memory_export.sk_mem_bank1_wdata_i = sk_mem_bank1_wdata_i;
    assign abr_memory_export.sk_mem_bank1_re_i    = sk_mem_bank1_re_i;
    assign abr_memory_export.sk_mem_bank1_raddr_i = sk_mem_bank1_raddr_i;
    assign sk_mem_bank1_rdata_o                   = abr_memory_export.sk_mem_bank1_rdata_o;

    // -----------------------------------------------------------------------
    // sig_z_mem
    // -----------------------------------------------------------------------
    assign abr_memory_export.sig_z_mem_we_i      = sig_z_mem_we_i;
    assign abr_memory_export.sig_z_mem_waddr_i   = sig_z_mem_waddr_i;
    assign abr_memory_export.sig_z_mem_wdata_i   = sig_z_mem_wdata_i;
    assign abr_memory_export.sig_z_mem_wstrobe_i = sig_z_mem_wstrobe_i;
    assign abr_memory_export.sig_z_mem_re_i      = sig_z_mem_re_i;
    assign abr_memory_export.sig_z_mem_raddr_i   = sig_z_mem_raddr_i;
    assign sig_z_mem_rdata_o                     = abr_memory_export.sig_z_mem_rdata_o;

    // -----------------------------------------------------------------------
    // pk_mem
    // -----------------------------------------------------------------------
    assign abr_memory_export.pk_mem_we_i      = pk_mem_we_i;
    assign abr_memory_export.pk_mem_waddr_i   = pk_mem_waddr_i;
    assign abr_memory_export.pk_mem_wdata_i   = pk_mem_wdata_i;
    assign abr_memory_export.pk_mem_wstrobe_i = pk_mem_wstrobe_i;
    assign abr_memory_export.pk_mem_re_i      = pk_mem_re_i;
    assign abr_memory_export.pk_mem_raddr_i   = pk_mem_raddr_i;
    assign pk_mem_rdata_o                     = abr_memory_export.pk_mem_rdata_o;

endmodule
