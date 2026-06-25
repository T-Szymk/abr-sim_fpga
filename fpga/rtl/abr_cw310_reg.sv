// abr_cw310_reg.sv — CW310 USB register file for the ABR FPGA design.
//
// Connects to cw310_usb_reg_fe with the same byte-wide interface used by
// cw310_reg_aes.  Address decoding:
//   reg_address         — upper USB address bits; selects 128-byte page
//   reg_bytecnt[6:2]    — selects the 32-bit register within page 0
//   reg_bytecnt[1:0]    — selects the byte within that register
//
// Register map (USB byte addresses, matching abr_fpga_pkg CW310_ADDR_* constants):
//   0x0000-0x0003  IDENT      RO   sampled from dut_ident_q
//   0x0004-0x0007  DUT_CTRL0  R/W  driven out as dut_ctrl0_o
//   0x0008-0x000B  DUT_CTRL1  R/W  driven out as dut_ctrl1_o
//   0x000C-0x000F  DUT_STAT0  RO   sampled from dut_stat0_i
//   0x0010-0x0013  DUT_STAT1  RO   sampled from dut_stat1_i
//   0x0014-0x0017  ABR_INSTR  R/W  driven out as abr_instr_o
//   0x0100-0x20FF  ABR_DBUFF  R/W  forwarded to external buffer module via
//                                  buf_addr_o / buf_wdata_o / buf_wr_o /
//                                  buf_rdata_i (not stored here)
// ToDo: Improve naming such that functional names are used for assignment to
// make it clear what is being assigned.
module abr_cw310_reg
  import abr_fpga_pkg::*;
