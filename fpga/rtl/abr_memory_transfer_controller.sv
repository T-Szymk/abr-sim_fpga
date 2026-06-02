// abr_memory_transfer_controller.sv
// Module to control data flow between data buffer (A) and register interface (B)
// Protocol specific controls are placed outside of this module to keep it protocol-agnostic


module abr_memory_transfer_controller #(
    parameter int unsigned ADDR_WIDTH      = 32,
    parameter int unsigned DATA_WIDTH      = 64,            // B interface width
    localparam int unsigned A_DATA_WIDTH   = DATA_WIDTH / 2, // A interface: 32b
    localparam int unsigned SizeWidth      =  3,
    localparam int unsigned BLenWidth      = 16              // Byte length of bursts
) (
    input  logic                     clk_i,
    input  logic                     rst_ni,

    // Controls

    input   logic                    start_i,    // pulse to start a transfer sequence
    input   logic [ADDR_WIDTH-1:0]   b_addr_i,   // base address for B interface
    input   logic [BLenWidth-1:0]    b_len_i,    // number of bytes to transfer (must be multiple of 4)
    input   logic                    op_i,       // 1 = A to B, 0 = B to A

    // A interface (32-bit BRAM)
    output  logic                    a_req_o,
    output  logic                    a_write_o,
    output  logic [SizeWidth-1:0]    a_size_o,   // always SIZE_32B
    output  logic [ADDR_WIDTH-1:0]   a_addr_o,
    output  logic [A_DATA_WIDTH-1:0] a_wdata_o,
    input   logic [A_DATA_WIDTH-1:0] a_rdata_i,
    input   logic                    a_ready_i,  // NOTE: Assumed to always be ready

    // B interface (64-bit AHB, 32-bit sub-word accesses with byte-lane packing)
    output  logic                    b_req_o,
    output  logic                    b_write_o,
    output  logic [SizeWidth-1:0]    b_size_o,   // always SIZE_32B
    output  logic [ADDR_WIDTH-1:0]   b_addr_o,
    output  logic [DATA_WIDTH-1:0]   b_wdata_o,
    input   logic [DATA_WIDTH-1:0]   b_rdata_i,
    input   logic                    b_ready_i,  // NOTE: Assumed to always be ready

    // Status
    output  logic                    busy_o,     // transfer sequence in-progress
    output  logic                    error_o     // error occurred during transfer sequence
);

  timeunit 1ns / 1ps;

  // All transfers are 32-bit words; stride = 4 bytes
  localparam int unsigned WordShift = 2;
  // SIZE_32B encoding per abr_fpga_pkg::size_e (log2(4) = 2)
  localparam logic [SizeWidth-1:0] K_SIZE_32B = SizeWidth'(WordShift);

  // -------------------------------------------------------------------------
  // Latched transfer parameters
  // -------------------------------------------------------------------------
  logic [ADDR_WIDTH-1:0] b_base_r;
  logic [BLenWidth-1:0]  n_words_r;
  logic                  op_r;

  logic [BLenWidth-1:0]  n_words_next;
  assign n_words_next = b_len_i >> WordShift;

  // -------------------------------------------------------------------------
  // Transfer counters: reads / writes issued (reset on every new start)
  // -------------------------------------------------------------------------
  logic [BLenWidth-1:0]  rd_cnt;
  logic [BLenWidth-1:0]  wr_cnt;

  // -------------------------------------------------------------------------
  // FSM
  // -------------------------------------------------------------------------
  typedef enum logic { IDLE, BUSY } state_e;
  state_e state_q;

  // Per-cycle enables.
  // do_read  — there are still words to fetch from the source.
  // do_write — source data from the previous cycle is available; write to dest.
  //            rd_cnt > 0 is equivalent to "at least one read has been issued"
  //            given the 1-cycle read latency.
  logic do_read, do_write;
  assign do_read  = (rd_cnt < n_words_r);
  assign do_write = (rd_cnt > '0);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q   <= IDLE;
      b_base_r  <= '0;
      n_words_r <= '0;
      op_r      <= '0;
      rd_cnt    <= '0;
      wr_cnt    <= '0;
    end else begin
      unique case (state_q)

        IDLE: begin
          if (start_i && n_words_next != '0) begin
            b_base_r  <= b_addr_i;
            n_words_r <= n_words_next;
            op_r      <= op_i;
            rd_cnt    <= '0;
            wr_cnt    <= '0;
            state_q   <= BUSY;
          end
        end

        BUSY: begin
          if (do_read)  rd_cnt <= rd_cnt + 1'b1;
          if (do_write) wr_cnt <= wr_cnt + 1'b1;
          // Exit after the last write is issued
          if (do_write && (wr_cnt == n_words_r - 1))
            state_q <= IDLE;
        end

      endcase
    end
  end

  // -------------------------------------------------------------------------
  // Byte-lane helpers for 32-bit accesses on 64-bit B bus.
  //
  // For a 32-bit-aligned address, addr[2] selects the active 32-bit lane:
  //   addr[2] = 0  →  data on b_data[31: 0]
  //   addr[2] = 1  →  data on b_data[63:32]
  //
  // b_wr_addr is the B address for the current write phase (wr_cnt tracks the
  // same word index that was read in the previous cycle, so using wr_cnt here
  // naturally recovers the lane of the pending read data).
  // -------------------------------------------------------------------------
  logic [ADDR_WIDTH-1:0] b_wr_addr;
  assign b_wr_addr = b_base_r + (ADDR_WIDTH'(wr_cnt) << WordShift);

  // -------------------------------------------------------------------------
  // Output logic
  // -------------------------------------------------------------------------
  assign busy_o  = (state_q == BUSY);
  assign error_o = 1'b0;

  always_comb begin
    a_req_o   = 1'b0;
    a_write_o = 1'b0;
    a_size_o  = K_SIZE_32B;
    a_addr_o  = '0;
    a_wdata_o = '0;
    b_req_o   = 1'b0;
    b_write_o = 1'b0;
    b_size_o  = K_SIZE_32B;
    b_addr_o  = '0;
    b_wdata_o = '0;

    if (state_q == BUSY) begin
      if (op_r) begin
        // A → B: read 32b from A, pack onto the correct B byte lane
        if (do_read) begin
          a_req_o  = 1'b1;
          a_addr_o = ADDR_WIDTH'(rd_cnt) << WordShift;
        end
        if (do_write) begin
          b_req_o   = 1'b1;
          b_write_o = 1'b1;
          b_addr_o  = b_wr_addr;
          b_wdata_o = b_wr_addr[2] ? {a_rdata_i, {A_DATA_WIDTH{1'b0}}}
                                   : {{A_DATA_WIDTH{1'b0}}, a_rdata_i};
        end
      end else begin
        // B → A: read 32b from the correct B byte lane, write to A
        if (do_read) begin
          b_req_o  = 1'b1;
          b_addr_o = b_base_r + (ADDR_WIDTH'(rd_cnt) << WordShift);
        end
        if (do_write) begin
          a_req_o   = 1'b1;
          a_write_o = 1'b1;
          a_addr_o  = ADDR_WIDTH'(wr_cnt) << WordShift;
          a_wdata_o = b_wr_addr[2] ? b_rdata_i[DATA_WIDTH-1 : A_DATA_WIDTH]
                                   : b_rdata_i[A_DATA_WIDTH-1 : 0];
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // Assertions
  // -------------------------------------------------------------------------
  // synthesis translate_off
  a_start_when_idle: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    start_i |-> (state_q == IDLE)
  ) else $error("%m: start_i pulsed while busy");

  a_len_aligned: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    start_i |-> (b_len_i[WordShift-1:0] == '0)
  ) else $error("%m: b_len_i not aligned to 32-bit words");

  a_a_always_ready: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    a_req_o |-> a_ready_i
  ) else $error("%m: a_ready_i deasserted unexpectedly");

  a_b_always_ready: assert property (
    @(posedge clk_i) disable iff (!rst_ni)
    b_req_o |-> b_ready_i
  ) else $error("%m: b_ready_i deasserted unexpectedly");
  // synthesis translate_on

endmodule : abr_memory_transfer_controller
