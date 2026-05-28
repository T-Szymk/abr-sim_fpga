# ------------------------------------------------------------------------------
# CW340.tcl
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 20-may-2026
#
# Description: TCL script containing FPGA board configuration values
# ------------------------------------------------------------------------------

if {[info exists ::env(SCRIPT_DIR)]} {
    set SCRIPT_DIR $::env(SCRIPT_DIR)
} else {
    puts "SCRIPT_DIR environment variable not set. Please set it to the directory containing this script."
    exit
}

if { [ info exists ::env(BOARD) ] } {
  set BOARD $::env(BOARD);
} else { 
  puts "BOARD environment variable not set. Please set it to the board name."
  exit
}

source ${SCRIPT_DIR}/common.tcl
source ${SCRIPT_DIR}/${BOARD}.tcl

log_script_entry;

# detect IP name
if [info exists ::env(JOBS)] {
    set JOBS $::env(JOBS)
} else {
    set JOBS 8
    puts "WARNING: JOBS variable not found. Value set to ${JOBS}"
}

# detect IP name
if [info exists ::env(TOP_CLK_ID)] {
    set TOP_CLK_ID $::env(TOP_CLK_ID)
    puts "NOTE: TOP_CLK_ID set to ${TOP_CLK_ID}"
} else {
    puts "WARNING: TOP_CLK_ID variable not set. Please set it to IP name."
    exit
}

# detect input clock period definition
if [info exists ::env(INPUT_OSC_FREQ_MHZ)] {
    set INPUT_OSC_FREQ_MHZ $::env(INPUT_OSC_FREQ_MHZ)
    puts "NOTE: INPUT_OSC_FREQ_MHZ set to ${INPUT_OSC_FREQ_MHZ} MHz"
} else {
    set INPUT_OSC_FREQ_MHZ 62.500
    puts "WARNING: INPUT_OSC_FREQ_MHZ variable not found. Value set to ${INPUT_OSC_FREQ_MHZ} MHz"
}

# set input oscillator period
set INPUT_OSC_PERIOD_NS [expr {1000.0 / $INPUT_OSC_FREQ_MHZ}];
puts "NOTE: INPUT_OSC_PERIOD_NS set to $INPUT_OSC_PERIOD_NS ns"


# detect top clock period definition
if [info exists ::env(TOP_CLK_FREQ_MHZ)] {
    set TOP_CLK_FREQ_MHZ $::env(TOP_CLK_FREQ_MHZ)
    puts "NOTE: TOP_CLK_FREQ_MHZ set to ${TOP_CLK_FREQ_MHZ} MHz"
} else {
    set TOP_CLK_FREQ_MHZ 50.000
    puts "WARNING: TOP_CLK_FREQ_MHZ variable not found. Value set to ${TOP_CLK_FREQ_MHZ} MHz"
}

# Critical definition checks
if {![info exists XLNX_PRT_ID]} {
    puts "WARNING: XLNX_PRT_ID is not defined. Please define within the <BOARD>.tcl file"
    exit
}

set IP_NAME ${TOP_CLK_ID}

create_project ${IP_NAME} . -part ${XLNX_PRT_ID}

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name ${IP_NAME}

set_property -dict [eval list \
  CONFIG.PRIMITIVE                  {MMCM}                 \
  CONFIG.MMCM_CLKIN1_PERIOD         {$INPUT_OSC_PERIOD_NS} \
  CONFIG.PRIM_IN_FREQ               {$INPUT_OSC_FREQ_MHZ}  \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {$TOP_CLK_FREQ_MHZ}    \
  CONFIG.CLKOUT1_DRIVES             {BUFG}                 \
  CONFIG.CLK_OUT1_PORT              {clk_out}              \
  CONFIG.LOCKED_PORT                {clk_lock}             \
] [get_ips ${IP_NAME}]

generate_target all [get_files  ./${IP_NAME}.srcs/sources_1/ip/${IP_NAME}/${IP_NAME}.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${IP_NAME}.srcs/sources_1/ip/${IP_NAME}/${IP_NAME}.xci]
launch_run -jobs $JOBS ${IP_NAME}_synth_1
wait_on_run ${IP_NAME}_synth_1

log_script_exit;

# ------------------------------------------------------------------------------
# End of Script
# ------------------------------------------------------------------------------

