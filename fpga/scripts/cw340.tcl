# ------------------------------------------------------------------------------
# CW340.tcl
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 20-may-2026
#
# Description: TCL script containing FPGA board configuration values
# ------------------------------------------------------------------------------

source ${SCRIPT_DIR}/common.tcl

log_script_entry;

# Set board-specific values for use in project
set XLNX_PRT_ID xcku095-ffva1156-1-c;

puts "Board Configuration Parameters are:";
puts "Board Part: ${XLNX_PRT_ID}";

log_script_exit;

# ------------------------------------------------------------------------------
# End of Script
# ------------------------------------------------------------------------------
