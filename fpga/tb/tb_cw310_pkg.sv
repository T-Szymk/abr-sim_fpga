
package tb_cw310_pkg;

  import abr_fpga_pkg::*;
  import abr_reg_pkg::*;
  import abr_params_pkg::*;

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

  localparam int unsigned InstrAddrLen = 16;
  localparam int unsigned InstrWrdsLen = 12;
  localparam int unsigned InstrOpCdLen =  4;

  typedef logic [InstrAddrLen-1:0] InstrAddr_t; 
  typedef logic [InstrWrdsLen-1:0] InstrWrds_t; 
  typedef logic [InstrOpCdLen-1:0] InstrOpCd_t; 

  typedef enum InstrOpCd_t {
    OP_READ  = 'h0,
    OP_WRITE = 'h1
  } InstrOp_e;

  // ABR instruction
  typedef struct packed {
    InstrAddr_t addr;
    InstrWrds_t len_wrds;
    InstrOpCd_t op_code;
  } AbrInstr_t;

  // ------------------------------------------------------------------------
  // ABR register map (AHB byte addresses + sizes in 32b words)
  // Source: adams-bridge/src/abr_top/rtl/abr_reg.rdl
  // ------------------------------------------------------------------------

  // ML-DSA registers
  parameter InstrAddr_t ABR_ADDR_MLDSA_NAME        = InstrAddr_t'('h0000);
  parameter InstrAddr_t ABR_ADDR_MLDSA_VERSION     = InstrAddr_t'('h0008);
  parameter InstrAddr_t ABR_ADDR_MLDSA_CTRL        = InstrAddr_t'('h0010);
  parameter InstrAddr_t ABR_ADDR_MLDSA_STATUS      = InstrAddr_t'('h0014);
  parameter InstrAddr_t ABR_ADDR_ENTROPY           = InstrAddr_t'('h0018);
  parameter InstrAddr_t ABR_ADDR_MLDSA_SEED        = InstrAddr_t'('h0058);
  parameter InstrAddr_t ABR_ADDR_MLDSA_SIGN_RND    = InstrAddr_t'('h0078);
  parameter InstrAddr_t ABR_ADDR_MLDSA_MSG         = InstrAddr_t'('h0098);
  parameter InstrAddr_t ABR_ADDR_MLDSA_VERIFY_RES  = InstrAddr_t'('h00D8);
  parameter InstrAddr_t ABR_ADDR_MLDSA_EXTERNAL_MU = InstrAddr_t'('h0118);
  parameter InstrAddr_t ABR_ADDR_MLDSA_MSG_STROBE  = InstrAddr_t'('h0158);
  parameter InstrAddr_t ABR_ADDR_MLDSA_CTX_CONFIG  = InstrAddr_t'('h015C);
  parameter InstrAddr_t ABR_ADDR_MLDSA_CTX         = InstrAddr_t'('h0160);
  parameter InstrAddr_t ABR_ADDR_MLDSA_PUBKEY      = InstrAddr_t'('h1000);
  parameter InstrAddr_t ABR_ADDR_MLDSA_SIGNATURE   = InstrAddr_t'('h2000);
  parameter InstrAddr_t ABR_ADDR_MLDSA_PRIVKEY_OUT = InstrAddr_t'('h4000);
  parameter InstrAddr_t ABR_ADDR_MLDSA_PRIVKEY_IN  = InstrAddr_t'('h6000);

  // ML-KEM registers
  parameter InstrAddr_t ABR_ADDR_MLKEM_NAME        = InstrAddr_t'('h9000);
  parameter InstrAddr_t ABR_ADDR_MLKEM_VERSION     = InstrAddr_t'('h9008);
  parameter InstrAddr_t ABR_ADDR_MLKEM_CTRL        = InstrAddr_t'('h9010);
  parameter InstrAddr_t ABR_ADDR_MLKEM_STATUS      = InstrAddr_t'('h9014);
  parameter InstrAddr_t ABR_ADDR_MLKEM_SEED_D      = InstrAddr_t'('h9018);
  parameter InstrAddr_t ABR_ADDR_MLKEM_SEED_Z      = InstrAddr_t'('h9038);
  parameter InstrAddr_t ABR_ADDR_MLKEM_SHARED_KEY  = InstrAddr_t'('h9058);
  parameter InstrAddr_t ABR_ADDR_MLKEM_MSG         = InstrAddr_t'('h9080);
  parameter InstrAddr_t ABR_ADDR_MLKEM_DECAPS_KEY  = InstrAddr_t'('hA000);
  parameter InstrAddr_t ABR_ADDR_MLKEM_ENCAPS_KEY  = InstrAddr_t'('hB000);
  parameter InstrAddr_t ABR_ADDR_MLKEM_CIPHERTEXT  = InstrAddr_t'('hB800);

  // ML-DSA register sizes in 32b words
  parameter InstrWrds_t ABR_WRDS_MLDSA_NAME        = InstrWrds_t'('d2);
  parameter InstrWrds_t ABR_WRDS_MLDSA_VERSION     = InstrWrds_t'('d2);
  parameter InstrWrds_t ABR_WRDS_MLDSA_CTRL        = InstrWrds_t'('d1);
  parameter InstrWrds_t ABR_WRDS_MLDSA_STATUS      = InstrWrds_t'('d1);
  parameter InstrWrds_t ABR_WRDS_ENTROPY           = InstrWrds_t'('d16);
  parameter InstrWrds_t ABR_WRDS_MLDSA_SEED        = InstrWrds_t'('d8);
  parameter InstrWrds_t ABR_WRDS_MLDSA_SIGN_RND    = InstrWrds_t'('d8);
  parameter InstrWrds_t ABR_WRDS_MLDSA_MSG         = InstrWrds_t'('d16);
  parameter InstrWrds_t ABR_WRDS_MLDSA_VERIFY_RES  = InstrWrds_t'('d16);
  parameter InstrWrds_t ABR_WRDS_MLDSA_EXTERNAL_MU = InstrWrds_t'('d16);
  parameter InstrWrds_t ABR_WRDS_MLDSA_MSG_STROBE  = InstrWrds_t'('d1);
  parameter InstrWrds_t ABR_WRDS_MLDSA_CTX_CONFIG  = InstrWrds_t'('d1);
  parameter InstrWrds_t ABR_WRDS_MLDSA_CTX         = InstrWrds_t'('d64);
  parameter InstrWrds_t ABR_WRDS_MLDSA_PUBKEY      = InstrWrds_t'('d648);
  parameter InstrWrds_t ABR_WRDS_MLDSA_SIGNATURE   = InstrWrds_t'('d1157);
  parameter InstrWrds_t ABR_WRDS_MLDSA_PRIVKEY_OUT = InstrWrds_t'('d1224);
  parameter InstrWrds_t ABR_WRDS_MLDSA_PRIVKEY_IN  = InstrWrds_t'('d1224);

  // ML-KEM register sizes in 32b words
  parameter InstrWrds_t ABR_WRDS_MLKEM_NAME        = InstrWrds_t'('d2);
  parameter InstrWrds_t ABR_WRDS_MLKEM_VERSION     = InstrWrds_t'('d2);
  parameter InstrWrds_t ABR_WRDS_MLKEM_CTRL        = InstrWrds_t'('d1);
  parameter InstrWrds_t ABR_WRDS_MLKEM_STATUS      = InstrWrds_t'('d1);
  parameter InstrWrds_t ABR_WRDS_MLKEM_SEED_D      = InstrWrds_t'('d8);
  parameter InstrWrds_t ABR_WRDS_MLKEM_SEED_Z      = InstrWrds_t'('d8);
  parameter InstrWrds_t ABR_WRDS_MLKEM_SHARED_KEY  = InstrWrds_t'('d8);
  parameter InstrWrds_t ABR_WRDS_MLKEM_MSG         = InstrWrds_t'('d8);
  parameter InstrWrds_t ABR_WRDS_MLKEM_DECAPS_KEY  = InstrWrds_t'('d792);
  parameter InstrWrds_t ABR_WRDS_MLKEM_ENCAPS_KEY  = InstrWrds_t'('d392);
  parameter InstrWrds_t ABR_WRDS_MLKEM_CIPHERTEXT  = InstrWrds_t'('d392);

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
      if (VERBOSE) begin
        $display("[%16t ns] TB", $realtime/1ns,
                  "\n\t\tNAME: %s ", regaddr2name(address),
                  "\n\t\tADDR: 0x%H ", address,
                  "\n\t\tDATA: 0x%0H", data
                );
      end
    end
  endtask : read_word

  // execute an instruction to read/write ABR registers to/from DBUFF
  task automatic exec_instr (
    input  AbrInstr_t  abr_instr,
    ref    UsbBus_t    usb
  );
    begin
      CwRegWord_t tmp_data;

      if (VERBOSE) begin
        $display("\n[%16t ns] TB : Executing instruction:", $realtime/1ns,
                 "\n\t ADDR     : 0x%4X", abr_instr.addr,
                 "\n\t LEN_WRDS :  0x%3X", abr_instr.len_wrds,
                 "\n\t OP_CODE  :    0x%1X", abr_instr.op_code,
        );
      end

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
          $display("[%16t ns] TB : CW310_ADDR_DUT_STAT1 0x%H: ", $realtime/1ns, tmp_data);
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

  // Wait for ABR to report ML-DSA ready
  task automatic dut_mldsa_wait_for_ready (   
    ref    UsbBus_t    usb
  );
    begin

      AbrInstr_t  abr_instr;
      CwRegWord_t tmp_data;

      $display("\n[%16t ns] TB : Waiting for ABR ML-DSA to report ready...", $realtime/1ns);

      // READ ABR MLDSA_STATUS register via data buffer
      abr_instr.addr     = ABR_ADDR_MLDSA_STATUS;
      abr_instr.len_wrds = ABR_WRDS_MLDSA_STATUS;
      abr_instr.op_code  = OP_READ;

      while(1) begin

        // execute instr
        exec_instr(abr_instr, usb);
        // read data buffer
        read_word(CW310_ADDR_ABR_DBUFF_BASE, tmp_data, usb);
        if (tmp_data[0][0])
          break;
      end


      $display("[%16t ns] TB : ABR MLDSA ready!", $realtime/1ns);
      $display("\t\tMLDSA_STATUS : 0x%H", tmp_data);

    end
      
  endtask : dut_mldsa_wait_for_ready

  // Wait for ABR to report ML-KEM ready
  task automatic dut_mlkem_wait_for_ready (   
    ref    UsbBus_t    usb
  );
    begin

      AbrInstr_t  abr_instr;
      CwRegWord_t tmp_data;

      $display("\n[%16t ns] TB : Waiting for ABR ML-KEM to report ready...", $realtime/1ns);

      // READ ABR MLKEM_STATUS register via data buffer
      abr_instr.addr     = ABR_ADDR_MLKEM_STATUS;
      abr_instr.len_wrds = ABR_WRDS_MLKEM_STATUS;
      abr_instr.op_code  = OP_READ;

      while(1) begin

        // execute instr
        exec_instr(abr_instr, usb);
        // read data buffer
        read_word(CW310_ADDR_ABR_DBUFF_BASE, tmp_data, usb);
        if (tmp_data[0][0])
          break;
      end


      $display("[%16t ns] TB : ABR MLKEM ready!", $realtime/1ns);
      $display("\t\tMLKEM_STATUS : 0x%H", tmp_data);

    end
      
  endtask : dut_mlkem_wait_for_ready


  // Verify name and version of accelerator ML-DSA core
  task automatic dut_mldsa_verify_meta (   
    ref    UsbBus_t    usb
  );
    begin

      CwRegWord_t [unsigned'(ABR_WRDS_MLDSA_NAME)-1:0]    tmp_name;
      CwRegWord_t [unsigned'(ABR_WRDS_MLDSA_VERSION)-1:0] tmp_vers;
      AbrInstr_t                                          abr_instr;

      $display("\n[%16t ns] TB : Verifying ML-DSA metadata", $realtime/1ns);

      // READ ABR MLDSA_NAME register via data buffer
      abr_instr.addr     = ABR_ADDR_MLDSA_NAME;
      abr_instr.len_wrds = ABR_WRDS_MLDSA_NAME;
      abr_instr.op_code  = OP_READ;

      // execute instr
      exec_instr(abr_instr, usb);

      for (int unsigned word = 0; word < unsigned'(ABR_WRDS_MLDSA_NAME); word++) begin
        // read data buffer
        UsbAddr_t tmp_addr = UsbAddr_t'(CW310_ADDR_ABR_DBUFF_BASE + (word * CW_REG_DATA_WIDTH_BYTES));
        read_word(tmp_addr, tmp_name[word], usb);
      end

      // READ ABR MLDSA_VERSION register via data buffer
      abr_instr.addr     = ABR_ADDR_MLDSA_VERSION;
      abr_instr.len_wrds = ABR_WRDS_MLDSA_VERSION;
      abr_instr.op_code  = OP_READ;

      // execute instr
      exec_instr(abr_instr, usb);

      for (int unsigned word = 0; word < unsigned'(ABR_WRDS_MLDSA_VERSION); word++) begin
        // read data buffer
        UsbAddr_t tmp_addr = UsbAddr_t'(CW310_ADDR_ABR_DBUFF_BASE + (word * CW_REG_DATA_WIDTH_BYTES));
        read_word(tmp_addr, tmp_vers[word], usb);

      end

      $display("[%16t ns] TB : Read ML-DSA metadata:", $realtime/1ns);
      $display("\t\tMLDSA_NAME    : 0x%H", tmp_name);
      $display("\t\tMLDSA_VERSION : 0x%H", tmp_vers);

    end
      
  endtask : dut_mldsa_verify_meta

  // Verify name and version of accelerator ML-KEM core
  task automatic dut_mlkem_verify_meta (   
    ref    UsbBus_t    usb
  );
    begin

      CwRegWord_t [unsigned'(ABR_WRDS_MLKEM_NAME)-1:0]    tmp_name;
      CwRegWord_t [unsigned'(ABR_WRDS_MLKEM_VERSION)-1:0] tmp_vers;
      AbrInstr_t                                          abr_instr;

      $display("\n[%16t ns] TB : Verifying ML-KEM metadata", $realtime/1ns);

      // READ ABR MLKEM_NAME register via data buffer
      abr_instr.addr     = ABR_ADDR_MLKEM_NAME;
      abr_instr.len_wrds = ABR_WRDS_MLKEM_NAME;
      abr_instr.op_code  = OP_READ;

      // execute instr
      exec_instr(abr_instr, usb);

      for (int unsigned word = 0; word < unsigned'(ABR_WRDS_MLKEM_NAME); word++) begin
        // read data buffer
        UsbAddr_t tmp_addr = UsbAddr_t'(CW310_ADDR_ABR_DBUFF_BASE + (word * CW_REG_DATA_WIDTH_BYTES));
        read_word(tmp_addr, tmp_name[word], usb);
      end

      // READ ABR MLKEM_VERSION register via data buffer
      abr_instr.addr     = ABR_ADDR_MLKEM_VERSION;
      abr_instr.len_wrds = ABR_WRDS_MLKEM_VERSION;
      abr_instr.op_code  = OP_READ;

      // execute instr
      exec_instr(abr_instr, usb);

      for (int unsigned word = 0; word < unsigned'(ABR_WRDS_MLKEM_VERSION); word++) begin
        // read data buffer
        UsbAddr_t tmp_addr = UsbAddr_t'(CW310_ADDR_ABR_DBUFF_BASE + (word * CW_REG_DATA_WIDTH_BYTES));
        read_word(tmp_addr, tmp_vers[word], usb);

      end

      $display("[%16t ns] TB : Read ML-KEM metadata:", $realtime/1ns);
      $display("\t\tMLKEM_NAME    : 0x%H", tmp_name);
      $display("\t\tMLKEM_VERSION : 0x%H", tmp_vers);

    end
      
  endtask : dut_mlkem_verify_meta

  // Verify name and version of accelerator ML-KEM core
  task automatic dut_verify_meta (   
    ref    UsbBus_t    usb
  );
    begin
      dut_mldsa_verify_meta(usb);
      dut_mlkem_verify_meta(usb);
    end

  endtask : dut_verify_meta

endpackage : tb_cw310_pkg
