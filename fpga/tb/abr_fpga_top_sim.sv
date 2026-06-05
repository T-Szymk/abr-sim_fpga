// abr_fpga_top_sim.sv — Simulation stub for abr_fpga_top.
//
// Matches the port list of abr_fpga_top exactly but contains no RTL logic.
// AHB-Lite behaviour:
//   - Zero wait states: hreadyout_o is permanently asserted.
//   - OKAY response: hresp_o is permanently 0.
//   - Read data: returns the registered request address zero-extended to
//     AHB_DATA_WIDTH bits, so callers can check that the right address was
//     driven without needing real register contents.
//   - Each read response prints the accessed address to stdout.
//   - Writes are silently accepted and discarded.
// All other outputs (triggers, interrupts, busy) are tied to 0.
//
// AHB-Lite pipeline recap:
//   Cycle N   : address phase — hsel, htrans, haddr, hwrite sampled on
//               posedge when hready_i is high.
//   Cycle N+1 : data phase   — hrdata_o valid, hreadyout_o = 1.


module abr_fpga_top_sim
  import abr_fpga_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,

`ifdef RV_FPGA_SCA
  output wire NTT_trigger,
  output wire PWM_trigger,
  output wire PWA_trigger,
  output wire INTT_trigger,
`endif

  // AHB-Lite subordinate — input
  input  wire  [AHB_ADDR_WIDTH-1:0] haddr_i,
  input  wire  [AHB_DATA_WIDTH-1:0] hwdata_i,
  input  wire                       hsel_i,
  input  wire                       hwrite_i,
  input  wire                       hready_i,
  input  wire  [               1:0] htrans_i,
  input  wire  [               2:0] hsize_i,
  // AHB-Lite subordinate — output
  output wire                       hresp_o,
  output wire                       hreadyout_o,
  output wire  [AHB_DATA_WIDTH-1:0] hrdata_o,
  // Status
  output logic                      busy_o,
  output logic                      error_intr_o,
  output logic                      notif_intr_o
);

  timeunit 1ns/1ps;

  // -------------------------------------------------------------------------
  // AHB-Lite address-phase capture
  // -------------------------------------------------------------------------
  // Sample the address and read/write intent on every active address phase.
  // An address phase is active when hsel_i is asserted, htrans_i indicates a
  // NONSEQ or SEQ transfer (htrans_i[1] = 1), and the previous cycle's
  // hreadyout_o was high (i.e. hready_i from the master's perspective).
  // Since hreadyout_o is always 1 here the condition reduces to hready_i.

  logic [AHB_ADDR_WIDTH-1:0] haddr_q;
  logic                      pending_read_q; // data phase carries a read

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      haddr_q       <= '0;
      pending_read_q <= 1'b0;
    end else if (hready_i) begin
      haddr_q        <= haddr_i;
      pending_read_q <= hsel_i && htrans_i[1] && !hwrite_i;
    end
  end

  // -------------------------------------------------------------------------
  // AHB-Lite response — always OKAY, zero wait states
  // -------------------------------------------------------------------------
  assign hresp_o      = 1'b0;
  assign hreadyout_o  = 1'b1;

  // Return the registered request address, zero-extended to 64 bits.
  assign hrdata_o = pending_read_q
                    ? AHB_DATA_WIDTH'({32'b0, haddr_q})
                    : '0;

  // -------------------------------------------------------------------------
  // Read-response logging
  // -------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (pending_read_q) begin
      $display("[abr_fpga_top_sim] AHB read  addr=0x%08X  rdata=0x%016X",
               haddr_q, hrdata_o);
    end
  end

  // -------------------------------------------------------------------------
  // Tie-offs
  // -------------------------------------------------------------------------
`ifdef RV_FPGA_SCA
  assign NTT_trigger  = 1'b0;
  assign PWM_trigger  = 1'b0;
  assign PWA_trigger  = 1'b0;
  assign INTT_trigger = 1'b0;
`endif

  assign busy_o       = 1'b0;
  assign error_intr_o = 1'b0;
  assign notif_intr_o = 1'b0;

endmodule
