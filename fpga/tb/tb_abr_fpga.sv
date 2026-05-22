
module tb_abr_fpga;

    timeunit 1ns / 1ps;
    
    import abr_fpga_pkg::*;

    parameter time TB_CLOCK_PERIOD   = 10ns; // 100 MHz clock
    parameter time TB_RESET_DURATION = 20ns; // Reset active for first 20 ns
    parameter time TB_TIMEOUT        = 1ms;  // Timeout for test completion

    parameter op_e             OPERATION    = OP_KEYGEN;
    parameter integer unsigned RESET_CYCLES = 16;

    // Clock and reset
    logic clk_i;
    logic rst_ni;
    logic done_o;
    logic error_o;
    logic busy_o;
    logic error_intr_o;
    logic notif_intr_o;

    // Clock generation
    initial begin
        clk_i = 0;
        forever begin
          #(TB_CLOCK_PERIOD/2) clk_i = ~clk_i; // 100 MHz clock
          if ($time > TB_TIMEOUT) begin
            $display("ERROR: Test timed out after %0t", $time);
            $finish;
          end
        end
    end

    // Reset generation
    initial begin
        rst_ni = 0;
        #(TB_RESET_DURATION) rst_ni = 1; // Release reset after 20 ns
    end

    // Instantiate the DUT
    abr_fpga_top #(
        .OPERATION    ( OPERATION    ),
        .RESET_CYCLES ( RESET_CYCLES )
    ) dut (
        .clk_i        ( clk_i        ),
        .rst_ni       ( rst_ni       ),
`ifdef RV_FPGA_SCA
        .NTT_trigger  ( NTT_trigger  ),
        .PWM_trigger  ( PWM_trigger  ),
        .PWA_trigger  ( PWA_trigger  ),
        .INTT_trigger ( INTT_trigger ),
`endif
        .done_o       ( done_o       ),
        .error_o      ( error_o      ),
        .busy_o       ( busy_o       ),
        .error_intr_o ( error_intr_o ),
        .notif_intr_o ( notif_intr_o )
    );

endmodule : tb_abr_fpga
