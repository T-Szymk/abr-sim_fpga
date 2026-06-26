
// Directory holding the expected-value .mem vectors (generated from
// flow/mlkem-gen.py with zero seeds/msg). Normally set by the Makefile to an
// absolute path; the fallback is relative to the Verilator run dir .sim_build.
`ifndef VECTOR_DIR
  `define VECTOR_DIR "../tb/vectors"
`endif

module tb_abr_fpga;

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

  initial begin

    CwRegWord_t mlkem_seed_d  [];
    CwRegWord_t mlkem_seed_z  [];
    CwRegWord_t mlkem_entropy [];
    CwRegWord_t mlkem_ek      [];
    CwRegWord_t mlkem_dk      [];
    CwRegWord_t mlkem_msg     [];
    CwRegWord_t mlkem_ct      [];
    CwRegWord_t mlkem_ss_enc  [];
    CwRegWord_t mlkem_ss_dec  [];

    // expected values from flow/mlkem-gen.py ($readmemh targets + dynamic
    // copies for check_words, as $readmemh cannot target dynamic arrays)
    CwRegWord_t exp_ek_mem [0:unsigned'(ABR_WRDS_MLKEM_ENCAPS_KEY)-1];
    CwRegWord_t exp_dk_mem [0:unsigned'(ABR_WRDS_MLKEM_DECAPS_KEY)-1];
    CwRegWord_t exp_ct_mem [0:unsigned'(ABR_WRDS_MLKEM_CIPHERTEXT)-1];
    CwRegWord_t exp_ss_mem [0:unsigned'(ABR_WRDS_MLKEM_SHARED_KEY)-1];
    CwRegWord_t exp_ek     [];
    CwRegWord_t exp_dk     [];
    CwRegWord_t exp_ct     [];
    CwRegWord_t exp_ss     [];

    automatic int unsigned kat_errors = 0;

    $display("[%16t ns] TB : Starting tb_abr_fpga testbench", $realtime/1ns);

    // initialise signals
    usb_clk_enable = 1'b1;
    usb.wdata      = 0;
    usb.addr       = 0;
    usb.rdn        = 1;
    usb.wrn        = 1;
    usb.cen        = 1;

    #TB_RESET_DURATION;
    #(USB_CLK_PERIOD*10);

    // lift DUT from reset
    dut_deassert_reset(usb);

    // wait for mldsa ready to be asserted
    dut_mldsa_wait_for_ready(usb);

    // wait for mlkwm ready to be asserted
    dut_mlkem_wait_for_ready(usb);

    // read name and version for both DSA and KEM
    dut_verify_meta(usb);

    // run ML-KEM keygen with all-zero seeds/entropy (matches the defaults of
    // flow/mlkem-gen.py, so outputs are deterministic for a later KAT check)
    mlkem_seed_d  = new[unsigned'(ABR_WRDS_MLKEM_SEED_D)];
    mlkem_seed_z  = new[unsigned'(ABR_WRDS_MLKEM_SEED_Z)];
    mlkem_entropy = new[unsigned'(ABR_WRDS_ENTROPY)];
    foreach (mlkem_seed_d[i])  mlkem_seed_d[i]  = '0;
    foreach (mlkem_seed_z[i])  mlkem_seed_z[i]  = '0;
    foreach (mlkem_entropy[i]) mlkem_entropy[i] = '0;

    dut_mlkem_keygen(mlkem_seed_d, mlkem_seed_z, mlkem_entropy, mlkem_ek, mlkem_dk, usb);

    // sanity check that keys read back non-zero
    begin
      automatic bit ek_nonzero = 1'b0;
      automatic bit dk_nonzero = 1'b0;
      foreach (mlkem_ek[i]) if (mlkem_ek[i] != '0) ek_nonzero = 1'b1;
      foreach (mlkem_dk[i]) if (mlkem_dk[i] != '0) dk_nonzero = 1'b1;
      a_kem_ek_nonzero : assert (ek_nonzero) else
        $error("[%16t ns] TB : ML-KEM EK read back all zeros!", $realtime/1ns);
      a_kem_dk_nonzero : assert (dk_nonzero) else
        $error("[%16t ns] TB : ML-KEM DK read back all zeros!", $realtime/1ns);
    end

    // KAT: compare keygen outputs against the FIPS 203 reference model
    $display("\n[%16t ns] TB : Checking ML-KEM keygen outputs against reference vectors", $realtime/1ns);
    $readmemh({`VECTOR_DIR, "/mlkem_ek_exp.mem"}, exp_ek_mem);
    $readmemh({`VECTOR_DIR, "/mlkem_dk_exp.mem"}, exp_dk_mem);
    exp_ek = new[$size(exp_ek_mem)];
    exp_dk = new[$size(exp_dk_mem)];
    foreach (exp_ek_mem[i]) exp_ek[i] = exp_ek_mem[i];
    foreach (exp_dk_mem[i]) exp_dk[i] = exp_dk_mem[i];
    kat_errors += check_words("MLKEM_EK", mlkem_ek, exp_ek);
    kat_errors += check_words("MLKEM_DK", mlkem_dk, exp_dk);

    // run ML-KEM encaps with all-zero msg (matches flow/mlkem-gen.py default)
    // and the encaps key read back from keygen
    mlkem_msg = new[unsigned'(ABR_WRDS_MLKEM_MSG)];
    foreach (mlkem_msg[i]) mlkem_msg[i] = '0;

    dut_mlkem_encaps(mlkem_msg, mlkem_ek, mlkem_entropy, mlkem_ct, mlkem_ss_enc, usb);

    // KAT: compare encaps outputs against the FIPS 203 reference model
    $display("\n[%16t ns] TB : Checking ML-KEM encaps outputs against reference vectors", $realtime/1ns);
    $readmemh({`VECTOR_DIR, "/mlkem_ct_exp.mem"}, exp_ct_mem);
    $readmemh({`VECTOR_DIR, "/mlkem_ss_exp.mem"}, exp_ss_mem);
    exp_ct = new[$size(exp_ct_mem)];
    exp_ss = new[$size(exp_ss_mem)];
    foreach (exp_ct_mem[i]) exp_ct[i] = exp_ct_mem[i];
    foreach (exp_ss_mem[i]) exp_ss[i] = exp_ss_mem[i];
    kat_errors += check_words("MLKEM_CT", mlkem_ct, exp_ct);
    kat_errors += check_words("MLKEM_SS_ENC", mlkem_ss_enc, exp_ss);

    // run ML-KEM decaps with the decaps key from keygen and the ciphertext
    // from encaps to close the round-trip
    dut_mlkem_decaps(mlkem_dk, mlkem_ct, mlkem_entropy, mlkem_ss_dec, usb);

    // KAT + round-trip: decaps shared key must match reference and encaps
    $display("\n[%16t ns] TB : Checking ML-KEM decaps output against reference vectors", $realtime/1ns);
    kat_errors += check_words("MLKEM_SS_DEC", mlkem_ss_dec, exp_ss);

    a_kem_ss_match : assert (mlkem_ss_enc == mlkem_ss_dec) else
      $error("[%16t ns] TB : ML-KEM encaps/decaps shared keys do not match!", $realtime/1ns);

    a_kem_kat : assert (kat_errors == 0) else
      $error("[%16t ns] TB : ML-KEM KAT failed with %0d word mismatches!", $realtime/1ns, kat_errors);

    if (kat_errors == 0 && mlkem_ss_enc == mlkem_ss_dec) begin
      $display("\n[%16t ns] TB : ML-KEM keygen/encaps/decaps KAT + round-trip PASSED!", $realtime/1ns);
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


endmodule : tb_abr_fpga
