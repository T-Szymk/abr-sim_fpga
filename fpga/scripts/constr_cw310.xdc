# ------------------------------------------------------------------------------
# constr_cw310.xdc
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 25-may-2026
#
# Description: Constraints file for main abr_fpga project on the cw310 board
# ------------------------------------------------------------------------------

##################################################################
# _____   _    _ __     __ _____  _____  _____            _      #
#|  __ \ | |  | |\ \   / // ____||_   _|/ ____|    /\    | |     #
#| |__) || |__| | \ \_/ /| (___    | | | |        /  \   | |     #
#|  ___/ |  __  |  \   /  \___ \   | | | |       / /\ \  | |     #
#| |     | |  | |   | |   ____) | _| |_| |____  / ____ \ | |____ #
#|_|     |_|  |_|   |_|  |_____/ |_____|\_____|/_/    \_\|______|#
#                                                                #
##################################################################

set_property -dict { PACKAGE_PIN  R22 IOSTANDARD   LVCMOS33  } [get_ports { PLL_CLK_1 }];
set_property -dict { PACKAGE_PIN AB21  IOSTANDARD  LVCMOS33  } [get_ports { CWIO_HS1  }]; #IO_L18P_T2_12
set_property -dict { PACKAGE_PIN  Y22  IOSTANDARD   LVCMOS33 } [get_ports { CWIO_HS2  }]; #IO_L13P_T2_MRCC_12

set_property -dict { PACKAGE_PIN Y23   IOSTANDARD LVCMOS33 } [get_ports { usb_clk }];
set_property -dict { PACKAGE_PIN A23   IOSTANDARD LVCMOS33 } [get_ports { usb_trigger }];

#set_property -dict { PACKAGE_PIN  Y25  IOSTANDARD   LVCMOS33 } [get_ports { USB_nALE }]; #IO_L10P_T1_12
set_property -dict { PACKAGE_PIN AA23  IOSTANDARD   LVCMOS33 } [get_ports { USB_nCE   }]; #IO_L11P_T1_SRCC_12
set_property -dict { PACKAGE_PIN AC23  IOSTANDARD   LVCMOS33 } [get_ports { USB_nRD   }]; #IO_L14P_T2_SRCC_12
set_property -dict { PACKAGE_PIN AA25  IOSTANDARD   LVCMOS33 } [get_ports { USB_nWR   }]; #IO_L7P_T1_12
set_property -dict { PACKAGE_PIN AC26  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[0]  }]; #IO_L9N_T1_DQS_12
set_property -dict { PACKAGE_PIN AD26  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[1]  }]; #IO_L21P_T3_DQS_12
set_property -dict { PACKAGE_PIN AD25  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[2]  }]; #IO_L23P_T3_12
set_property -dict { PACKAGE_PIN AE26  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[3]  }]; #IO_L21N_T3_DQS_12
set_property -dict { PACKAGE_PIN AB24  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[4]  }]; #IO_L11N_T1_SRCC_12
set_property -dict { PACKAGE_PIN AC24  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[5]  }]; #IO_L14N_T2_SRCC_12
set_property -dict { PACKAGE_PIN AD24  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[6]  }]; #IO_L16N_T2_12
set_property -dict { PACKAGE_PIN AD23  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[7]  }]; #IO_L16P_T2_12
set_property -dict { PACKAGE_PIN AB26  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[8]  }]; #IO_L9P_T1_DQS_12
set_property -dict { PACKAGE_PIN AB25  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[9]  }]; #IO_L7N_T1_12
set_property -dict { PACKAGE_PIN  W23  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[10] }]; #IO_L8P_T1_12
set_property -dict { PACKAGE_PIN  V23  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[11] }]; #IO_L3P_T0_DQS_12
set_property -dict { PACKAGE_PIN  Y21  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[12] }]; #IO_L15N_T2_DQS_12
set_property -dict { PACKAGE_PIN  U24  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[13] }]; #IO_L2P_T0_12
set_property -dict { PACKAGE_PIN  U22  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[14] }]; #IO_L1P_T0_12
set_property -dict { PACKAGE_PIN  V22  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[15] }]; #IO_L1N_T0_12
set_property -dict { PACKAGE_PIN  U21  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[16] }]; #IO_0_12
set_property -dict { PACKAGE_PIN  V21  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[17] }]; #IO_L6P_T0_12
set_property -dict { PACKAGE_PIN  W21  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[18] }]; #IO_L6N_T0_VREF_12
set_property -dict { PACKAGE_PIN  W20  IOSTANDARD   LVCMOS33 } [get_ports { USB_A[19] }]; #IO_L15P_T2_DQS_12
set_property -dict { PACKAGE_PIN  U25  IOSTANDARD   LVCMOS33 } [get_ports { USB_D[0] }]; #IO_L2N_T0_12
set_property -dict { PACKAGE_PIN  U26  IOSTANDARD   LVCMOS33 } [get_ports { USB_D[1] }]; #IO_L4P_T0_12
set_property -dict { PACKAGE_PIN AC21  IOSTANDARD   LVCMOS33 } [get_ports { USB_D[2] }]; #IO_L18N_T2_12
set_property -dict { PACKAGE_PIN  V24  IOSTANDARD   LVCMOS33 } [get_ports { USB_D[3] }]; #IO_L3N_T0_DQS_12
set_property -dict { PACKAGE_PIN  V26  IOSTANDARD   LVCMOS33 } [get_ports { USB_D[4] }]; #IO_L4N_T0_12
set_property -dict { PACKAGE_PIN  W26  IOSTANDARD   LVCMOS33 } [get_ports { USB_D[5] }]; #IO_L5N_T0_12
set_property -dict { PACKAGE_PIN  W25  IOSTANDARD   LVCMOS33 } [get_ports { USB_D[6] }]; #IO_L5P_T0_12
set_property -dict { PACKAGE_PIN  Y26  IOSTANDARD   LVCMOS33 } [get_ports { USB_D[7] }]; #IO_L10N_T1_12

