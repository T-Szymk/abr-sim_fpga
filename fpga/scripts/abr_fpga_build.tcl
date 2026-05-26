
# ------------------------------------------------------------------------------
# abr_fpga_build.tcl
#
# Author(s): Tom Szymkowiak <thomas.szymkowiak@tuni.fi>
# Date     : 22-may-2026
#
# Description: Vivado build script to generate a bitstream for the abr_fpga 
#              project. This script is intended to be run from the Makefile in 
#              the fpga directory.
# ------------------------------------------------------------------------------

if {[info exists ::env(SCRIPT_DIR)]} {
    set SCRIPT_DIR $::env(SCRIPT_DIR)
} else {
    puts "SCRIPT_DIR environment variable not set. Please set it to the directory containing this script."
    exit
}

if { [ info exists ::env(JOBS) ] } {
  set JOBS $::env(JOBS);
} else { 
  set JOBS 8;
}
puts "JOBS  : ${JOBS}";

if { [ info exists ::env(PROJECT_NAME) ] } {
  set PROJECT_NAME $::env(PROJECT_NAME);
} else { 
  puts "PROJECT_NAME environment variable not set. Please set it to the project name."
  exit
}

if { [ info exists ::env(PROJECT_DIR) ] } {
  set PROJECT_DIR $::env(PROJECT_DIR);
} else { 
  puts "PROJECT_DIR environment variable not set. Please set it to the project name."
  exit
}

if { [ info exists ::env(TOP_MODULE) ] } {
  set TOP_MODULE $::env(TOP_MODULE);
} else { 
  puts "TOP_MODULE environment variable not set. Please set it to the top module name."
  exit
}

if { [ info exists ::env(OOC_TOP_MODULE) ] } {
  set OOC_TOP_MODULE $::env(OOC_TOP_MODULE);
} else { 
  puts "OOC_TOP_MODULE environment variable not set. Please set it to the top module name of the OOC project."
  exit
}

# used for EDIF import
if { [ info exists ::env(OOC_PROJECT_NAME) ] } {
  set OOC_PROJECT_NAME $::env(OOC_PROJECT_NAME);
} else { 
  puts "OOC_PROJECT_NAME environment variable not set. Please set it to the project name."
  exit
}

if { [ info exists ::env(EDIF_DIR) ] } {
  set EDIF_DIR $::env(EDIF_DIR);
} else { 
  puts "EDIF_DIR environment variable not set. Please set it to the EDIF directory."
  exit
}

if { [ info exists ::env(IP_LIST) ] } {
  set IP_LIST $::env(IP_LIST);
} else { 
  puts "IP_LIST environment variable not set. Please set it to the list of IPs to import."
  exit
}

if { [ info exists ::env(IP_DIR) ] } {
  set IP_DIR $::env(IP_DIR);
} else { 
  puts "IP_DIR environment variable not set. Please set it to the directory containing the IPs."
  exit
}

source ${SCRIPT_DIR}/common.tcl
source ${SCRIPT_DIR}/cw340.tcl

log_script_entry;

# Generate OOC design if netlist doesn't exist
if { ![file exists ${EDIF_DIR}/${OOC_TOP_MODULE}.edf] } {
    puts "OOC netlist not found. Generating OOC design and netlist..."
    source ${SCRIPT_DIR}/abr_top_ooc.tcl
} else {
    puts "OOC netlist found at ${EDIF_DIR}/${OOC_TOP_MODULE}.edf. Skipping OOC generation..."
}

set ADAMSBRIDGE_ROOT [file normalize "${CURR_DIR}/../adams-bridge"]
set FPGA_SRC_DIR     [file normalize "${CURR_DIR}/rtl"]
set CONSTR "${SCRIPT_DIR}/constr.xdc"

create_project ${PROJECT_NAME} ${PROJECT_DIR} -part ${XLNX_PRT_ID};

# set top design
set_property top ${TOP_MODULE} [current_fileset]
puts "TOP_MODULE  : ${TOP_MODULE}";

#########################################################
# ADD SOURCES
#########################################################

set ABR_SV_FILES " \
  ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv               \
  ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_reg_pkg.sv                  \
  ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_ahb_defines_pkg.sv         \
  ${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl/abr_sampler_pkg.sv      \
  ${ADAMSBRIDGE_ROOT}/src/sample_in_ball/rtl/sample_in_ball_pkg.sv    \
  ${ADAMSBRIDGE_ROOT}/src/abr_sha3/rtl/abr_sha3_pkg.sv                \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_util_pkg.sv           \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_alert_pkg.sv          \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_subreg_pkg.sv         \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_mubi_pkg.sv           \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_cipher_pkg.sv         \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_pkg.sv                \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_sparse_fsm_pkg.sv     \
  ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_defines_pkg.sv              \
  ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose_defines_pkg.sv      \
  ${ADAMSBRIDGE_ROOT}/src/sk_decode/rtl/skdecode_defines_pkg.sv       \
  ${ADAMSBRIDGE_ROOT}/src/makehint/rtl/makehint_defines_pkg.sv        \
  ${ADAMSBRIDGE_ROOT}/src/norm_check/rtl/norm_check_defines_pkg.sv    \
  ${ADAMSBRIDGE_ROOT}/src/sig_encode_z/rtl/sigencode_z_defines_pkg.sv \
  ${ADAMSBRIDGE_ROOT}/src/sigdecode_h/rtl/sigdecode_h_defines_pkg.sv  \
  ${ADAMSBRIDGE_ROOT}/src/sig_decode_z/rtl/sigdecode_z_defines_pkg.sv \
  ${ADAMSBRIDGE_ROOT}/src/power2round/rtl/power2round_defines_pkg.sv  \
  ${ADAMSBRIDGE_ROOT}/src/compress/rtl/compress_defines_pkg.sv        \
  ${ADAMSBRIDGE_ROOT}/src/decompress/rtl/decompress_defines_pkg.sv    \
  ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_ctrl_pkg.sv                 \
  ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_mem_if.sv                   \
"

