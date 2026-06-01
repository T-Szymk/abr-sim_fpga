// Module to control data flow between data buffer (A) and register interface (B)
// Protocol specific controls are placed outside of this module to keep it protocol-agnostic


module abr_data_flow_controller #(
    parameter int unsigned ADDR_WIDTH      = 32,
    parameter int unsigned DATA_WIDTH      = 64,
    localparam int unsigned WordWidthBytes = (DATA_WIDTH / 8),
    localparam int unsigned SizeWidth      =  3,
    localparam int unsigned BLenWidth      = 16 // Byte length of bursts
) (
    input  logic                   clk_i,
    input  logic                   rst_ni,

    // Controls

    input   logic                  start_i,    // pulse to start a transfer sequence
    input   logic [ADDR_WIDTH-1:0] b_addr_i,   // base address for B interface
    input   logic [BLenWidth-1:0]  b_len_i,    // number of bytes to transfer (must be multiple of DATA_WIDTH/8)
    input   logic                  op_i,       // 0 = A to B, 1 = B to A

    // A interface
    output  logic                  a_req_o,    // initiate a transfer
    output  logic                  a_write_o,  // 1 = write, 0 = read
    output  logic [SizeWidth-1:0]  a_size_o,   // SIZE: 000=8b 001=16b 010=32b 011=64b
    output  logic [ADDR_WIDTH-1:0] a_addr_o,
    output  logic [DATA_WIDTH-1:0] a_wdata_o,
    input   logic [DATA_WIDTH-1:0] a_rdata_i,
    input   logic                  a_ready_i,  // NOTE: Assumed to always  be ready

    // B interface
    output  logic                  b_req_o,    // initiate a transfer
    output  logic                  b_write_o,  // 1 = write, 0 = read
    output  logic [SizeWidth-1:0]  b_size_o,   // SIZE: 000=8b 001=16b 010=32b 011=64b
    output  logic [ADDR_WIDTH-1:0] b_addr_o,
    output  logic [DATA_WIDTH-1:0] b_wdata_o,
    input   logic [DATA_WIDTH-1:0] b_rdata_i,
    input   logic                  b_ready_i,  // NOTE: Assumed to always  be ready

    // Status
    output  logic                  busy_o,     // transfer sequence in-progress
    output  logic                  error_o     // error occurred during transfer sequence
);

/* Data Types and Parameters */

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_TRANSFER_INIT,
    ST_TRANSFER_A_TO_B,
    ST_TRANSFER_B_TO_A
  } state_t;

  state_t state_q, state_d;


/* Signal Declarations */

logic op_d, op_q; // Register for operation type (A to B or B to A)

logic [BLenWidth-1:0]  byte_count_d, byte_count_q; // Counts bytes transferred in current burst

logic [ADDR_WIDTH-1:0] a_addr_d, a_addr_q;
logic [ADDR_WIDTH-1:0] b_addr_d, b_addr_q;


/* Assignments */

assign a_addr_o = a_addr_q;
assign b_addr_o = b_addr_q;


