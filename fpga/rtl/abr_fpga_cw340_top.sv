// abr_fpga_cw340_top.vs - Top-level module for the ABR FPGA CW340 design

(* DONT_TOUCH = "yes" *)
module abr_fpga_cw340_top 
  import abr_fpga_pkg::*;
(
    input  wire PLL_CLK_1,   // 62.5MHz clk
    input  wire USRSW0,      // active-low reset
    output wire [4:0] USRLED // user LEDs
);

  timeunit 1ns/1ps;

  `ifndef ABR_OP
    `define ABR_OP OP_KGSIGN
  `endif

  localparam integer unsigned ResetSyncStages = 3;
  localparam op_e             Operation       = `ABR_OP;
  localparam integer unsigned ResetCycles     = 16; 

  // Internal signal for reset
  wire reset_ext;
  wire reset_int;
  wire rst_n;
  wire clk_100MHz;

  (* DONT_TOUCH = "yes" *) logic done_d, done_q;
  (* DONT_TOUCH = "yes" *) logic error_d, error_q;
  (* DONT_TOUCH = "yes" *) logic busy_d, busy_q;
  (* DONT_TOUCH = "yes" *) logic error_intr_d, error_intr_q;
  (* DONT_TOUCH = "yes" *) logic notif_intr_d, notif_intr_q;

  // Debug counter for LED toggling
  logic [25:0] debug_counter;

  logic [ResetSyncStages-1:0] resetn_sync_ff;

  // Generate active-high reset signal
  assign reset_ext = ~USRSW0;
  assign USRLED[0] = reset_int;         // Drive LED with PLL lock for debugging
  assign USRLED[1] = debug_counter[25]; // Toggle LED at ~1Hz
  assign USRLED[2] = done_q;            // Drive LED with done status for debugging
  assign USRLED[3] = error_q;           // Drive LED with error status for debugging
  assign USRLED[4] = busy_q;            // Drive LED with busy status for debugging
  assign rst_n     = resetn_sync_ff[ResetSyncStages-1];

  ip_top_clk top_clk (
    .clk_in1  ( PLL_CLK_1  ), // input  external clock in
    .clk_out  ( clk_100MHz ), // output clk_out
    .reset    ( reset_ext  ), // input  reset
    .clk_lock ( reset_int  )  // output clk_lock    
  );

  // n-stage reset synchronizer
  always_ff @(posedge clk_100MHz or posedge reset_ext) begin
    if (reset_ext) begin
      resetn_sync_ff <= '0; // Set all stages to 0 on reset
    end else begin
      resetn_sync_ff <= {resetn_sync_ff[ResetSyncStages-2:0], reset_int}; // Shift in the async reset
    end
  end

  // instantiate the design
  abr_fpga_top #(  
    .OPERATION    ( Operation   ),
    .RESET_CYCLES ( ResetCycles )
  ) i_abr_fpga_top (
    .clk_i        ( clk_100MHz ),
    .rst_ni       ( rst_n      ),      // active-low board/PLL reset

`ifdef RV_FPGA_SCA   // Warning: This doesn't work right now...
    .NTT_trigger  ( /* NC */ ),
    .PWM_trigger  ( /* NC */ ),
    .PWA_trigger  ( /* NC */ ),
    .INTT_trigger ( /* NC */ ),
`endif

    .done_o       ( done_d ), // pulses high for one cycle when operation completes
    .error_o      ( error_d ), // asserted and held on STATUS error

    // abr_top status pass-through
    .busy_o       ( busy_d ),
    .error_intr_o ( error_intr_d ),
    .notif_intr_o ( notif_intr_d )
  );

  // register status signals from abr_top
  always_ff @(posedge clk_100MHz or negedge rst_n) begin
    if (!rst_n) begin
      done_q        <= 1'b0;
      error_q       <= 1'b0;
      busy_q        <= 1'b0;
      error_intr_q  <= 1'b0;
      notif_intr_q  <= 1'b0;
    end else begin
      // latch status signal
      if (done_d) begin
        done_q <= 1'b1;
      end
      
      if (error_d) begin
        error_q <= 1'b1;
      end
      
      busy_q        <= busy_d;

      error_intr_q  <= error_intr_d;
      notif_intr_q  <= notif_intr_d;
    end
  end

  // create a 1Hz pulse for debugging (ToDo: Remove this)  
  always_ff @(posedge clk_100MHz or negedge rst_n) begin
    if (!rst_n) begin
      debug_counter <= 0;
    end else begin
      debug_counter <= debug_counter + 1;
    end
  end


endmodule