set_property -dict { PACKAGE_PIN  Y11  IOSTANDARD  LVCMOS18 PULLTYPE PULLUP } [get_ports { USRSW0 }]; # USR_DBG_nRST

set_property -dict { PACKAGE_PIN AF24  IOSTANDARD  LVCMOS33 } [get_ports { CWIO_IO4 }]; #IO_L20P_T3_12

set_property -dict { PACKAGE_PIN  M26  IOSTANDARD   LVCMOS33 } [get_ports { USRLED[0] }]; #IO_L5N_T0_13
set_property -dict { PACKAGE_PIN  M25  IOSTANDARD   LVCMOS33 } [get_ports { USRLED[1] }]; #IO_L3P_T0_DQS_13
set_property -dict { PACKAGE_PIN  M24  IOSTANDARD   LVCMOS33 } [get_ports { USRLED[2] }]; #IO_L8P_T1_13
set_property -dict { PACKAGE_PIN  M19  IOSTANDARD   LVCMOS33 } [get_ports { USRLED[3] }]; #IO_L22N_T3_13
set_property -dict { PACKAGE_PIN  L25  IOSTANDARD   LVCMOS33 } [get_ports { USRLED[4] }]; #IO_L3N_T0_DQS_13
set_property -dict { PACKAGE_PIN  K26  IOSTANDARD   LVCMOS33 } [get_ports { USRLED[5] }]; #IO_L1N_T0_13

set_property -dict { PACKAGE_PIN   U9  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP0 }]; #IO_0_VRN_33
set_property -dict { PACKAGE_PIN   V7  IOSTANDARD   LVCMOS18 } [get_ports { USRDIP1 }]; #IO_L2N_T0_33

################################################
# _______  _____  __  __  _____  _   _   _____ #
#|__   __||_   _||  \/  ||_   _|| \ | | / ____|#
#   | |     | |  | \  / |  | |  |  \| || |  __ #
#   | |     | |  | |\/| |  | |  | . ` || | |_ |#
#   | |    _| |_ | |  | | _| |_ | |\  || |__| |#
#   |_|   |_____||_|  |_||_____||_| \_| \_____|#
################################################

# clocks:
create_clock -period 10.000 -name usb_clk  -waveform {0.000 5.000} [get_nets  usb_clk]

# both input clocks have same properties so there is no point in doing timing analysis for both:
set_case_analysis 1 [get_pins i_cw_clocks/CCLK_MUX/S]

# No spec for these, seems sensible:
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports {       USB_A }];
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports {       USB_D }];
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports { usb_trigger }];
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports {     USB_nCE }];
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports {     USB_nRD }];
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports {     USB_nWR }];

set_input_delay -clock usb_clk              -add_delay 0.000 [get_ports { USRDIP0 }];
set_input_delay -clock usb_clk              -add_delay 0.000 [get_ports { USRDIP1 }];
set_input_delay -clock [get_clocks usb_clk] -add_delay 0.500 [get_ports {  USRSW2 }];

set_output_delay -clock usb_clk 0.000 [ get_ports { USB_D     }];
set_output_delay -clock usb_clk 0.000 [ get_ports { CWIO_IO4  }];
set_output_delay -clock usb_clk 0.000 [ get_ports { CWIO_HS1  }];

set_false_path -to   [get_ports { USB_D     }]
set_false_path -from [get_ports { USRSW0    }]; # USR_DBG_nRST is not a real reset, but a switch. It can be used to reset the system, but it is not guaranteed to be glitch-free. Therefore, we need to tell the tools that it is not a real reset signal.
set_false_path -to   [get_ports { USRLED[*] }]; # USRLEDs are not real outputs, but just indicators. They can be used to indicate the state of the system, but they are not guaranteed to be glitch-free. Therefore, we need to tell the tools that they are not real output signals.
set_false_path -to   [get_ports { CWIO_HS1  }]; # Forwarded clock
set_false_path -to   [get_ports { CWIO_IO4  }]; # Async trigger signal
