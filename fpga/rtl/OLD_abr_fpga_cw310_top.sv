// abr_fpga_cw310_top.vs - Top-level module for the ABR FPGA CW310 design

(* DONT_TOUCH = "yes" *)
module abr_fpga_cw310_top 
  import abr_fpga_pkg::*; 
#(
  parameter integer unsigned pBYTECNT_SIZE =   7,
  parameter integer unsigned pADDR_WIDTH   =  20,
  parameter integer unsigned pPT_WIDTH     = 128,
  parameter integer unsigned pCT_WIDTH     = 128,
  parameter integer unsigned pKEY_WIDTH    = 128
) (
  input  wire                   PLL_CLK_1,   // clk
  output wire                   CWIO_HS1,    // output clock for scope triggering    
  input  wire                   CWIO_HS2,

  input  wire                   USRDIP0,        // DIP switch 0
  input  wire                   USRDIP1,        // DIP switch 1
  input  wire                   USRSW0,         // active-low reset
  output wire [            5:0] USRLED,         // user LEDs
  output wire                   CWIO_IO4,       // IO used for trigger  
  // USB Interface
  input  wire                   usb_clk,        // Clock
  inout  wire [            7:0] USB_D,          // Data for write/read
  input  wire [pADDR_WIDTH-1:0] USB_A,          // Address
  input  wire                   USB_nRD,        // !RD, low when addr valid for read
  input  wire                   USB_nWR,        // !WR, low when data+addr valid for write
  input  wire                   USB_nCE,        // !CE, active low chip enable
  input  wire                   usb_trigger     // High when trigger requested

);

  timeunit 1ns/1ps;

  `ifndef ABR_OP
    `define ABR_OP OP_KGSIGN
  `endif

  localparam integer unsigned ResetSyncStages = 3;
  localparam op_e             Operation       = `ABR_OP;
  localparam integer unsigned ResetCycles     = 16; 

  // Internal signal for reset
  logic reset_ext;
  logic reset_int;
  logic rst_n;
  logic clk_int;

  logic ext_trigger;
  logic reg_usr_led;

  (* DONT_TOUCH = "yes" *) logic done_d, done_q;
  (* DONT_TOUCH = "yes" *) logic error_d, error_q;
  (* DONT_TOUCH = "yes" *) logic busy_d, busy_q;
  (* DONT_TOUCH = "yes" *) logic error_intr_d, error_intr_q;
  (* DONT_TOUCH = "yes" *) logic notif_intr_d, notif_intr_q;

  // Debug counter for LED toggling
  logic [25:0] debug_counter;

  logic [ResetSyncStages-1:0] resetn_sync_ff;

  // Generate active-high reset signal
  assign reset_ext = ~USRSW0;
  
  assign USRLED[0] = reset_int;         // Drive LED with PLL lock for debugging
  assign USRLED[1] = debug_counter[25]; // Toggle LED at ~1Hz
  assign USRLED[2] = done_q;            // Drive LED with done status for debugging
  assign USRLED[3] = error_q;           // Drive LED with error status for debugging
  assign USRLED[4] = busy_q;            // Drive LED with busy status for debugging
  assign USRLED[5] = reg_usr_led;       // LED controlled by register for testing
  
  assign rst_n     = resetn_sync_ff[ResetSyncStages-1];
  assign CWIO_IO4  = busy_q;            // Trigger output for scope (goes high when busy)
  
  ip_top_clk top_clk (
    .clk_in1  ( PLL_CLK_1  ), // input  external clock in
    .clk_out  ( clk_int ), // output clk_out
    .reset    ( reset_ext  ), // input  reset
    .clk_lock ( reset_int  )  // output clk_lock    
  );

  // n-stage reset synchronizer
  always_ff @(posedge clk_int or posedge reset_ext) begin
    if (reset_ext) begin
      resetn_sync_ff <= '0; // Set all stages to 0 on reset
    end else begin
      resetn_sync_ff <= {resetn_sync_ff[ResetSyncStages-2:0], reset_int}; // Shift in the async reset
    end
  end

  // instantiate the design
  abr_fpga_top #(  
    .OPERATION     ( Operation   ),
    .RESET_CYCLES  ( ResetCycles )
  ) i_abr_fpga_top (
    .clk_i         ( clk_int     ),
    .rst_ni        ( rst_n       ),      // active-low board/PLL reset

`ifdef RV_FPGA_SCA   // Warning: This doesn't work right now...
    .NTT_trigger   ( /* NC */    ),
    .PWM_trigger   ( /* NC */    ),
    .PWA_trigger   ( /* NC */    ),
    .INTT_trigger  ( /* NC */    ),
`endif

    .ext_trigger_i ( ext_trigger ), // e.g. external trigger to start the operation; usage depends on the platform

    .done_o        ( done_d      ), // pulses high for one cycle when operation completes
    .error_o       ( error_d     ), // asserted and held on STATUS error

    // abr_top status pass-through
    .busy_o        ( busy_d       ),
    .error_intr_o  ( error_intr_d ),
    .notif_intr_o  ( notif_intr_d )
  );


  // register status signals from abr_top
  always_ff @(posedge clk_int or negedge rst_n) begin
    if (!rst_n) begin
      done_q        <= 1'b0;
      error_q       <= 1'b0;
      busy_q        <= 1'b0;
      error_intr_q  <= 1'b0;
      notif_intr_q  <= 1'b0;
    end else begin
      // latch status signal
      if (done_d) begin
        done_q <= 1'b1;
      end
      
      if (error_d) begin
        error_q <= 1'b1;
      end

      busy_q        <= busy_d;

      error_intr_q  <= error_intr_d;
      notif_intr_q  <= notif_intr_d;
    end
  end

  
  always_ff @(posedge clk_int or negedge rst_n) begin
    if (!rst_n) begin
      debug_counter <= 0;
    end else begin
      debug_counter <= debug_counter + 1;
    end
  end

