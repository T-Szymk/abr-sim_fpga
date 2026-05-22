# ------------------------------------------------------------------------------
# constr_ooc.xdc
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 20-may-2026
#
# Description: Constraints file for out-of-context synthesis of abr_top module
# ------------------------------------------------------------------------------

create_clock -period 10.000 -name clk [get_ports clk];

set_false_path -from [get_ports rst_b];