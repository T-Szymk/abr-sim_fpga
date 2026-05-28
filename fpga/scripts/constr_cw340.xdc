# ------------------------------------------------------------------------------
# constr_cw340.xdc
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 25-may-2026
#
# Description: Constraints file for main abr_fpga project on the cw340 board
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

set_property -dict { PACKAGE_PIN  AJ29 IOSTANDARD   LVCMOS18 } [get_ports { PLL_CLK_1 }];

set_property -dict { PACKAGE_PIN  E23  IOSTANDARD   LVCMOS18 PULLTYPE PULLUP } [get_ports { USRSW0 }]; # USR_DBG_nRST

set_property -dict { PACKAGE_PIN AH32  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[0] }]; # OT_IOR6
set_property -dict { PACKAGE_PIN AJ33  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[1] }]; # OT_IOR7
set_property -dict { PACKAGE_PIN AH34  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[2] }]; # OT_IOR8
set_property -dict { PACKAGE_PIN AH31  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[3] }]; # OT_IOR9
set_property -dict { PACKAGE_PIN AH27  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[4] }]; # OT_IOR10

################################################
# _______  _____  __  __  _____  _   _   _____ #
#|__   __||_   _||  \/  ||_   _|| \ | | / ____|#
#   | |     | |  | \  / |  | |  |  \| || |  __ #
#   | |     | |  | |\/| |  | |  | . ` || | |_ |#
#   | |    _| |_ | |  | | _| |_ | |\  || |__| |#
#   |_|   |_____||_|  |_||_____||_| \_| \_____|#
################################################

#set PLL_CLK1_HALF_PERIOD 8.0000
#create_clock -period [expr 2*$PLL_CLK1_HALF_PERIOD] -name PLL_CLK1 -waveform "0.000 ${PLL_CLK1_HALF_PERIOD}" [get_ports { PLL_CLK_1 }]


set_false_path -from [get_ports USRSW0]; # USR_DBG_nRST is not a real reset, but a switch. It can be used to reset the system, but it is not guaranteed to be glitch-free. Therefore, we need to tell the tools that it is not a real reset signal.
set_false_path -to   [get_ports USRLED[*]]; # USRLEDs are not real outputs, but just indicators. They can be used to indicate the state of the system, but they are not guaranteed to be glitch-free. Therefore, we need to tell the tools that they are not real output signals.