/* FSM to control logic transfers between A and B interfaces */

  always_comb begin

    // default assignments
    state_d = state_q;

    a_req_o      = 1'b0;
    a_write_o    = 1'b0;
    a_size_o     = 3'b11; // TODO: Implement dynamic sizing
    a_addr_d     = a_addr_q;
    a_wdata_o    = '0;

    b_req_o      = 1'b0;
    b_write_o    = 1'b0;
    b_size_o     = 3'b11; // TODO: Implement dynamic sizing
    b_addr_d     = b_addr_q;
    b_wdata_o    = '0;

    byte_count_d = byte_count_q;

    op_d = op_q; // Hold operation type constant during transfer sequence

    busy_o  = 1'b0;
    error_o = 1'b0; // TODO: Implement error handling and assert error_o when appropriate

    case (state_q)

      // wait for start signal
      ST_IDLE: begin

        if (start_i) begin          

          state_d = ST_TRANSFER_INIT;

          op_d         = op_i; // Capture operation type at start of transfer sequence
          byte_count_d = '0; // Reset byte count at start of transfer

          if (op_i == 1'b0) begin
            a_addr_d  = '0; // Reset starting address for A
          end else begin
            b_addr_d  = b_addr_i; // Starting address for B comes from input
          end
          
        end

      end

      // This state is used for any setup needed before starting transfers
      ST_TRANSFER_INIT: begin

        busy_o = 1'b1;

        if (op_q == 1'b0) begin

            state_d   = ST_TRANSFER_A_TO_B;
            // Initiate transfer from A to B
            a_req_o   = 1'b1;
            a_write_o = 1'b0; // Read from A
            a_addr_d  = a_addr_q + WordWidthBytes; // advance A address as read lags by a cycle

          end else begin

            state_d   = ST_TRANSFER_B_TO_A;
            // Initiate transfer from B to A
            b_req_o   = 1'b1;
            b_write_o = 1'b0; // Read from B
            b_addr_d  = b_addr_q + WordWidthBytes; // advance B address as read lags by a cycle

          end
      end

      // transfer data from A to B and check for completion conditions
      ST_TRANSFER_A_TO_B: begin

        busy_o = 1'b1;

        // Capture data from A and initiate transfer to B
        b_req_o   = 1'b1;
        b_write_o = 1'b1;      // Write to B
        b_wdata_o = a_rdata_i; // Data read from A

        if (byte_count_q + WordWidthBytes >= b_len_i) begin
            
          state_d      = ST_IDLE; // Last beat, return to idle
          a_addr_d     = '0;      // Reset address for next transfer

        end else begin
  
          a_req_o      = 1'b1;   // prepare next transfer from A
          a_write_o    = 1'b0;   // Read from A
          
          a_addr_d     = a_addr_q + WordWidthBytes; // advance A address as read lags by a cycle
          b_addr_d     = b_addr_q + WordWidthBytes;     // Increment B address for next beat
          byte_count_d = byte_count_q + WordWidthBytes; // Increment byte count          

        end        

        state_d = ST_TRANSFER_B_TO_A; // Move to next state

      end

      // transfer data from B to A and check for completion conditions
      ST_TRANSFER_B_TO_A: begin

        busy_o = 1'b1;

        a_req_o   = 1'b1;
        a_write_o = 1'b1;      // Write to A
        a_wdata_o = b_rdata_i; // Data read from B

        if (byte_count_q + WordWidthBytes >= b_len_i) begin
            
          state_d      = ST_IDLE; // Last beat, return to idle
          a_addr_d     = '0;      // Reset address for next transfer

        end else begin          
            
          b_req_o      = 1'b1; // prepare next transfer from B
          b_write_o    = 1'b0; // Read from B

          a_addr_d     = a_addr_q + WordWidthBytes;     // Increment A address for next beat
          b_addr_d     = b_addr_q + WordWidthBytes; // advance B address as read lags by a cycle
          byte_count_d = byte_count_q + WordWidthBytes; // Increment byte count          
 
        end
      end

      default: begin
        state_d = ST_IDLE;
      end

    endcase
  end


/* Sequential Logic */

  always_ff @(posedge clk_i or negedge rst_ni) begin

    if (!rst_ni) begin
      state_q      <= ST_IDLE;
      a_addr_q     <= '0;
      b_addr_q     <= '0;
      byte_count_q <= '0;
      op_q         <= '0;
    end else begin
      state_q      <= state_d;
      a_addr_q     <= a_addr_d;
      b_addr_q     <= b_addr_d;
      byte_count_q <= byte_count_d;
      op_q         <= op_d;
    end
  
  end

// ToDo: Asserts to check byte length is multiple of DATA_WIDTH/8, and that burst doesn't exceed max length


endmodule : abr_data_flow_controller
