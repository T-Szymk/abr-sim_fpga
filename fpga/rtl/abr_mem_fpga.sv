// abr_mem_fpga.sv — AMD FPGA BRAM replacement for abr_mem_top.
//
// Drop-in substitution: same port list and abr_mem_if.resp modport as
// abr_mem_top.sv.  Every bank is implemented as a simple synchronous 1R1W
// RAM with (* ram_style = "block" *) so Vivado infers RAMB18/RAMB36 tiles.
//
// Non-byte-enable banks  →  separate read/write always_ff blocks (SDP BRAM).
// Byte-enable banks      →  byte-lane write enables, single read port.
//
// Note: w1_mem (4-bit × 512) is narrow but Vivado still maps it to a BRAM
// at 4-bit width; the resource costs one BRAM18 tile.

`include "abr_config_defines.svh"

module abr_mem_fpga
    import abr_params_pkg::*;
    import abr_ctrl_pkg::*;
(
    input  logic clk_i,
    abr_mem_if.resp abr_memory_export
);

    // -----------------------------------------------------------------------
    // w1_mem  — depth ABR_MEM_W1_DEPTH × ABR_MEM_W1_DATA_W bits
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [ABR_MEM_W1_DATA_W-1:0]
        w1_arr [0:ABR_MEM_W1_DEPTH-1];

    always_ff @(posedge clk_i)
        if (abr_memory_export.w1_mem_we_i)
            w1_arr[abr_memory_export.w1_mem_waddr_i] <=
                abr_memory_export.w1_mem_wdata_i;

    always_ff @(posedge clk_i)
        if (abr_memory_export.w1_mem_re_i)
            abr_memory_export.w1_mem_rdata_o <=
                w1_arr[abr_memory_export.w1_mem_raddr_i];

    // -----------------------------------------------------------------------
    // mem_inst0_bank0  — depth ABR_MEM_INST0_DEPTH × ABR_MEM_DATA_WIDTH bits
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [ABR_MEM_DATA_WIDTH-1:0]
        inst0b0_arr [0:ABR_MEM_INST0_DEPTH-1];

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst0_bank0_we_i)
            inst0b0_arr[abr_memory_export.mem_inst0_bank0_waddr_i] <=
                abr_memory_export.mem_inst0_bank0_wdata_i;

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst0_bank0_re_i)
            abr_memory_export.mem_inst0_bank0_rdata_o <=
                inst0b0_arr[abr_memory_export.mem_inst0_bank0_raddr_i];

    // -----------------------------------------------------------------------
    // mem_inst0_bank1
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [ABR_MEM_DATA_WIDTH-1:0]
        inst0b1_arr [0:ABR_MEM_INST0_DEPTH-1];

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst0_bank1_we_i)
            inst0b1_arr[abr_memory_export.mem_inst0_bank1_waddr_i] <=
                abr_memory_export.mem_inst0_bank1_wdata_i;

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst0_bank1_re_i)
            abr_memory_export.mem_inst0_bank1_rdata_o <=
                inst0b1_arr[abr_memory_export.mem_inst0_bank1_raddr_i];

    // -----------------------------------------------------------------------
    // mem_inst1  — depth ABR_MEM_INST1_DEPTH × ABR_MEM_DATA_WIDTH bits
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [ABR_MEM_DATA_WIDTH-1:0]
        inst1_arr [0:ABR_MEM_INST1_DEPTH-1];

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst1_we_i)
            inst1_arr[abr_memory_export.mem_inst1_waddr_i] <=
                abr_memory_export.mem_inst1_wdata_i;

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst1_re_i)
            abr_memory_export.mem_inst1_rdata_o <=
                inst1_arr[abr_memory_export.mem_inst1_raddr_i];

    // -----------------------------------------------------------------------
    // mem_inst2  — depth ABR_MEM_INST2_DEPTH × ABR_MEM_DATA_WIDTH bits
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [ABR_MEM_DATA_WIDTH-1:0]
        inst2_arr [0:ABR_MEM_INST2_DEPTH-1];

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst2_we_i)
            inst2_arr[abr_memory_export.mem_inst2_waddr_i] <=
                abr_memory_export.mem_inst2_wdata_i;

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst2_re_i)
            abr_memory_export.mem_inst2_rdata_o <=
                inst2_arr[abr_memory_export.mem_inst2_raddr_i];

    // -----------------------------------------------------------------------
    // mem_inst3  — depth ABR_MEM_INST3_DEPTH × ABR_MEM_MASKED_DATA_WIDTH bits
    // (masked data path — wide but shallow; maps to cascaded BRAMs)
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [ABR_MEM_MASKED_DATA_WIDTH-1:0]
        inst3_arr [0:ABR_MEM_INST3_DEPTH-1];

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst3_we_i)
            inst3_arr[abr_memory_export.mem_inst3_waddr_i] <=
                abr_memory_export.mem_inst3_wdata_i;

    always_ff @(posedge clk_i)
        if (abr_memory_export.mem_inst3_re_i)
            abr_memory_export.mem_inst3_rdata_o <=
                inst3_arr[abr_memory_export.mem_inst3_raddr_i];

    // -----------------------------------------------------------------------
    // sk_mem_bank0  — depth SK_MEM_BANK_DEPTH × SK_MEM_BANK_DATA_W bits
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [SK_MEM_BANK_DATA_W-1:0]
        skb0_arr [0:SK_MEM_BANK_DEPTH-1];

    always_ff @(posedge clk_i)
        if (abr_memory_export.sk_mem_bank0_we_i)
            skb0_arr[abr_memory_export.sk_mem_bank0_waddr_i] <=
                abr_memory_export.sk_mem_bank0_wdata_i;

    always_ff @(posedge clk_i)
        if (abr_memory_export.sk_mem_bank0_re_i)
            abr_memory_export.sk_mem_bank0_rdata_o <=
                skb0_arr[abr_memory_export.sk_mem_bank0_raddr_i];

    // -----------------------------------------------------------------------
    // sk_mem_bank1
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [SK_MEM_BANK_DATA_W-1:0]
        skb1_arr [0:SK_MEM_BANK_DEPTH-1];

    always_ff @(posedge clk_i)
        if (abr_memory_export.sk_mem_bank1_we_i)
            skb1_arr[abr_memory_export.sk_mem_bank1_waddr_i] <=
                abr_memory_export.sk_mem_bank1_wdata_i;

    always_ff @(posedge clk_i)
        if (abr_memory_export.sk_mem_bank1_re_i)
            abr_memory_export.sk_mem_bank1_rdata_o <=
                skb1_arr[abr_memory_export.sk_mem_bank1_raddr_i];

    // -----------------------------------------------------------------------
    // sig_z_mem  — byte-enable, depth SIG_Z_MEM_DEPTH × SIG_Z_MEM_DATA_W bits
    // Strobe width: SIG_Z_MEM_WSTROBE_W = SIG_Z_MEM_DATA_W/8 (one bit per byte)
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [SIG_Z_MEM_DATA_W-1:0]
        sigz_arr [0:SIG_Z_MEM_DEPTH-1];

    always_ff @(posedge clk_i) begin
        if (abr_memory_export.sig_z_mem_we_i) begin
            for (int b = 0; b < SIG_Z_MEM_WSTROBE_W; b++) begin
                if (abr_memory_export.sig_z_mem_wstrobe_i[b])
                    sigz_arr[abr_memory_export.sig_z_mem_waddr_i][8*b +: 8] <=
                        abr_memory_export.sig_z_mem_wdata_i[8*b +: 8];
            end
        end
    end

    always_ff @(posedge clk_i)
        if (abr_memory_export.sig_z_mem_re_i)
            abr_memory_export.sig_z_mem_rdata_o <=
                sigz_arr[abr_memory_export.sig_z_mem_raddr_i];

    // -----------------------------------------------------------------------
    // pk_mem  — byte-enable, depth PK_MEM_DEPTH × PK_MEM_DATA_W bits
    // Strobe width: PK_MEM_WSTROBE_W = PK_MEM_DATA_W/8 (one bit per byte)
    // -----------------------------------------------------------------------
    (* ram_style = "block" *)
    logic [PK_MEM_DATA_W-1:0]
        pk_arr [0:PK_MEM_DEPTH-1];

    always_ff @(posedge clk_i) begin
        if (abr_memory_export.pk_mem_we_i) begin
            for (int b = 0; b < PK_MEM_WSTROBE_W; b++) begin
                if (abr_memory_export.pk_mem_wstrobe_i[b])
                    pk_arr[abr_memory_export.pk_mem_waddr_i][8*b +: 8] <=
                        abr_memory_export.pk_mem_wdata_i[8*b +: 8];
            end
        end
    end

    always_ff @(posedge clk_i)
        if (abr_memory_export.pk_mem_re_i)
            abr_memory_export.pk_mem_rdata_o <=
                pk_arr[abr_memory_export.pk_mem_raddr_i];

endmodule
