
module bringup (
    input  wire PLL_CLK1,   // 62.5MHz clk
    input  wire USRSW0,      // active-low reset
    output wire [7:0] USRLED // user LEDs
);

  timeunit 1ns/1ps;

  // create counter_0 to blink LED at 1Hz with aninput clock of 62.5MHz
  logic [25:0] counter_0   = 0; // 26 bits to count up to 62.5 million
  logic [25:0] counter_1   = 0; // 26 bits to count up to 62.5 million
  logic        led_blink_0 = 0;
  logic        led_blink_1 = 0;
  logic        clk_100MHz;
  logic        reset_int;

  assign USRLED[0] = led_blink_0;
  assign USRLED[1] = led_blink_1;
  assign USRLED[2] = USRSW0;
  assign USRLED[7:3] = 6'b1; // turn on unused LEDs for better visibility of blinking LEDs

  always @(posedge PLL_CLK1 or negedge USRSW0) begin
    if (!USRSW0) begin
      counter_0     <= '0;
      led_blink_0 <= 1'b0;
    end else begin
      if (counter_0 == 62_500_000 - 1) begin
        counter_0 <= 0;
        led_blink_0 <= ~led_blink_0; // toggle LEDs
      end else begin
        counter_0 <= counter_0 + 1;
      end
    end
  end

  ip_top_clock i_top_clock (
    .clk_in1  ( PLL_CLK1   ), // input  external clock in
    .clk_out1 ( clk_100MHz ), // output clk_out
    .resetn   ( USRSW0     ), // input  reset
    .locked   ( reset_int  )  // output clk_lock    
  );

  always @(posedge clk_100MHz or negedge reset_int) begin
    if (!reset_int) begin
      counter_1     <= '0;
      led_blink_1 <= 1'b0;
    end else begin
      if (counter_1 == 62_500_000 - 1) begin
        counter_1 <= 0;
        led_blink_1 <= ~led_blink_1; // toggle LEDs
      end else begin
        counter_1 <= counter_1 + 1;
      end
    end
  end

  

endmodule : bringup