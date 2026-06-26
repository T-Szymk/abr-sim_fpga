
// Directory holding the expected-value .mem vectors (generated from
// flow/mlkem-gen.py with zero seeds/msg). Normally set by the Makefile to an
// absolute path; the fallback is relative to the Verilator run dir .sim_build.
`ifndef VECTOR_DIR
  `define VECTOR_DIR "../tb/vectors"
`endif

module tb_abr_fpga_leds;

  timeunit 1ns / 1ps;
    
  import tb_cw310_pkg::*;
  import abr_fpga_pkg::*;

  logic tb_pll_clk;
  logic tb_usb_clk;
  logic tb_reset;

  logic                      tb_j16_sel;
  logic                      tb_k16_sel;
  logic                      tb_cwio4_trigger;
  logic [     LED_COUNT-1:0] tb_leds;

  logic                      usb_clk_enable;
  wire  [USB_DATA_WIDTH-1:0] usb_data_net;

  logic                      usb_trigger;

  logic                      read_select;

  UsbBus_t usb;

  // -------------------------------------------------------------------------
  // Clock gen
  // -------------------------------------------------------------------------

  // PLL
  initial begin
    tb_pll_clk = 1'b0;
    forever begin
      #(TB_PLL_CLK_PERIOD) tb_pll_clk = ~tb_pll_clk;
    end
  end

  // USB
  initial begin
    tb_usb_clk = 1'b0;
    forever begin
      #(USB_CLK_PERIOD) tb_usb_clk = ~tb_usb_clk;
    end
  end

  assign usb.clk = tb_usb_clk & usb_clk_enable;

  // -------------------------------------------------------------------------
  // TB Reset
  // -------------------------------------------------------------------------

  initial begin
    tb_reset = '0;
    #TB_RESET_DURATION;
    tb_reset = 1'b1;
  end

  // -------------------------------------------------------------------------
  // TB Logic Instance
  // -------------------------------------------------------------------------

  assign usb_clk_enable = 1'b1;

  // -------------------------------------------------------------------------
  // TB Timeout
  // -------------------------------------------------------------------------
  
  initial begin
    forever begin
      @(posedge tb_pll_clk);
      if ($realtime >= TB_TIMEOUT) begin 
        $display("[%16t ns] TB : Test bench timed out!", $realtime/1ns);
        $finish;
      end
    end
  end

  // -------------------------------------------------------------------------
  // Waveform gen
  // -------------------------------------------------------------------------

`ifdef VERILATOR
    // pass +notrace to skip waveform dumping (much faster regression runs)
    initial begin
      if (!$test$plusargs("notrace")) begin
        $dumpfile("vtrace.fst");
        $dumpvars();
      end
    end
`endif

  // -------------------------------------------------------------------------
  // DUT Instance
  // -------------------------------------------------------------------------

  assign tb_j16_sel  = 1'b0; // enabled pll clock
  assign tb_k16_sel  = 1'b0; // enables output clock
  assign usb_trigger = 1'b0; // unused - normally used to drive functions when usb clock is disabled

  assign read_select  = (usb.wrn == 1'b0) ? 1'b0 : 1'b1;
  assign usb_data_net = read_select ? 'Z : usb.wdata;
  assign usb.rdata    = usb_data_net;

  wire #1 usb_rdn_dly = usb.rdn;
  wire #1 usb_wrn_dly = usb.wrn;
  wire #1 usb_cen_dly = usb.cen;

  abr_fpga_cw310_top i_dut (
    .PLL_CLK_1  ( tb_pll_clk       ),
    .CWIO_HS1   ( /*NC*/           ),
    .CWIO_HS2   ( 1'b0             ),
    .USRDIP0    ( tb_j16_sel       ),
    .USRDIP1    ( tb_k16_sel       ),
    .USRSW0     ( tb_reset         ),
    .USRLED     ( tb_leds          ),
    .CWIO_IO4   ( tb_cwio4_trigger ),
    .usb_clk    ( tb_usb_clk       ),
    .USB_D      ( usb_data_net     ),
    .USB_A      ( usb.addr         ),
    .USB_nRD    ( usb_rdn_dly      ),
    .USB_nWR    ( usb_wrn_dly      ),
    .USB_nCE    ( usb_cen_dly      ),
    .usb_trigger( usb_trigger      )
  );


endmodule : tb_abr_fpga_leds
