
package tb_cw310_pkg;

  import abr_fpga_pkg::*;

  parameter realtime TB_PLL_CLK_PERIOD =  1.0ns; 
  parameter realtime USB_CLK_PERIOD    = 10.0ns;
  parameter realtime TB_RESET_DURATION = 20.0ns; // Reset active for first 20 ns
  parameter realtime TB_TIMEOUT        =  1.0ms; // Timeout for test completion

`ifdef VERBOSE
  parameter bit      VERBOSE           = 1'b1;
`else
  parameter bit      VERBOSE           = 1'b0;
`endif


  typedef logic [         USB_ADDR_WIDTH-1:0]                     UsbAddr_t;
  typedef logic [         USB_DATA_WIDTH-1:0]                     UsbData_t;
  typedef logic [    USB_WORD_ADDR_WIDTH-1:0]                     RegAddr_t;
  typedef logic [        USB_BCOUNT_SIZE-1:0]                     ByteCnt_t;
  typedef logic [CW_REG_DATA_WIDTH_BYTES-1:0][USB_DATA_WIDTH-1:0] CwRegWord_t;

  // ------------------------------------------------------------------------
  // Helper functions
  // ------------------------------------------------------------------------ 
  function automatic string regaddr2name (
    UsbAddr_t address
  );
    begin
      case (address) inside
        CW310_ADDR_DUT_CTRL0 : begin
          return "DUT_CTRL0";
        end
        CW310_ADDR_DUT_CTRL1 : begin
          return "DUT_CTRL1";
        end
        CW310_ADDR_DUT_STAT0 : begin
          return "DUT_STAT0";
        end
        CW310_ADDR_DUT_STAT1 : begin
          return "DUT_STAT1";
        end
        CW310_ADDR_ABR_INSTR : begin
          return "DUT_INSTR";
        end
        [CW310_ADDR_ABR_DBUFF_BASE:CW310_ADDR_ABR_DBUFF_END] : begin
          return "ABR_DBUFF";
        end
        default : begin
          return "UNKNOWN";
        end
      endcase
    end
  endfunction : regaddr2name
  // ------------------------------------------------------------------------
  // Tasks to read/write USB registers
  // ------------------------------------------------------------------------

  task automatic write_byte(
    input  UsbAddr_t       address,
    input  UsbData_t       data,
    ref    logic           usb_clk,
    ref    UsbAddr_t       usb_addr,
    ref    UsbData_t       usb_wdata,
    ref    logic           usb_wrn,
    ref    logic           usb_cen
  );
    begin
      
      RegAddr_t reg_addr = address[USB_ADDR_WIDTH-1:USB_BCOUNT_SIZE];
      ByteCnt_t subbyte  = address[USB_BCOUNT_SIZE-1:0];

      @(posedge usb_clk);
      usb_addr  = {reg_addr, subbyte};
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
    input  UsbAddr_t       address,
    output UsbData_t       data,
    ref    logic           usb_clk,
    ref    UsbAddr_t       usb_addr,
    ref    logic           usb_rdn,
    ref    logic           usb_cen,
    ref    UsbData_t       usb_data
  );
    begin
      
      RegAddr_t reg_addr = address[USB_ADDR_WIDTH-1:USB_BCOUNT_SIZE];
      ByteCnt_t subbyte  = address[USB_BCOUNT_SIZE-1:0];

      @(posedge usb_clk);
      usb_addr = {reg_addr, subbyte};
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


  task automatic write_word(
    input  UsbAddr_t   address,
    input  CwRegWord_t data,
    ref    logic       usb_clk,
    ref    UsbAddr_t   usb_addr,
    ref    UsbData_t   usb_wdata,
    ref    logic       usb_wrn,
    ref    logic       usb_cen
  );
    begin
      for (int unsigned subbyte = 0; subbyte < CW_REG_DATA_WIDTH_BYTES; subbyte++) begin
        write_byte(
          address + UsbAddr_t'(subbyte),
          data[subbyte],
          usb_clk, usb_addr, usb_wdata, usb_wrn, usb_cen
        );
      end
      if (VERBOSE) begin
        $display("[%0t ns] %M", $realtime/1ns,
                  "\n\t\tNAME: %s ", regaddr2name(address),
                  "\n\t\tADDR: 0x%H ", address,
                  "\n\t\tDATA: 0x%H", data
                );
      end
    end
  endtask : write_word


  task automatic read_word (
    input  UsbAddr_t   address,
    output CwRegWord_t data,
    ref    logic       usb_clk,
    ref    UsbAddr_t   usb_addr,
    ref    logic       usb_rdn,
    ref    logic       usb_cen,
    ref    UsbData_t   usb_data
  );
    begin
      for (int unsigned subbyte = 0; subbyte < CW_REG_DATA_WIDTH_BYTES; subbyte++) begin
        read_byte(
          address + UsbAddr_t'(subbyte),
          data[subbyte],
          usb_clk, usb_addr, usb_rdn, usb_cen, usb_data);
      end
      if (VERBOSE)
        $display("[%0t ns] %M", $realtime/1ns,
                  "\n\t\tNAME: %s ", regaddr2name(address),
                  "\n\t\tADDR: 0x%H ", address,
                  "\n\t\tDATA: 0x%0H", data
                );
    end
  endtask : read_word

endpackage : tb_cw310_pkg
