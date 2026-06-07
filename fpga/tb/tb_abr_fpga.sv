
module tb_abr_fpga;

  timeunit 1ns / 1ps;
    
  import tb_cw310_pkg::*;
  import abr_fpga_pkg::*;

  logic tb_pll_clk;
  logic tb_usb_clk;
  logic tb_reset;

  logic                     tb_j16_sel;
  logic                     tb_k16_sel;
  logic                     tb_cwio4_trigger;
  logic [    LED_COUNT-1:0] tb_leds;

  logic                      usb_clk;
  logic                      usb_clk_enable;
  wire  [USB_DATA_WIDTH-1:0] usb_data;
  logic [USB_DATA_WIDTH-1:0] usb_data_var;
  logic [USB_DATA_WIDTH-1:0] usb_wdata;
  logic [USB_ADDR_WIDTH-1:0] usb_addr;
  logic                      usb_rdn;
  logic                      usb_wrn;
  logic                      usb_cen;
  logic                      usb_trigger;

  logic                      read_select;

  
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

  assign usb_clk = tb_usb_clk & usb_clk_enable;

  // -------------------------------------------------------------------------
  // TB Logic Instance
  // -------------------------------------------------------------------------

  initial begin

    logic dut_busy = 1'b1;
    logic [3:0][7:0] read_data;
    
    $display("[%0t ns] TB : Starting tb_abr_fpga testbench", $realtime/1ns);

    // initialise signals
    usb_clk_enable = 1'b1;
    usb_wdata      = 0;
    usb_addr       = 0;
    usb_rdn        = 1;
    usb_wrn        = 1;
    usb_cen        = 1;

    // simulate reset 
    tb_reset = 1'b0;
    #(USB_CLK_PERIOD*5);
    tb_reset = 1'b1;

    #(USB_CLK_PERIOD*10);

    // lift DUT from reset
    write_word(
      CW310_ADDR_DUT_CTRL0, 
      CwRegWord_t'('h1),
      usb_clk, usb_addr, usb_wdata, usb_wrn,usb_cen
    );

    // read ABR status register via data buffer
    // write READ instr. to INSTR reg
    write_word(
      CW310_ADDR_ABR_INSTR, 
      CwRegWord_t'('h00140010),
      usb_clk, usb_addr, usb_wdata, usb_wrn,usb_cen
    );

    // commit INSTR
    write_word(
      CW310_ADDR_DUT_CTRL1, 
      CwRegWord_t'('h1),
      usb_clk, usb_addr, usb_wdata, usb_wrn,usb_cen
    );

    // wait for transfer busy flag to clear
    while(1) begin
    read_word(
      CW310_ADDR_DUT_STAT1, 
      read_data,
      usb_clk, usb_addr, usb_rdn, usb_cen,usb_data_var
    );

    dut_busy = read_data[0][1];

    if(dut_busy == 1'b0) 
      break;

    end

    $display("READ_TRANSFER COMPLETE");

    // Read data back from Data Buffer
    read_word(
      CW310_ADDR_ABR_DBUFF_BASE, 
      read_data,
      usb_clk, usb_addr, usb_rdn, usb_cen,usb_data_var
    );
    
  end

  // -------------------------------------------------------------------------
  // TB Timeout
  // -------------------------------------------------------------------------
  
  initial begin
    forever begin
      @(posedge tb_pll_clk);
      if ($realtime >= TB_TIMEOUT) begin 
        $display("[%0t ns] TB : Test bench timed out!", $realtime/1ns);
        $finish;
      end
    end
  end

  // -------------------------------------------------------------------------
  // Waveform gen
  // -------------------------------------------------------------------------

`ifdef VERILATOR
    initial begin
        $dumpfile("vtrace.fst");
        $dumpvars();
    end
`endif 

  // -------------------------------------------------------------------------
  // DUT Instance
  // -------------------------------------------------------------------------

  assign tb_j16_sel  = 1'b0; // enabled pll clock
  assign tb_k16_sel  = 1'b0; // enables output clock
  assign usb_trigger = 1'b0; // unused - normally used to drive functions when usb clock is disabled

  assign read_select  = (usb_wrn == 1'b0) ? 1'b0 : 1'b1;
  assign usb_data     = read_select ? 'Z : usb_wdata;
  assign usb_data_var = usb_data;

  wire #1 usb_rdn_dly = usb_rdn;
  wire #1 usb_wrn_dly = usb_wrn;
  wire #1 usb_cen_dly = usb_cen;

  abr_fpga_cw310_top #(
    .pBYTECNT_SIZE( USB_BCOUNT_SIZE ),
    .pADDR_WIDTH  ( USB_ADDR_WIDTH  )
   ) abr_fpga_cw310_top (
    .PLL_CLK_1  ( tb_pll_clk       ),
    .CWIO_HS1   ( /*NC*/           ),
    .CWIO_HS2   ( 1'b0             ),
    .USRDIP0    ( tb_j16_sel       ),
    .USRDIP1    ( tb_k16_sel       ),
    .USRSW0     ( tb_reset         ),
    .USRLED     ( tb_leds          ),
    .CWIO_IO4   ( tb_cwio4_trigger ),
    .usb_clk    ( tb_usb_clk       ),
    .USB_D      ( usb_data         ),
    .USB_A      ( usb_addr         ),
    .USB_nRD    ( usb_rdn_dly      ),
    .USB_nWR    ( usb_wrn_dly      ),
    .USB_nCE    ( usb_cen_dly      ),
    .usb_trigger( usb_trigger      )
  );


endmodule : tb_abr_fpga