#(
  parameter integer unsigned pBYTECNT_SIZE = 2,
  parameter integer unsigned pADDR_WIDTH   = 20
) (
  input  logic                                  reset_i,
  input  logic                                  usb_clk,

  // Interface from cw310_usb_reg_fe
  input  logic [pADDR_WIDTH-pBYTECNT_SIZE-1:0] reg_address,
  input  logic [            pBYTECNT_SIZE-1:0] reg_bytecnt,
  output logic [                          7:0] read_data,
  input  logic [                          7:0] write_data,
  input  logic                                 reg_read,
  input  logic                                 reg_write,
  input  logic                                 reg_addrvalid,

  // R/W registers — values written by USB host, driven as outputs
  output logic [        CW_REG_DATA_WIDTH-1:0] dut_ctrl0_o,
  output logic [        CW_REG_DATA_WIDTH-1:0] dut_ctrl1_o,
  output logic [        CW_REG_DATA_WIDTH-1:0] abr_instr_o,

  // RO registers — values driven from external logic, readable by USB host
  input  logic [        CW_REG_DATA_WIDTH-1:0] dut_stat0_i,
  input  logic [        CW_REG_DATA_WIDTH-1:0] dut_stat1_i,

  // ABR_DBUFF passthrough — accesses forwarded to an external buffer module.
  // buf_addr_o is driven combinationally whenever the address falls in the
  // buffer range; buf_wr_o is pulsed for one USB clock on each write byte.
  output logic [              pADDR_WIDTH-1:0] buf_addr_o,
  output logic [                          7:0] buf_wdata_o,
  output logic                                 buf_wr_o,
  input  logic [                          7:0] buf_rdata_i
);

  timeunit 1ns/1ps;

  // ---------------------------------------------------------------------------
  // Register index constants (reg_bytecnt[15:2]) derived from package addresses
  // ---------------------------------------------------------------------------
  localparam logic [13:0] IDX_DUT_IDENT = CW310_ADDR_DUT_IDENT[15:2]; // 15'h00
  localparam logic [13:0] IDX_DUT_CTRL0 = CW310_ADDR_DUT_CTRL0[15:2]; // 15'h01
  localparam logic [13:0] IDX_DUT_CTRL1 = CW310_ADDR_DUT_CTRL1[15:2]; // 15'h02
  localparam logic [13:0] IDX_DUT_STAT0 = CW310_ADDR_DUT_STAT0[15:2]; // 15'h03
  localparam logic [13:0] IDX_DUT_STAT1 = CW310_ADDR_DUT_STAT1[15:2]; // 15'h04
  localparam logic [13:0] IDX_ABR_INSTR = CW310_ADDR_ABR_INSTR[15:2]; // 15'h05

  // ---------------------------------------------------------------------------
  // Buffer range bounds expressed as reg_address values.
  // reg_address = USB_A[19:pBYTECNT_SIZE], so each unit is 2^pBYTECNT_SIZE bytes.
  // With pBYTECNT_SIZE=7: DBUFF_BASE=0x0100>>7=2, DBUFF_HI=0x20FF>>7=65.
  // ---------------------------------------------------------------------------
  localparam int DBUFF_ADDR_LO = int'(CW310_ADDR_ABR_DBUFF_BASE) >> pBYTECNT_SIZE;
  localparam int DBUFF_ADDR_HI = (int'(CW310_ADDR_ABR_DBUFF_END) - 1) >> pBYTECNT_SIZE;

  // ---------------------------------------------------------------------------
  // Internal signals
  // ---------------------------------------------------------------------------
  logic [CW_REG_DATA_WIDTH-1:0] dut_ident_q;
  logic [CW_REG_DATA_WIDTH-1:0] dut_ctrl0_q;
  logic [CW_REG_DATA_WIDTH-1:0] dut_ctrl1_q;
  logic [CW_REG_DATA_WIDTH-1:0] abr_instr_q;

  logic [pADDR_WIDTH-1:0]  full_byte_addr; // reconstructed 20-bit USB byte address
  logic [13:0]             reg_idx;        // register select within page 0
  logic [ 1:0]             byte_sel;       // byte within 32-bit register
  logic                    buf_sel;        // access targets the ABR_DBUFF region

  logic [CW_REG_DATA_WIDTH-1:0] dut_stat0;
  logic [CW_REG_DATA_WIDTH-1:0] dut_stat1;

  logic instr_busy;
  logic instr_run;

  assign instr_busy = dut_stat1_i[0];
  assign instr_run  = dut_ctrl1_q[0];

  // break out any status signals which are driven by output of ctrl regs here
  assign dut_stat0       = dut_stat0_i;
  assign dut_stat1[   0] = instr_run | instr_busy; // xfer busy driven by instr_run | xfer_busy
  assign dut_stat1[31:1] = dut_stat1_i[31:1];  

  // Full-width buffer offset subtraction — pADDR_WIDTH bits comfortably spans
  // the 0x0100–0x20FF window (0x20FF = 8447 < 2^20).
  logic [pADDR_WIDTH-1:0] buf_offset;

  assign full_byte_addr  = {reg_address, reg_bytecnt};
  assign reg_idx         = full_byte_addr[15:2];
  assign byte_sel        = full_byte_addr[ 1:0];

  assign buf_sel         = reg_addrvalid &&
                           (int'(reg_address) >= DBUFF_ADDR_LO) &&
                           (int'(reg_address) <= DBUFF_ADDR_HI);

  // Buffer byte offset: subtract the buffer base from the address.
  assign buf_offset      = full_byte_addr - CW310_ADDR_ABR_DBUFF_BASE;
  assign buf_addr_o      = buf_offset;

  // Write data and strobe forwarded directly; address is always combinational.
  assign buf_wdata_o     = write_data;
  assign buf_wr_o        = buf_sel && reg_write;

  // ---------------------------------------------------------------------------
  // Write path — synchronous, byte-lane granularity (scalar registers only)
  // ---------------------------------------------------------------------------
  always_ff @(posedge usb_clk) begin
    if (reset_i) begin
      dut_ident_q <= CW_IDENTIFIER;
      dut_ctrl0_q <= '0;
      dut_ctrl1_q <= '0;
      abr_instr_q <= '0;
    end else begin
      if (reg_write) begin
        case (reg_idx)
          IDX_DUT_CTRL0: dut_ctrl0_q[{byte_sel, 3'b0} +: 8] <= write_data;
          IDX_DUT_CTRL1: dut_ctrl1_q[{byte_sel, 3'b0} +: 8] <= write_data;
          IDX_ABR_INSTR: abr_instr_q[{byte_sel, 3'b0} +: 8] <= write_data;
          default: ;
        endcase
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Read path — combinational.
  // Buffer region takes priority; page registers are checked second.
  // Both ranges are mutually exclusive (buf_sel requires reg_address >= 2).
  // ---------------------------------------------------------------------------
  always_comb begin
    read_data = 8'h00;
    if (reg_read && buf_sel) begin
      read_data = buf_rdata_i;
    end else if (reg_read) begin
      case (reg_idx)
        IDX_DUT_IDENT: read_data = dut_ident_q[{byte_sel, 3'b0} +: 8];
        IDX_DUT_CTRL0: read_data = dut_ctrl0_q[{byte_sel, 3'b0} +: 8];
        IDX_DUT_CTRL1: read_data = dut_ctrl1_q[{byte_sel, 3'b0} +: 8];
        IDX_DUT_STAT0: read_data =   dut_stat0[{byte_sel, 3'b0} +: 8];
        IDX_DUT_STAT1: read_data =   dut_stat1[{byte_sel, 3'b0} +: 8];
        IDX_ABR_INSTR: read_data = abr_instr_q[{byte_sel, 3'b0} +: 8];
        default:       read_data = 8'h00;
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Output assignments
  // ---------------------------------------------------------------------------
  assign dut_ctrl0_o = dut_ctrl0_q;
  assign dut_ctrl1_o = dut_ctrl1_q;
  assign abr_instr_o = abr_instr_q;

endmodule