add_files -norecurse -scan_for_includes ${ABR_SV_FILES};

set FPGA_FILES " \
  ${FPGA_SRC_DIR}/abr_fpga_pkg.sv             \
  ${FPGA_SRC_DIR}/abr_fpga_pkg.sv             \
  ${FPGA_SRC_DIR}/abr_mem_fpga.sv             \
  ${FPGA_SRC_DIR}/abr_ahb_mgr.sv              \
  ${FPGA_SRC_DIR}/abr_mem_if_pack.sv          \
  ${FPGA_SRC_DIR}/abr_top_wrapper_black_box.v \
  ${FPGA_SRC_DIR}/abr_fpga_top.sv             \
  ${FPGA_SRC_DIR}/abr_fpga_cw340_top.sv       \
"

add_files -norecurse -scan_for_includes ${FPGA_FILES};

#########################################################
# SET INCLUDES
#########################################################

set ABR_INCLUDES  " \
  ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl           \
  ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl          \
  ${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl   \
  ${ADAMSBRIDGE_ROOT}/src/rej_bounded/rtl       \
  ${ADAMSBRIDGE_ROOT}/src/rej_sampler/rtl       \
  ${ADAMSBRIDGE_ROOT}/src/exp_mask/rtl          \
  ${ADAMSBRIDGE_ROOT}/src/sample_in_ball/rtl    \
  ${ADAMSBRIDGE_ROOT}/src/cbd_sampler/rtl       \
  ${ADAMSBRIDGE_ROOT}/src/abr_sha3/rtl          \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl          \
  ${ADAMSBRIDGE_ROOT}/src/abr_prim_generic/rtl  \
  ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl           \
  ${ADAMSBRIDGE_ROOT}/src/barrett_reduction/rtl \
  ${ADAMSBRIDGE_ROOT}/src/decompose/rtl         \
  ${ADAMSBRIDGE_ROOT}/src/sk_decode/rtl         \
  ${ADAMSBRIDGE_ROOT}/src/sk_encode/rtl         \
  ${ADAMSBRIDGE_ROOT}/src/makehint/rtl          \
  ${ADAMSBRIDGE_ROOT}/src/norm_check/rtl        \
  ${ADAMSBRIDGE_ROOT}/src/sig_encode_z/rtl      \
  ${ADAMSBRIDGE_ROOT}/src/sigdecode_h/rtl       \
  ${ADAMSBRIDGE_ROOT}/src/sig_decode_z/rtl      \
  ${ADAMSBRIDGE_ROOT}/src/pk_decode/rtl         \
  ${ADAMSBRIDGE_ROOT}/src/power2round/rtl       \
  ${ADAMSBRIDGE_ROOT}/src/compress/rtl          \
  ${ADAMSBRIDGE_ROOT}/src/decompress/rtl        \
"

set_property include_dirs ${ABR_INCLUDES} [current_fileset]

#########################################################
# READ PRE-BUILT OOC NETLIST
#########################################################

read_edif ${EDIF_DIR}/${OOC_TOP_MODULE}.edf

#########################################################
# SET DEFINES
#########################################################

set DEFINES " \
  SYNTHESIS=1           \
  DTECH_SPECIFIC_ICG=1  \
  ABR_OP=OP_KGSIGN \
"

set_property verilog_define ${DEFINES} [current_fileset]

#########################################################
# SET CONSTRAINTS
#########################################################

add_files -fileset constrs_1 -norecurse ${CONSTR};

#########################################################
# ADD IPs
#########################################################

# Add Xilinx IPs
foreach {IP_NAME} ${IP_LIST} {
    # fpga/.fpga_build/ip/ip_top_clk.srcs/sources_1/ip/ip_top_clk/ip_top_clk.xci
    import_ip ${IP_DIR}/${IP_NAME}.srcs/sources_1/ip/${IP_NAME}/${IP_NAME}.xci
}

#########################################################
# ELABORATION (Optional)
#########################################################

## Elaborate design
synth_design -rtl -name rtl_1 -sfcu;


#########################################################
# SYNTHESIS
#########################################################

set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
launch_runs synth_1 -jobs ${JOBS}
wait_on_run synth_1
open_run synth_1 -name netlist_1
set_property needs_refresh false [get_runs synth_1];

#########################################################
# IMPLEMENTATION
#########################################################

# set for RuntimeOptimized implementation
set_property "steps.opt_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
set_property "steps.place_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
set_property "steps.route_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
set_property "steps.phys_opt_design.args.is_enabled" true [get_runs impl_1]
#set_property "steps.phys_opt_design.args.directive" "ExploreWithHoldFix" [get_runs impl_1]
#set_property "steps.post_route_phys_opt_design.args.is_enabled" true [get_runs impl_1]
#set_property "steps.post_route_phys_opt_design.args.directive" "ExploreWithAggressiveHoldFix" [get_runs impl_1]
#set_param route.enableHoldExpnBailout 0

set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

launch_runs impl_1 -jobs ${JOBS} -verbose; # CAN BE MODIFIED DEPENDING ON BUILD HOST 
wait_on_run impl_1

#########################################################
# BITSTREAM GENERATION
#########################################################

launch_runs impl_1 -jobs ${JOBS} -to_step write_bitstream
wait_on_run impl_1

open_run impl_1

log_script_exit;
