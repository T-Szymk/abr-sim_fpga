// abr_instr_decode.sv - Module to take output of instruction register and 
// decode to signals used for control of ABR operations.

module abr_instr_decode 
  import abr_fpga_pkg::*;
(
  input  logic [CW_REG_DATA_WIDTH-1:0] abr_instr_i,

  output logic [   AHB_ADDR_WIDTH-1:0] m_xfer_b_addr_o,
  output logic [M_XFER_BLEN_WIDTH-1:0] m_xfer_b_len_o,
  output logic                         m_xfer_op_o
);

  timeunit 1ns / 1ps;

  /* Signal declarations */
  
  logic [INSTR_ADDR_WIDTH-1:0] instr_field_addr;
  logic [ INSTR_LEN_WIDTH-1:0] instr_field_len;
  logic [  INSTR_OP_WIDTH-1:0] instr_field_op;

  /* Logic */

  assign {instr_field_addr, instr_field_len, instr_field_op} = abr_instr_i;

  assign m_xfer_op_o     = instr_field_op[0]; // 0 : read, 1: write
  assign m_xfer_b_len_o  = M_XFER_BLEN_WIDTH'(instr_field_len) << 2; // Convert from word to bytes
  assign m_xfer_b_addr_o = AHB_ADDR_WIDTH'(instr_field_addr);

endmodule : abr_instr_decode
