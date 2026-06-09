
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

  // wrap usb signals for ease
  typedef struct {
    logic     clk;
    UsbAddr_t addr;
    UsbData_t wdata;
    UsbData_t rdata;
    logic     rdn;
    logic     wrn;
    logic     cen;
  } UsbBus_t;

  // ABR instruction
  typedef struct packed {
    logic [15:0] addr;
    logic [11:0] len_wrds;
    logic [ 3:0] op_code;
  } AbrInstr_t;

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

  // Write single byte of data to address
  task automatic write_byte (
    input  UsbAddr_t       address,
    input  UsbData_t       data,
    ref    UsbBus_t        usb
  );
    begin
      
      RegAddr_t reg_addr = address[USB_ADDR_WIDTH-1:USB_BCOUNT_SIZE];
      ByteCnt_t subbyte  = address[USB_BCOUNT_SIZE-1:0];

      @(posedge usb.clk);
      usb.addr  = {reg_addr, subbyte};
      usb.wdata = data;
      usb.wrn   = 1'b0;
      @(posedge usb.clk);
      usb.cen = 1'b0;
      @(posedge usb.clk);
      usb.cen = 1'b1;
      @(posedge usb.clk);
      usb.wrn = 1'b1;
      @(posedge usb.clk);
    end
  endtask : write_byte

  // read single byte of data from address
  task automatic read_byte (
    input  UsbAddr_t       address,
    output UsbData_t       data,
    ref    UsbBus_t        usb
  );
    begin
      
      RegAddr_t reg_addr = address[USB_ADDR_WIDTH-1:USB_BCOUNT_SIZE];
      ByteCnt_t subbyte  = address[USB_BCOUNT_SIZE-1:0];

      @(posedge usb.clk);
      usb.addr = {reg_addr, subbyte};
      @(posedge usb.clk);
      usb.rdn = 1'b0;
      usb.cen = 1'b0;
      @(posedge usb.clk);
      @(posedge usb.clk);
      #1 data = usb.rdata;
      @(posedge usb.clk);
      usb.rdn = 1'b1;
      usb.cen = 1'b1;
      repeat(2) @(posedge usb.clk);
    end
  endtask : read_byte

  // write 4 Bytes of data to [address + 3 : address]
  task automatic write_word(
    input  UsbAddr_t   address,
    input  CwRegWord_t data,
    ref    UsbBus_t    usb
  );
    begin
      for (int unsigned subbyte = 0; subbyte < CW_REG_DATA_WIDTH_BYTES; subbyte++) begin
        write_byte(
          address + UsbAddr_t'(subbyte),
          data[subbyte],
          usb
        );
      end
      if (VERBOSE) begin
        $display("[%16t ns] TB", $realtime/1ns,
                  "\n\t\tNAME: %s ", regaddr2name(address),
                  "\n\t\tADDR: 0x%H", address,
                  "\n\t\tDATA: 0x%H", data
                );
      end
    end
  endtask : write_word

  // read 4 Bytes of data from [address + 3 : address]
  task automatic read_word (
    input  UsbAddr_t   address,
    output CwRegWord_t data,
    ref    UsbBus_t    usb
  );
    begin
      for (int unsigned subbyte = 0; subbyte < CW_REG_DATA_WIDTH_BYTES; subbyte++) begin
        read_byte(
          address + UsbAddr_t'(subbyte),
          data[subbyte],
          usb
        );
      end
      if (VERBOSE)
        $display("[%16t ns] TB", $realtime/1ns,
                  "\n\t\tNAME: %s ", regaddr2name(address),
                  "\n\t\tADDR: 0x%H ", address,
                  "\n\t\tDATA: 0x%0H", data
                );
    end
  endtask : read_word

  // execute an instruction to read/write ABR registers to/from DBUFF
  task automatic exec_instr (
    input  AbrInstr_t  abr_instr,
    ref    UsbBus_t    usb
  );
    begin
      CwRegWord_t tmp_data;

      $display("\n[%16t ns] TB : Executing instruction:", $realtime/1ns,
               "\n\t ADDR     : 0x%4X", abr_instr.addr,
               "\n\t LEN_WRDS :  0x%3X", abr_instr.len_wrds,
               "\n\t OP_CODE  :    0x%1X", abr_instr.op_code,
      );

      // write instruction to instr reg
      write_word(CW310_ADDR_ABR_INSTR, CwRegWord_t'(abr_instr), usb);
      
      // initiate instruction execution using read/modify/write
      read_word(CW310_ADDR_DUT_CTRL1, tmp_data, usb);
      tmp_data[0][0] = 1'b1;
      write_word(CW310_ADDR_DUT_CTRL1, tmp_data, usb);

      // wait for transfer busy flag to clear and check for errors
      while(1) begin
        read_word(CW310_ADDR_DUT_STAT1, tmp_data, usb);
        // end sim if error is detected
        if (tmp_data[0][1]) begin
          $error("[%16t ns] TB : Transfer error bit set!", $realtime/1ns);
          $finish;
        end
        if (!tmp_data[0][0])
          break;
      end

      // clear instruction initiate register using read/modify/write
      read_word(CW310_ADDR_DUT_CTRL1, tmp_data, usb);
      tmp_data[0][0] = 1'b0;
      write_word(CW310_ADDR_DUT_CTRL1, tmp_data, usb);

    end
  endtask : exec_instr

  // ------------------------------------------------------------------------
  // Tasks to perform functions using tasks above
  // ------------------------------------------------------------------------

  // place DUT in reset
  task automatic dut_assert_reset (   
    ref    UsbBus_t    usb
  );
    begin

      CwRegWord_t tmp_data;

      $display("\n[%16t ns] TB : Clearing DUT_nRST...", $realtime/1ns);

      // read register
      read_word(CW310_ADDR_DUT_CTRL0, tmp_data, usb);
      // clear DUT_nRST bit
      tmp_data[0][0] = 1'b0;
      // write back data to register
      write_word(CW310_ADDR_DUT_CTRL0, tmp_data, usb);

      // verify design is in reset
      $display("[%16t ns] TB : Waiting for reset status to confirm...", $realtime/1ns);

      while(1) begin
        read_word(CW310_ADDR_DUT_STAT0, tmp_data, usb);
        if (!tmp_data[0][0])
          break;
      end

      $display("[%16t ns] TB : DUT in reset!", $realtime/1ns);

    end
      
  endtask : dut_assert_reset

  // take DUT out of reset
  task automatic dut_deassert_reset (   
    ref    UsbBus_t    usb
  );
    begin

      CwRegWord_t tmp_data;

      $display("\n[%16t ns] TB : Setting DUT_nRST...", $realtime/1ns);

      // read register
      read_word(CW310_ADDR_DUT_CTRL0, tmp_data, usb);
      // set DUT_nRST bit
      tmp_data[0][0] = 1'b1;
      // write back data to register
      write_word(CW310_ADDR_DUT_CTRL0, tmp_data, usb);

      // verify design is not in reset
      $display("[%16t ns] TB : Waiting for reset status to confirm...", $realtime/1ns);

      while(1) begin
        read_word(CW310_ADDR_DUT_STAT0, tmp_data, usb);
        if (tmp_data[0][0])
          break;
      end

      $display("[%16t ns] TB : DUT in reset!", $realtime/1ns);

    end
      
  endtask : dut_deassert_reset


endpackage : tb_cw310_pkg
