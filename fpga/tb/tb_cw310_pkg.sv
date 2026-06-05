
package tb_cw310_pkg;

  import abr_fpga_pkg::*;

  parameter realtime TB_PLL_CLK_PERIOD =  1.0ns; 
  parameter realtime USB_CLK_PERIOD    = 10.0ns;
  parameter realtime TB_RESET_DURATION = 20.0ns; // Reset active for first 20 ns
  parameter realtime TB_TIMEOUT        =  1.0ms; // Timeout for test completion

  parameter bit      VERBOSE           = 1'b0;

  typedef logic [      USB_ADDR_WIDTH-1:0] UsbAddr_t;
  typedef logic [      USB_DATA_WIDTH-1:0] UsbData_t;
  typedef logic [ USB_WORD_ADDR_WIDTH-1:0] RegAddr_t;
  typedef logic [     USB_BCOUNT_SIZE-1:0] ByteCnt_t;

  // ------------------------------------------------------------------------
  // Tasks to read/write USB registers
  // ------------------------------------------------------------------------

  task automatic write_byte(
    input  RegAddr_t       address,
    input  ByteCnt_t       subbyte,
    input  UsbData_t       data,
    ref    logic           usb_clk,
    ref    UsbAddr_t       usb_addr,
    ref    UsbData_t       usb_wdata,
    ref    logic           usb_wrn,
    ref    logic           usb_cen
  );
    begin
      @(posedge usb_clk);
      usb_addr  = {address, subbyte};
      usb_wdata = data;
      usb_wrn   = 1'b0;
      @(posedge usb_clk);
      usb_cen = 1'b0;
      @(posedge usb_clk);
      usb_cen = 1'b1;
      @(posedge usb_clk);
      usb_wrn = 1'b1;
      @(posedge usb_clk);
    end
  endtask : write_byte


  task automatic read_byte(
    input  RegAddr_t       address,
    input  ByteCnt_t       subbyte,
    output UsbData_t       data,
    ref    logic           usb_clk,
    ref    UsbAddr_t       usb_addr,
    ref    logic           usb_rdn,
    ref    logic           usb_cen,
    ref    UsbData_t       usb_data
  );
    begin
      @(posedge usb_clk);
      usb_addr = {address, subbyte};
      @(posedge usb_clk);
      usb_rdn = 1'b0;
      usb_cen = 1'b0;
      @(posedge usb_clk);
      @(posedge usb_clk);
      #1 data = usb_data;
      @(posedge usb_clk);
      usb_rdn = 1'b1;
      usb_cen = 1'b1;
      repeat(2) @(posedge usb_clk);
    end
  endtask : read_byte


  task automatic write_bytes(
    input  logic     [  1:0] block,
    input  logic     [  7:0] bytes,
    input  RegAddr_t         address,
    input  logic     [255:0] data,
    ref    logic             usb_clk,
    ref    UsbAddr_t         usb_addr,
    ref    UsbData_t         usb_wdata,
    ref    logic             usb_wrn,
    ref    logic             usb_cen
  );
    begin
      for (int subbyte = 0; subbyte < int'(bytes); subbyte++) begin
        write_byte(
          address, 
          subbyte[USB_BCOUNT_SIZE-1:0], 
          data[subbyte*8 +: 8],
          usb_clk, usb_addr, usb_wdata, usb_wrn, usb_cen
        );
      end
      if (VERBOSE)
        $display("Write %0h", data);
    end
  endtask : write_bytes


  task automatic read_bytes(
    input  logic     [  1:0] block,
    input  logic     [  7:0] bytes,
    input  RegAddr_t         address,
    output logic     [255:0] data,
    ref    logic             usb_clk,
    ref    UsbAddr_t         usb_addr,
    ref    logic             usb_rdn,
    ref    logic             usb_cen,
    ref    UsbData_t         usb_data
  );
    begin
      for (int subbyte = 0; subbyte < int'(bytes); subbyte++) begin
        read_byte(
          address, 
          subbyte[USB_BCOUNT_SIZE-1:0], 
          data[subbyte*8 +: 8],
          usb_clk, usb_addr, usb_rdn, usb_cen, usb_data);
      end
      if (VERBOSE)
        $display("Read %0h", data);
    end
  endtask : read_bytes

endpackage : tb_cw310_pkg
