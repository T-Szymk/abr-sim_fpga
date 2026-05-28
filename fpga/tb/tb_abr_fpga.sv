
module tb_abr_fpga;

    timeunit 1ns / 1ps;
    
    import abr_fpga_pkg::*;

    parameter realtime TB_CLOCK_PERIOD   =  1.0ns; // 1000 MHz clock
    parameter realtime TB_RESET_DURATION = 20.0ns; // Reset active for first 20 ns
    parameter realtime TB_TIMEOUT        =  1.0ms;  // Timeout for test completion

    parameter op_e             OPERATION    = OP_KGSIGN;
    parameter integer unsigned RESET_CYCLES = 16;

    parameter integer unsigned TEST_LOOP_COUNT = 1; // Number of times to repeat the operation

    // Clock and reset
    logic clk_i;
    logic rst_ni;
    logic done_o;
    logic error_o;
    logic busy_o;
    logic error_intr_o;
    logic notif_intr_o;
    logic ext_trigger;

    integer unsigned test_loop_counter;

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_START_OP,
        ST_WAIT_FOR_DONE
    } tb_state_e;

    tb_state_e tb_state;

    // Clock generation
    initial begin
        clk_i = 0;
        forever begin
          #(TB_CLOCK_PERIOD/2) clk_i = ~clk_i; // 100 MHz clock
          if ($realtime > TB_TIMEOUT) begin
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

    // TB State machine to trigger operation
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ext_trigger       <= 0;
            tb_state          <= ST_IDLE;
            test_loop_counter <= 0;
        end else begin
            case (tb_state)
                ST_IDLE: begin
                    // Wait for a few cycles after reset before starting the operation
                    if ($realtime > (TB_RESET_DURATION + 10ns)) begin
                        ext_trigger <= 1; // Trigger the operation
                        tb_state <= ST_START_OP;
                    end
                end

                ST_START_OP: begin
                    ext_trigger <= 0; // De-assert trigger after one cycle
                    tb_state    <= ST_WAIT_FOR_DONE;
                end

                ST_WAIT_FOR_DONE: begin                    
                    // Wait for done_o to be asserted by the DUT (handled in the monitor below)
                    if (done_o) begin
                        if (test_loop_counter < TEST_LOOP_COUNT) begin
                            test_loop_counter <= test_loop_counter + 1;
                            ext_trigger       <= 1; // Trigger the next operation
                            tb_state          <= ST_START_OP;
                        end else begin
                            $display("TB: Operation completed successfully at %0t", $realtime);
                            $finish;
                        end
                    end else if (error_o) begin
                        $display("TB: Operation failed with error at %0t", $realtime);
                        $finish;
                    end
                end

                default: tb_state <= ST_IDLE;
            endcase
        end
    end

    // Instantiate the DUT
    abr_fpga_top #(
        .OPERATION     ( OPERATION    ),
        .RESET_CYCLES  ( RESET_CYCLES )
    ) dut (
        .clk_i         ( clk_i        ),
        .rst_ni        ( rst_ni       ),
`ifdef RV_FPGA_SCA
        .NTT_trigger   ( NTT_trigger  ),
        .PWM_trigger   ( PWM_trigger  ),
        .PWA_trigger   ( PWA_trigger  ),
        .INTT_trigger  ( INTT_trigger ),
`endif
        .ext_trigger_i ( ext_trigger  ),
        .done_o        ( done_o       ),
        .error_o       ( error_o      ),
        .busy_o        ( busy_o       ),
        .error_intr_o  ( error_intr_o ),
        .notif_intr_o  ( notif_intr_o )
    );

`ifdef VERILATOR
    initial begin
        $dumpfile("vtrace.vcd");
        $dumpvars();
    end
`endif 


endmodule : tb_abr_fpga
