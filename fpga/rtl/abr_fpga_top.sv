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
#(
    parameter op_e OPERATION   = OP_KEYGEN,
    parameter int  RESET_CYCLES = 16        // cycles abr_top rst_b is held low
)
(
    input  logic clk_i,
    input  logic rst_ni,      // active-low board/PLL reset

`ifdef RV_FPGA_SCA
    output wire NTT_trigger,
    output wire PWM_trigger,
    output wire PWA_trigger,
    output wire INTT_trigger,
`endif

    output logic done_o,      // pulses high for one cycle when operation completes
    output logic error_o,     // asserted and held on STATUS error

    // abr_top status pass-through
    output logic busy_o,
    output logic error_intr_o,
    output logic notif_intr_o
);

    timeunit 1ns/1ps;

    // -----------------------------------------------------------------------
    // Localparams — resolved from package constants at elaboration time
    // -----------------------------------------------------------------------

    // Select the descriptor table and control word for this operation
    localparam wr_desc_t DESC [MAX_DESC] =
        (OPERATION == OP_KEYGEN) ? KEYGEN_DESC  :
        (OPERATION == OP_SIGN)   ? SIGN_DESC    :
        (OPERATION == OP_VERIFY) ? VERIFY_DESC  :
                                   KGSIGN_DESC;

    localparam int unsigned NUM_DESC =
        (OPERATION == OP_KEYGEN) ? KEYGEN_NUM_DESC  :
        (OPERATION == OP_SIGN)   ? SIGN_NUM_DESC    :
        (OPERATION == OP_VERIFY) ? VERIFY_NUM_DESC  :
                                   KGSIGN_NUM_DESC;

    localparam logic [31:0] OP_CTRL =
        (OPERATION == OP_KEYGEN) ? KEYGEN_CTRL  :
        (OPERATION == OP_SIGN)   ? SIGN_CTRL    :
        (OPERATION == OP_VERIFY) ? VERIFY_CTRL  :
                                   KGSIGN_CTRL;

    // Counter widths
    localparam int unsigned RESET_CNT_W = $clog2(RESET_CYCLES + 1);
    localparam int unsigned DESC_IDX_W  = $clog2(MAX_DESC);
    // 11 bits covers the maximum word count (PRIVKEY_WORDS = 1224)
    localparam int unsigned WORD_IDX_W  = 11;

    // -----------------------------------------------------------------------
    // AHB bus parameters
    // -----------------------------------------------------------------------
    localparam int unsigned AHB_ADDR_W = 32;
    localparam int unsigned AHB_DATA_W = 64;  // abr_top default

    // -----------------------------------------------------------------------
    // Internal AHB wires (ahb_mgr → abr_top)
    // -----------------------------------------------------------------------
    logic [AHB_ADDR_W-1:0] haddr;
    logic [AHB_DATA_W-1:0] hwdata;
    logic                  hsel;
    logic                  hwrite;
    logic                  hready;
    logic [1:0]            htrans;
    logic [2:0]            hsize;
    logic                  hresp;
    logic                  hreadyout;
    logic [AHB_DATA_W-1:0] hrdata;

    // -----------------------------------------------------------------------
    // ahb_mgr request/response interface to the FSM
    // -----------------------------------------------------------------------
    logic                  mgr_req;
    logic                  mgr_write;
    logic [2:0]            mgr_size;
    logic [AHB_ADDR_W-1:0] mgr_addr;
    logic [AHB_DATA_W-1:0] mgr_wdata;
    logic                  mgr_ready;
    logic                  mgr_done;
    logic [AHB_DATA_W-1:0] mgr_rdata;
    logic                  mgr_error;

    // -----------------------------------------------------------------------
    // abr_top reset (driven by FSM)
    // -----------------------------------------------------------------------
    logic abr_rst_b;

    // -----------------------------------------------------------------------
    // Memory interface
    // -----------------------------------------------------------------------
    abr_mem_if abr_memory_export();

    // -----------------------------------------------------------------------
    // abr_mem_fpga instantiation
    // -----------------------------------------------------------------------
    abr_mem_fpga mem_inst (
        .clk_i            (clk_i),
        .abr_memory_export (abr_memory_export)
    );

    // -----------------------------------------------------------------------
    // abr_top instantiation
    // -----------------------------------------------------------------------
    abr_top #(
        .AHB_ADDR_WIDTH    (AHB_ADDR_W),
        .AHB_DATA_WIDTH    (AHB_DATA_W),
        .CLIENT_DATA_WIDTH (32)
    ) dut (
        .clk                             ( clk_i             ),
        .rst_b                           ( abr_rst_b         ),
`ifdef RV_FPGA_SCA
        .NTT_trigger                     ( NTT_trigger       ),
        .PWM_trigger                     ( PWM_trigger       ),
        .PWA_trigger                     ( PWA_trigger       ),
        .INTT_trigger                    ( INTT_trigger      ),
`endif
        .haddr_i                         ( haddr             ),
        .hwdata_i                        ( hwdata            ),
        .hsel_i                          ( hsel              ),
        .hwrite_i                        ( hwrite            ),
        .hready_i                        ( hready            ),
        .htrans_i                        ( htrans            ),
        .hsize_i                         ( hsize             ),
        .hresp_o                         ( hresp             ),
        .hreadyout_o                     ( hreadyout         ),
        .hrdata_o                        ( hrdata            ),
        .abr_memory_export               ( abr_memory_export ),
        .debugUnlock_or_scan_mode_switch ('0),
        .busy_o                          ( busy_o            ),
        .error_intr                      ( error_intr_o      ),
        .notif_intr                      ( notif_intr_o      )
    );

    // -----------------------------------------------------------------------
    // abr_ahb_mgr instantiation (64-bit data width)
    // -----------------------------------------------------------------------
    abr_ahb_mgr #(
        .AHB_ADDR_WIDTH (AHB_ADDR_W),
        .AHB_DATA_WIDTH (AHB_DATA_W)
    ) ahb_mgr (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .req_i        (mgr_req),
        .write_i      (mgr_write),
        .size_i       (mgr_size),
        .addr_i       (mgr_addr),
        .wdata_i      (mgr_wdata),
        .ready_o      (mgr_ready),
        .done_o       (mgr_done),
        .rdata_o      (mgr_rdata),
        .error_o      (mgr_error),
        .haddr_o      (haddr),
        .hwdata_o     (hwdata),
        .hsel_o       (hsel),
        .hwrite_o     (hwrite),
        .hready_o     (hready),
        .htrans_o     (htrans),
        .hsize_o      (hsize),
        .hresp_i      (hresp),
        .hreadyout_i  (hreadyout),
        .hrdata_i     (hrdata)
    );

    // -----------------------------------------------------------------------
    // FSM
    // -----------------------------------------------------------------------
    typedef enum logic [3:0] {
        ST_RESET,           // drive abr_rst_b low
        ST_POLL_RDY_ISSUE,  // issue STATUS read to check READY
        ST_POLL_RDY_WAIT,   // wait for STATUS read to complete
        ST_WRITE_ISSUE,     // issue one input-register write
        ST_WRITE_WAIT,      // wait for write to complete, advance counters
        ST_CTRL_ISSUE,      // issue CTRL write to start operation
        ST_CTRL_WAIT,       // wait for CTRL write to complete
        ST_POLL_DONE_ISSUE, // issue STATUS read to check completion
        ST_POLL_DONE_WAIT,  // wait for STATUS read to complete
        ST_DONE,
        ST_ERROR
    } state_e;

    state_e                      state_q, state_d;
    logic [RESET_CNT_W-1:0]      reset_cnt_q;
    logic [DESC_IDX_W-1:0]       desc_idx_q;
    logic [WORD_IDX_W-1:0]       word_idx_q;
    logic [31:0]                 status_lat_q; // latched STATUS word

    // -----------------------------------------------------------------------
    // Data-lookup: returns the 32-bit payload for (desc_idx, word_idx).
    // OPERATION is a compile-time constant so the case reduces to one branch.
    // -----------------------------------------------------------------------
    function automatic logic [31:0] get_input_data(
        input int unsigned di,
        input int unsigned wi
    );
        unique case (OPERATION)
            OP_KEYGEN: return keygen_data(di, wi);
            OP_SIGN:   return sign_data(di, wi);
            OP_VERIFY: return verify_data(di, wi);
            OP_KGSIGN: return kgsign_data(di, wi);
            default:   return '0;
        endcase
    endfunction

    // -----------------------------------------------------------------------
    // AHB 64-bit lane helpers
    //   addr[2]=0 → lower 32-bit lane  [31:0]
    //   addr[2]=1 → upper 32-bit lane  [63:32]
    // -----------------------------------------------------------------------
    function automatic logic [AHB_DATA_W-1:0] pack_wdata(
        input logic [31:0] addr,
        input logic [31:0] data
    );
        return addr[2] ? {data, 32'h0} : {{32'h0}, data};
    endfunction

    function automatic logic [31:0] unpack_rdata(
        input logic [31:0]         addr,
        input logic [AHB_DATA_W-1:0] rdata
    );
        return addr[2] ? rdata[63:32] : rdata[31:0];
    endfunction

    // -----------------------------------------------------------------------
    // Current-write address for the active (desc_idx, word_idx) position
    // -----------------------------------------------------------------------
    logic [31:0] cur_wr_addr;
    assign cur_wr_addr = DESC[desc_idx_q].base_addr + {19'h0, word_idx_q, 2'b00};

    // -----------------------------------------------------------------------
    // FSM sequential
    // -----------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q     <= ST_RESET;
            reset_cnt_q <= RESET_CNT_W'(RESET_CYCLES);
            desc_idx_q  <= '0;
            word_idx_q  <= '0;
            status_lat_q <= '0;
        end else begin
            state_q <= state_d;

            unique case (state_q)

                ST_RESET: begin
                    if (reset_cnt_q != '0)
                        reset_cnt_q <= reset_cnt_q - 1'b1;
                end

                ST_POLL_RDY_WAIT: begin
                    if (mgr_done)
                        status_lat_q <= unpack_rdata(ADDR_MLDSA_STATUS, mgr_rdata);
                end

                ST_WRITE_WAIT: begin
                    if (mgr_done) begin
                        if (word_idx_q == WORD_IDX_W'(DESC[desc_idx_q].num_words - 1)) begin
                            word_idx_q <= '0;
                            desc_idx_q <= desc_idx_q + 1'b1;
                        end else begin
                            word_idx_q <= word_idx_q + 1'b1;
                        end
                    end
                end

                ST_POLL_DONE_WAIT: begin
                    if (mgr_done)
                        status_lat_q <= unpack_rdata(ADDR_MLDSA_STATUS, mgr_rdata);
                end

                default: ;

            endcase
        end
    end

    // -----------------------------------------------------------------------
    // FSM combinational — next-state and output logic
    // -----------------------------------------------------------------------
    always_comb begin
        state_d    = state_q;
        abr_rst_b  = 1'b1;
        mgr_req    = 1'b0;
        mgr_write  = 1'b0;
        mgr_size   = 3'b010;     // HSIZE word (32-bit)
        mgr_addr   = '0;
        mgr_wdata  = '0;
        done_o     = 1'b0;
        error_o    = 1'b0;

        unique case (state_q)

            // -----------------------------------------------------------------
            ST_RESET: begin
                abr_rst_b = 1'b0;
                if (reset_cnt_q == '0)
                    state_d = ST_POLL_RDY_ISSUE;
            end

            // -----------------------------------------------------------------
            // Poll STATUS — wait for READY
            // -----------------------------------------------------------------
            ST_POLL_RDY_ISSUE: begin
                if (mgr_ready) begin
                    mgr_req   = 1'b1;
                    mgr_write = 1'b0;
                    mgr_addr  = ADDR_MLDSA_STATUS;
                    state_d   = ST_POLL_RDY_WAIT;
                end
            end

            ST_POLL_RDY_WAIT: begin
                if (mgr_done) begin
                    if (mgr_error)
                        state_d = ST_ERROR;
                    else if (status_lat_q & STATUS_READY)
                        state_d = ST_WRITE_ISSUE;
                    else
                        state_d = ST_POLL_RDY_ISSUE;  // not yet ready, re-poll
                end
            end

            // -----------------------------------------------------------------
            // Write all input descriptors word-by-word
            // -----------------------------------------------------------------
            ST_WRITE_ISSUE: begin
                // All descriptors written — proceed to CTRL
                if (desc_idx_q == DESC_IDX_W'(NUM_DESC)) begin
                    state_d = ST_CTRL_ISSUE;
                end else if (mgr_ready) begin
                    mgr_req   = 1'b1;
                    mgr_write = 1'b1;
                    mgr_addr  = cur_wr_addr;
                    mgr_wdata = pack_wdata(
                        cur_wr_addr,
                        get_input_data(int'(desc_idx_q), int'(word_idx_q))
                    );
                    state_d = ST_WRITE_WAIT;
                end
            end

            ST_WRITE_WAIT: begin
                if (mgr_done) begin
                    if (mgr_error)
                        state_d = ST_ERROR;
                    else
                        state_d = ST_WRITE_ISSUE;
                end
            end

            // -----------------------------------------------------------------
            // Write CTRL to start the operation
            // -----------------------------------------------------------------
            ST_CTRL_ISSUE: begin
                if (mgr_ready) begin
                    mgr_req   = 1'b1;
                    mgr_write = 1'b1;
                    mgr_addr  = ADDR_MLDSA_CTRL;
                    mgr_wdata = pack_wdata(ADDR_MLDSA_CTRL, OP_CTRL);
                    state_d   = ST_CTRL_WAIT;
                end
            end

            ST_CTRL_WAIT: begin
                if (mgr_done) begin
                    if (mgr_error)
                        state_d = ST_ERROR;
                    else
                        state_d = ST_POLL_DONE_ISSUE;
                end
            end

            // -----------------------------------------------------------------
            // Poll STATUS — wait for READY+VALID (operation complete)
            // -----------------------------------------------------------------
            ST_POLL_DONE_ISSUE: begin
                if (mgr_ready) begin
                    mgr_req   = 1'b1;
                    mgr_write = 1'b0;
                    mgr_addr  = ADDR_MLDSA_STATUS;
                    state_d   = ST_POLL_DONE_WAIT;
                end
            end

            ST_POLL_DONE_WAIT: begin
                if (mgr_done) begin
                    if (mgr_error || (status_lat_q & STATUS_ERROR))
                        state_d = ST_ERROR;
                    else if ((status_lat_q & (STATUS_READY | STATUS_VALID)) ==
                             (STATUS_READY | STATUS_VALID))
                        state_d = ST_DONE;
                    else
                        state_d = ST_POLL_DONE_ISSUE;
                end
            end

            // -----------------------------------------------------------------
            ST_DONE: begin
                done_o = 1'b1;
                // Hold in DONE; external logic can observe done_o for one cycle
                // or permanently via a registered flag.
            end

            ST_ERROR: begin
                error_o = 1'b1;
            end

            default: ;

        endcase
    end

endmodule
