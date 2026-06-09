
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
  logic                      usb_rdn;
  logic                      usb_wrn;
  logic                      usb_cen;
  logic [USB_DATA_WIDTH-1:0] usb_rdata;
  logic [USB_DATA_WIDTH-1:0] usb_wdata;
  logic [USB_ADDR_WIDTH-1:0] usb_addr;
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
  // TB Logic Instance
  // -------------------------------------------------------------------------

  initial begin

    logic dut_busy = 1'b1;
    CwRegWord_t read_data;
    AbrInstr_t abr_instr;
    
    $display("[%16t ns] TB : Starting tb_abr_fpga testbench", $realtime/1ns);

    // initialise signals
    usb_clk_enable = 1'b1;
    usb.wdata      = 0;
    usb.addr       = 0;
    usb.rdn        = 1;
    usb.wrn        = 1;
    usb.cen        = 1;

    // simulate reset 
    tb_reset = 1'b0;
    #(USB_CLK_PERIOD*5);
    tb_reset = 1'b1;

    #(USB_CLK_PERIOD*10);

    // lift DUT from reset
    dut_deassert_reset(usb);

    // read ABR status register via data buffer
    abr_instr.addr     = 'h0014;
    abr_instr.len_wrds =   'h01;
    abr_instr.op_code  =    'h0;

    // execute READ instruction
    exec_instr(abr_instr, usb);

    $display("\n[%16t ns] TB : READ_TRANSFER COMPLETE\n", $realtime/1ns);

    // Read data back from Data Buffer
    read_word(
      CW310_ADDR_ABR_DBUFF_BASE, 
      read_data,
      usb
    );
    
    for (int unsigned i = 0; i < 16; i++) begin
      // write dummy words to ABR
      write_word(
        CW310_ADDR_ABR_DBUFF_BASE + USB_ADDR_WIDTH'(i*4), 
        CwRegWord_t'({16'hDEAD, 16'(i)}),
        usb
      );
    end

    // write the dummy bytes from DBUFF to MLDSA_SEED
    abr_instr.addr     = 'h0058;
    abr_instr.len_wrds =   'h10;
    abr_instr.op_code  =    'h1;

    // execute WRITE instruction
    exec_instr(abr_instr, usb);

    $display("\n[%16t ns] TB : WRITE_TRANSFER COMPLETE\n", $realtime/1ns);

    // clear DBUFF 
    for (int unsigned i = 0; i < 16; i++) begin
      write_word(
        CW310_ADDR_ABR_DBUFF_BASE + USB_ADDR_WIDTH'(i*4), 
        CwRegWord_t'(32'h0000_0000),
        usb
      );
    end

    // read the dummy bytes from MLDSA_SEED back to DBUFF
    abr_instr.addr     = 'h0058;
    abr_instr.len_wrds =   'h10;
    abr_instr.op_code  =    'h0;

    // execute READ instruction
    exec_instr(abr_instr, usb);

    // print DBUFF contents
    $display("\n[%16t] TB : Reading out from DBUFF", $realtime/1ns);
    
    for (int unsigned i = 0; i < 16; i++) begin
      // read dummy words from BUFF
      read_word(
        CW310_ADDR_ABR_DBUFF_BASE + USB_ADDR_WIDTH'(i*4), 
        read_data,
        usb
      );
      $display("\t\tRead 0x%8H from DBUFF entry %d", read_data, i);
    end

    // end of test
    $display("\nTest Complete!\n");
    $finish;
    
  end

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
  assign usb_data_net = read_select ? 'Z : usb.wdata;
  assign usb.rdata    = usb_data_net;

  wire #1 usb_rdn_dly = usb.rdn;
  wire #1 usb_wrn_dly = usb.wrn;
  wire #1 usb_cen_dly = usb.cen;

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
    .USB_D      ( usb_data_net     ),
    .USB_A      ( usb.addr         ),
    .USB_nRD    ( usb_rdn_dly      ),
    .USB_nWR    ( usb_wrn_dly      ),
    .USB_nCE    ( usb_cen_dly      ),
    .usb_trigger( usb_trigger      )
  );


endmodule : tb_abr_fpga
