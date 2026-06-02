/* 
ChipWhisperer Bergen Target - Simple testbench to check for signs of life.

Copyright (c) 2021, NewAE Technology Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted without restriction. Note that modules within
the project may have additional restrictions, please carefully inspect
additional licenses.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of NewAE Technology Inc.
*/

module tb_310_aes 
   import tb_cw310_pkg::*;
#(
    parameter integer unsigned pUSB_CLOCK_PERIOD =    10,
    parameter integer unsigned pPLL_CLOCK_PERIOD =     6,
    parameter integer unsigned pSEED             =     1,
    parameter integer unsigned pTIMEOUT          = 30000,
    parameter integer unsigned pDUMP             =     0
)();

  timeunit 1ns/1ps;

  logic         usb_clk;
  logic         usb_clk_enable;
  UsbData_t     usb_data_internal;
  wire    [7:0] usb_data;
  UsbData_t     usb_wdata;
  UsbAddr_t     usb_addr;
  logic         usb_rdn;
  logic         usb_wrn;
  logic         usb_cen;
  logic         usb_trigger;

  logic       j16_sel;
  logic       k16_sel;

  logic pushbutton;
  logic pll_clk1;
  logic tio_clkin;
  logic trig_out;

  logic usrled0, usrled1, usrled2;

  logic tio_trigger;
  logic tio_clkout;

  int seed;
  int errors;
  int warnings;
  int i;
    
  logic [31:0] write_data;

  logic clk = pll_clk1;  // shorthand for testbench

  int cycle;
  int total_time;

  logic [127:0] read_data;
  logic [127:0] expected_cipher = 128'h8a278bf8fa2812bc39e52c76205af377;

  logic read_select;

  assign usb_data          = read_select ? 8'bz : usb_wdata;
  assign usb_data_internal = usb_data;
  assign tio_clkin         = pll_clk1;


  initial begin
    seed     = pSEED;
    errors   = 0;
    warnings = 0;

    $display("Running with seed=%0d", seed);
    void'($urandom(seed));
    
    if (pDUMP) begin
       $dumpfile("results/tb.fst");
       $dumpvars(0, tb_310_aes);
    end
    
    usb_clk        = 1'b1;
    usb_clk_enable = 1'b1;
    pll_clk1       = 1'b1;

    usb_wdata   = 0;
    usb_addr    = 0;
    usb_rdn     = 1;
    usb_wrn     = 1;
    usb_cen     = 1;
    usb_trigger = 0;

    j16_sel     = 1;
    k16_sel     = 0;
    pushbutton  = 1;
    pll_clk1    = 0;

    #(pUSB_CLOCK_PERIOD*2) pushbutton = 0;
    #(pUSB_CLOCK_PERIOD*2) pushbutton = 1;
    #(pUSB_CLOCK_PERIOD*10);

    write_bytes( 
      0, 
      16, 
      REG_CRYPT_TEXTIN, 
      {32'h12345678, 32'habcdef01, 32'h87654321, 32'hdeadbeef},
      usb_clk, usb_addr, usb_wdata, usb_wrn, usb_cen
    );

    write_bytes(
      0, 
      16, 
      REG_CRYPT_KEY, 
      {32'habcdef01, 32'h12345678, 32'hdeadbeef, 32'h87654321},
      usb_clk, usb_addr, usb_wdata, usb_wrn, usb_cen
    );

      $display("Encrypting via register...");

    write_byte(
      0,
      REG_CRYPT_GO, 
      0, 
      1,
      usb_clk, usb_addr, usb_wdata, usb_wrn, usb_cen
      );
      
      repeat (5) 
        @(posedge usb_clk);
      
      wait_done();
      
      read_bytes(
        0, 
        16, 
        REG_CRYPT_CIPHEROUT, 
        read_data,
        usb_clk, usb_addr, usb_rdn, usb_cen, usb_data_internal
      );
      
      if (read_data == expected_cipher) begin
         $display("Good result");
      end
      else begin
         errors += 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end


      $display("Encrypting via usb_trigger (USB clock disabled)...");

      write_bytes(
        0, 
        1, 
        REG_CRYPT_TEXTIN, 
        8'h01,
        usb_clk, usb_addr, usb_wdata, usb_wrn, usb_cen
      );
      
      expected_cipher = 128'h0efee0bff4cf170752994fb45bd45934;
      usb_clk_enable = 1'b0;
      
      @(posedge usb_clk) usb_trigger = 1'b1;
      
      repeat (10) 
        @(posedge usb_clk); 
      
      usb_trigger = 1'b0;
      
      repeat (30)
        @(posedge pll_clk1);
      
      usb_clk_enable = 1'b1;
      
      repeat (5) 
        @(posedge usb_clk);
      
      wait_done();
      
      read_bytes(
        0, 
        16, 
        REG_CRYPT_CIPHEROUT, 
        read_data,
        usb_clk, usb_addr, usb_rdn, usb_cen, usb_data_internal
      );
      
      if (read_data == expected_cipher) begin
         $display("Good result");
      end else begin
         errors += 1;
         $display("ERROR: expected %h", expected_cipher);
         $display("            got %h", read_data);
      end

      $display("done!");
      #(pUSB_CLOCK_PERIOD*10);
      if (errors)
         $display("SIMULATION FAILED (%0d errors, %0d warnings).", errors, warnings);
      else
         $display("Simulation passed (%0d warnings).", warnings);
      $finish;

   end

   // maintain a cycle counter
   always @(posedge clk) begin
      if (pushbutton == 0)
         cycle <= 0;
      else
         cycle <= cycle + 1;
   end


   // timeout thread:
   initial begin
      #(pUSB_CLOCK_PERIOD*pTIMEOUT);
      errors += 1;
      $display("ERROR: global timeout");
      $display("SIMULATION FAILED (%0d errors).", errors);
      $finish;
   end

   always @(*) begin
      if (usb_wrn == 1'b0)
         read_select = 1'b0;
      else if (usb_rdn == 1'b0)
         read_select = 1'b1;
   end

   always #(pUSB_CLOCK_PERIOD/2) usb_clk = !usb_clk;
   always #(pPLL_CLOCK_PERIOD/2) pll_clk1 = !pll_clk1;

   wire #1 usb_rdn_out = usb_rdn;
   wire #1 usb_wrn_out = usb_wrn;
   wire #1 usb_cen_out = usb_cen;
   wire #1 usb_trigger_out = usb_trigger;

   logic trigger; // TODO: use it?

   cw310_top #(
      .pBYTECNT_SIZE ( pBYTECNT_SIZE ),             
      .pADDR_WIDTH   ( pADDR_WIDTH   ),           
      .pPT_WIDTH     ( pPT_WIDTH     ),         
      .pCT_WIDTH     ( pCT_WIDTH     ),         
      .pKEY_WIDTH    ( pKEY_WIDTH    )          
   ) U_dut (                  
      .usb_clk           ( usb_clk & usb_clk_enable ),
      .USB_D             ( usb_data                 ),
      .USB_A             ( usb_addr                 ),
      .USB_nRD           ( usb_rdn_out              ),
      .USB_nWR           ( usb_wrn_out              ),
      .USB_nCE           ( usb_cen_out              ),
      .usb_trigger       ( usb_trigger_out          ),
    
      .USRDIP0           ( j16_sel                  ),
      .USRDIP1           ( k16_sel                  ),
      .USRSW2            ( pushbutton               ),
      .USRLED0           ( usrled0                  ),
      .USRLED1           ( usrled1                  ),
      .USRLED2           ( usrled2                  ),   

      .PLL_CLK1          (pll_clk1                  ),

      .CWIO_IO4          ( trigger                  ),
      .CWIO_HS1          ( /*NC*/                   ),
      .CWIO_HS2          ( tio_clkin                ),
      .vauxp0            ( 1'b0                     ),
      .vauxn0            ( 1'b0                     ),
      .vauxp1            ( 1'b0                     ),
      .vauxn1            ( 1'b0                     ),
      .vauxp8            ( 1'b0                     ),
      .vauxn8            ( 1'b0                     )
   );


   task wait_done;
      bit busy;
      busy = 1;
      while (busy == 1) begin
        //$display("checking busy...");
        read_byte(
          0, 
          REG_CRYPT_GO, 
          0, 
          busy,
          usb_clk, usb_addr, usb_rdn, usb_cen, usb_data_internal
        );
      end
   endtask


endmodule : tb_310_aes


