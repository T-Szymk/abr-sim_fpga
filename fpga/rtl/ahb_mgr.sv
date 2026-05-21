// ahb_mgr.sv — AHB-Lite manager (master)
// Drives a single subordinate with a simple req/ready handshake.
// Back-to-back transfers are supported: assert req_i while ready_o is high.

module ahb_mgr #(
    parameter int unsigned AHB_ADDR_WIDTH = 32,
    parameter int unsigned AHB_DATA_WIDTH = 32
) (
    input  logic                          clk_i,
    input  logic                          rst_ni,

    // Request interface
    input  logic                          req_i,    // initiate a transfer
    input  logic                          write_i,  // 1 = write, 0 = read
    input  logic [2:0]                    size_i,   // HSIZE: 000=8b 001=16b 010=32b 011=64b
    input  logic [AHB_ADDR_WIDTH-1:0]     addr_i,
    input  logic [AHB_DATA_WIDTH-1:0]     wdata_i,
    output logic                          ready_o,  // manager ready for new request

    // Response interface (valid for one cycle when transfer completes)
    output logic                          done_o,   // transfer accepted by subordinate
    output logic [AHB_DATA_WIDTH-1:0]     rdata_o,  // read data (valid when done_o & !write)
    output logic                          error_o,  // subordinate returned HRESP ERROR

    // AHB-Lite manager port
    output logic [AHB_ADDR_WIDTH-1:0]     haddr_o,
    output logic [AHB_DATA_WIDTH-1:0]     hwdata_o,
    output logic                          hsel_o,
    output logic                          hwrite_o,
    output logic                          hready_o,  // fed back from hreadyout_i
    output logic [1:0]                    htrans_o,
    output logic [2:0]                    hsize_o,
    input  logic                          hresp_i,
    input  logic                          hreadyout_i,
    input  logic [AHB_DATA_WIDTH-1:0]     hrdata_i
);

    timeunit 1ns / 1ps;

    localparam logic [1:0] HTRANS_IDLE   = 2'b00;
    localparam logic [1:0] HTRANS_NONSEQ = 2'b10;

    typedef enum logic { ST_IDLE, ST_DATA } state_t;
    state_t state_q, state_d;

    // Registered data-phase info (captured when address phase is launched)
    logic                        dp_write_q;
    logic [AHB_DATA_WIDTH-1:0]   dp_wdata_q;

    // HREADY is a pass-through to the subordinate for single-manager topologies
    assign hready_o = hreadyout_i;

    always_comb begin
        state_d  = state_q;
        ready_o  = 1'b0;
        done_o   = 1'b0;
        rdata_o  = hrdata_i;
        error_o  = 1'b0;

        hsel_o   = 1'b0;
        htrans_o = HTRANS_IDLE;
        haddr_o  = addr_i;
        hwrite_o = write_i;
        hsize_o  = size_i;
        hwdata_o = dp_wdata_q;

        unique case (state_q)

            ST_IDLE: begin
                ready_o = 1'b1;
                if (req_i) begin
                    hsel_o   = 1'b1;
                    htrans_o = HTRANS_NONSEQ;
                    state_d  = ST_DATA;
                end
            end

            ST_DATA: begin
                // Hold data-phase info for the subordinate
                hsel_o   = 1'b1;
                hwrite_o = dp_write_q;
                hwdata_o = dp_wdata_q;

                if (hreadyout_i) begin
                    done_o  = 1'b1;
                    error_o = hresp_i;

                    if (req_i) begin
                        // Back-to-back: launch next address phase this cycle
                        htrans_o = HTRANS_NONSEQ;
                        haddr_o  = addr_i;
                        hwrite_o = write_i;
                        hsize_o  = size_i;
                        ready_o  = 1'b1;
                        state_d  = ST_DATA;
                    end else begin
                        hsel_o   = 1'b0;
                        htrans_o = HTRANS_IDLE;
                        ready_o  = 1'b1;
                        state_d  = ST_IDLE;
                    end
                end
                // else: wait state — hold signals, no new address phase
            end

        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q    <= ST_IDLE;
            dp_write_q <= '0;
            dp_wdata_q <= '0;
        end else begin
            state_q <= state_d;
            // Capture address-phase info into data-phase regs when a transfer is accepted
            if (ready_o && req_i) begin
                dp_write_q <= write_i;
                dp_wdata_q <= wdata_i;
            end
        end
    end

endmodule
