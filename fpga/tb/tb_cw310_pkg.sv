`include "cw310_defines.v"

package tb_cw310_pkg;

  parameter int unsigned pADDR_WIDTH   =  20;
  parameter int unsigned pDATA_WIDTH   =   8;
  parameter int unsigned pBYTECNT_SIZE =   7;
  parameter int unsigned pPT_WIDTH     = 128;
  parameter int unsigned pCT_WIDTH     = 128;
  parameter int unsigned pKEY_WIDTH    = 128;
  
  parameter bit          pVERBOSE      = 1'b0;

  localparam integer unsigned RegAddrWidth = pADDR_WIDTH - pBYTECNT_SIZE;

  typedef logic [  pADDR_WIDTH-1:0] UsbAddr_t;
  typedef logic [  pDATA_WIDTH-1:0] UsbData_t;
  typedef logic [ RegAddrWidth-1:0] RegAddr_t;
  typedef logic [pBYTECNT_SIZE-1:0] ByteCnt_t;

  localparam RegAddr_t REG_CRYPT_TEXTIN      = `REG_CRYPT_TEXTIN;
  localparam RegAddr_t REG_CRYPT_KEY         = `REG_CRYPT_KEY;
  localparam RegAddr_t REG_CRYPT_GO          = `REG_CRYPT_GO;
  localparam RegAddr_t REG_CRYPT_CIPHEROUT   = `REG_CRYPT_CIPHEROUT;

  task automatic write_byte(
    input  logic     [1:0] block,
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
      usb_addr  = pADDR_WIDTH'({block, address[5:0], subbyte});
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
    input  logic     [1:0] block,
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
      usb_addr = pADDR_WIDTH'({block, address[5:0], subbyte});
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
          block, 
          address, 
          subbyte[pBYTECNT_SIZE-1:0], 
          data[subbyte*8 +: 8],
          usb_clk, usb_addr, usb_wdata, usb_wrn, usb_cen
        );
      end
      if (pVERBOSE)
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
          block, 
          address, 
          subbyte[pBYTECNT_SIZE-1:0], 
          data[subbyte*8 +: 8],
          usb_clk, usb_addr, usb_rdn, usb_cen, usb_data);
      end
      if (pVERBOSE)
        $display("Read %0h", data);
    end
  endtask : read_bytes

endpackage : tb_cw310_pkg