/******************************************************************************/
/* CW LOGIC INSTANCES                                                         */
/******************************************************************************/

  logic       usb_reset;
  logic       usb_clk_buf;
  logic       isout;
  logic [7:0] usb_dout;

  logic [pADDR_WIDTH-pBYTECNT_SIZE-1:0] reg_address;
  logic [            pBYTECNT_SIZE-1:0] reg_bytecnt;
  logic                                 reg_addrvalid;
  logic [                          7:0] write_data;
  logic [                          7:0] read_data;
  logic                                 reg_read;
  logic                                 reg_write;
  logic [                          4:0] clk_settings;
  logic                                 crypt_clk;
  logic                                 crypt_ready;
  logic                                 crypt_done;

  assign usb_reset    = !reset_int; // Use inverted synchronized reset for USB logic
  assign USB_D        = isout? usb_dout : 8'bZ;
  assign clk_settings = '0; // Use DIP switches for clock settings
  assign crypt_ready  = 1'b1; // Tie ready high for now
  assign crypt_done   = !busy_q; // Done when not busy

  cw310_usb_reg_fe #(
    .pBYTECNT_SIZE           ( pBYTECNT_SIZE    ),
    .pADDR_WIDTH             ( pADDR_WIDTH      )
  ) i_cw_usb_reg_fe (
    .rst                     ( usb_reset        ),
    .usb_clk                 ( usb_clk_buf      ), 
    .usb_din                 ( USB_D            ), 
    .usb_dout                ( usb_dout         ), 
    .usb_rdn                 ( USB_nRD          ), 
    .usb_wrn                 ( USB_nWR          ),
    .usb_cen                 ( USB_nCE          ),
    .usb_alen                ( 1'b0             ),
    .usb_addr                ( USB_A            ),
    .usb_isout               ( isout            ), 
    .reg_address             ( reg_address      ), 
    .reg_bytecnt             ( reg_bytecnt      ), 
    .reg_datao               ( write_data       ), 
    .reg_datai               ( read_data        ),
    .reg_read                ( reg_read         ), 
    .reg_write               ( reg_write        ), 
    .reg_addrvalid           ( reg_addrvalid    )
  );

  cw310_reg_aes #(
       .pBYTECNT_SIZE        ( pBYTECNT_SIZE ),
       .pADDR_WIDTH          ( pADDR_WIDTH   ),
       .pPT_WIDTH            ( pPT_WIDTH     ),
       .pCT_WIDTH            ( pCT_WIDTH     ),
       .pKEY_WIDTH           ( pKEY_WIDTH    )
  ) i_cw_reg_abr (
       .reset_i              ( usb_reset                                  ),
       .crypto_clk           ( crypt_clk                                  ),
       .usb_clk              ( usb_clk_buf                                ), 
       .reg_address          ( reg_address[pADDR_WIDTH-pBYTECNT_SIZE-1:0] ), 
       .reg_bytecnt          ( reg_bytecnt                                ), 
       .read_data            ( read_data                                  ), 
       .write_data           ( write_data                                 ),
       .reg_read             ( reg_read                                   ), 
       .reg_write            ( reg_write                                  ), 
       .reg_addrvalid        ( reg_addrvalid                              ),

       .exttrigger_in        ( usb_trigger                                ),

       .I_textout            ( '0                                         ),               // unused
       .I_cipherout          ( '0                                         ),
       .I_ready              ( crypt_ready                                ),
       .I_done               ( crypt_done                                 ),
       .I_busy               ( busy_q                                     ),
       .O_clksettings        ( /* NC */                                   ),
       .O_user_led           ( reg_usr_led                                ),
       .O_key                ( /* NC */                                   ),
       .O_textin             ( /* NC */                                   ),
       .O_cipherin           ( /* NC */                                   ),                     // unused
       .O_start              ( ext_trigger                                )
    );   

    clocks i_cw_clocks (
       .usb_clk              ( usb_clk      ),
       .usb_clk_buf          ( usb_clk_buf  ),
       .I_j16_sel            ( USRDIP0      ),
       .I_k16_sel            ( USRDIP1      ),
       .I_clock_reg          ( clk_settings ),
       .I_cw_clkin           ( '0           ), // unused, we only use top_clk
       .I_pll_clk1           ( clk_int      ),
       .O_cw_clkout          ( CWIO_HS1     ),
       .O_cryptoclk          ( crypt_clk    )
    );

endmodule
