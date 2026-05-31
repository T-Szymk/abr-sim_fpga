DATE         := `date +'%y%m%d_%T.%3N'`

export CURR_DIR         := $(PWD)
export ADAMSBRIDGE_ROOT ?= $(abspath $(CURR_DIR)/../adams-bridge)
export JOBS             ?= 8

BUILD_DIR     = $(CURR_DIR)/.sim_build
LOG_DIR       = $(BUILD_DIR)/logs
SIM_DIR       = $(CURR_DIR)/sim
FPGA_SRC_DIR  = $(CURR_DIR)/rtl
FPGA_TB_DIR   = $(CURR_DIR)/tb

FPGA_SV_FILES    = $(FPGA_SRC_DIR)/abr_fpga_pkg.sv      \
                   $(FPGA_SRC_DIR)/abr_mem_fpga.sv      \
                   $(FPGA_SRC_DIR)/abr_ahb_mgr.sv       \
									 $(FPGA_SRC_DIR)/abr_mem_if_pack.sv   \
									 $(FPGA_SRC_DIR)/abr_mem_if_unpack.sv \
									 $(FPGA_SRC_DIR)/abr_top_wrapper.sv   \
                   $(FPGA_SRC_DIR)/abr_fpga_top.sv

ABR_SV_FILES     = ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_config_defines.svh                 \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_reg_pkg.sv                         \
									 ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_sva.svh                           \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_macros.svh                        \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_1r1w_ram.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_1r1w_be_ram.sv                    \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_1r1w_512x4_ram.sv                 \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_ram_regout.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_icg.sv                            \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_2ff_sync.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_piso_multi.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_piso.sv                           \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_sample_buffer.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_msg_buffer.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_ahb_defines_pkg.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_ahb_slv_sif.sv                    \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_AND.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_delay_masked_shares.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_add_sub_mod_Boolean.sv     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_MUX.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_N_bit_Boolean_sub.sv       \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_full_adder.sv              \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_A2B_conv.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_N_bit_Boolean_adder.sv     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_N_bit_Arith_adder.sv       \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_B2A_conv.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_N_bit_mult.sv              \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_N_bit_mult_two_share.sv    \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_adder.sv                          \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_add_sub_mod.sv                    \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_ntt_add_sub_mod.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl/abr_masked_OR.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl/abr_sampler_pkg.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/rej_bounded/rtl/rej_bounded_ctrl.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/rej_bounded/rtl/rej_bounded2.sv                    \
                   ${ADAMSBRIDGE_ROOT}/src/rej_sampler/rtl/rej_sampler_ctrl.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/rej_sampler/rtl/rej_sampler.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/exp_mask/rtl/exp_mask_ctrl.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/exp_mask/rtl/exp_mask.sv                           \
                   ${ADAMSBRIDGE_ROOT}/src/sample_in_ball/rtl/sample_in_ball_pkg.sv           \
                   ${ADAMSBRIDGE_ROOT}/src/sample_in_ball/rtl/sib_mem.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/sample_in_ball/rtl/sample_in_ball_ctrl.sv          \
                   ${ADAMSBRIDGE_ROOT}/src/sample_in_ball/rtl/sample_in_ball_shuffler.sv      \
                   ${ADAMSBRIDGE_ROOT}/src/sample_in_ball/rtl/sample_in_ball.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/cbd_sampler/rtl/cbd_sampler_ctrl.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/cbd_sampler/rtl/cbd_sampler.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_sha3/rtl/abr_sha3_pkg.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_util_pkg.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_alert_pkg.sv                 \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_subreg_pkg.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_mubi_pkg.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_cipher_pkg.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_pkg.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_sparse_fsm_pkg.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim_generic/rtl/abr_prim_generic_flop_en.sv   \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim_generic/rtl/abr_prim_generic_flop.sv      \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim_generic/rtl/abr_prim_generic_buf.sv       \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_flop_en.sv                   \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_cdc_rand_delay.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_flop_2sync.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_lfsr.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_mubi4_sync.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_diff_decode.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_sec_anchor_buf.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_slicer.sv                    \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_count.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_sparse_fsm_flop.sv           \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_dom_and_2share.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_sec_anchor_flop.sv           \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_reg_we_check.sv              \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_packer_fifo.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_max_tree.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_subreg_arb.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_subreg.sv                    \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_intr_hw.sv                   \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_onehot_check.sv              \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_mubi8_sync.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_fifo_sync_cnt.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_buf.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_alert_receiver.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_flop.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_alert_sender.sv              \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_fifo_sync.sv                 \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_arbiter_ppc.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_sum_tree.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_subreg_ext.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl/abr_prim_edge_detector.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/abr_sha3/rtl/abr_keccak_round.sv                   \
                   ${ADAMSBRIDGE_ROOT}/src/abr_sha3/rtl/abr_keccak_2share.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/abr_sha3/rtl/abr_sha3pad.sv                        \
                   ${ADAMSBRIDGE_ROOT}/src/abr_sha3/rtl/abr_sha3.sv                           \
                   ${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl/abr_sampler_top.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_defines_pkg.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/barrett_reduction/rtl/barrett_reduction.sv         \
                   ${ADAMSBRIDGE_ROOT}/src/barrett_reduction/rtl/masked_barrett_if_cond.sv    \
                   ${ADAMSBRIDGE_ROOT}/src/barrett_reduction/rtl/masked_barrett_reduction.sv  \
                   ${ADAMSBRIDGE_ROOT}/src/barrett_reduction/rtl/masked_barrett_if_cond_v2.sv \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_butterfly2x2.sv                    \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_butterfly.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_mult_dsp.sv                        \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_mult_reduction.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_special_adder.sv                   \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_masked_special_adder.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_masked_mult_redux46.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_div2.sv                            \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_buffer.sv                          \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_shuffle_buffer.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_twiddle_lookup.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_ctrl.sv                            \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_top.sv                             \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_masked_BFU_add_sub.sv              \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_mlkem_masked_BFU_add_sub.sv        \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_masked_BFU_mult.sv                 \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_mlkem_masked_BFU_mult.sv           \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_masked_gs_butterfly.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_mlkem_masked_gs_butterfly.sv       \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_masked_pwm.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_masked_butterfly1x2.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_mlkem_masked_butterfly1x2.sv       \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_hybrid_butterfly_2x2.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_karatsuba_pairwm.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl/ntt_masked_pairwm.sv                   \
                   ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose_defines_pkg.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose.sv                         \
                   ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose_r1_lut.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose_w1_mem.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose_mod_2gamma2.sv             \
                   ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose_ctrl.sv                    \
                   ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose_w1_encode.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/decompose/rtl/decompose_usehint.sv                 \
                   ${ADAMSBRIDGE_ROOT}/src/sk_decode/rtl/skdecode_defines_pkg.sv              \
                   ${ADAMSBRIDGE_ROOT}/src/sk_encode/rtl/skencode.sv                          \
                   ${ADAMSBRIDGE_ROOT}/src/sk_decode/rtl/skdecode_top.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/sk_decode/rtl/skdecode_ctrl.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/sk_decode/rtl/skdecode_s1s2_unpack.sv              \
                   ${ADAMSBRIDGE_ROOT}/src/sk_decode/rtl/skdecode_t0_unpack.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/makehint/rtl/makehint_defines_pkg.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/makehint/rtl/hintgen.sv                            \
                   ${ADAMSBRIDGE_ROOT}/src/makehint/rtl/makehint.sv                           \
                   ${ADAMSBRIDGE_ROOT}/src/norm_check/rtl/norm_check_defines_pkg.sv           \
                   ${ADAMSBRIDGE_ROOT}/src/norm_check/rtl/norm_check.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/norm_check/rtl/norm_check_ctrl.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/norm_check/rtl/norm_check_top.sv                   \
                   ${ADAMSBRIDGE_ROOT}/src/sig_encode_z/rtl/sigencode_z_defines_pkg.sv        \
                   ${ADAMSBRIDGE_ROOT}/src/sig_encode_z/rtl/sigencode_z_top.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/sig_encode_z/rtl/sigencode_z_unit.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/sigdecode_h/rtl/sigdecode_h_defines_pkg.sv         \
                   ${ADAMSBRIDGE_ROOT}/src/sigdecode_h/rtl/sigdecode_h.sv                     \
                   ${ADAMSBRIDGE_ROOT}/src/sigdecode_h/rtl/sigdecode_h_ctrl.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/sig_decode_z/rtl/sigdecode_z_defines_pkg.sv        \
                   ${ADAMSBRIDGE_ROOT}/src/sig_decode_z/rtl/sigdecode_z_top.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/sig_decode_z/rtl/sigdecode_z_unit.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/pk_decode/rtl/pkdecode.sv                          \
                   ${ADAMSBRIDGE_ROOT}/src/power2round/rtl/power2round_defines_pkg.sv         \
                   ${ADAMSBRIDGE_ROOT}/src/power2round/rtl/power2round_top.sv                 \
                   ${ADAMSBRIDGE_ROOT}/src/power2round/rtl/power2round_ctrl.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/power2round/rtl/power2round_core.sv                \
                   ${ADAMSBRIDGE_ROOT}/src/power2round/rtl/power2round_skencode.sv            \
                   ${ADAMSBRIDGE_ROOT}/src/compress/rtl/compress_defines_pkg.sv               \
                   ${ADAMSBRIDGE_ROOT}/src/compress/rtl/compress_top.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/compress/rtl/compress.sv                           \
                   ${ADAMSBRIDGE_ROOT}/src/compress/rtl/compress_ctrl.sv                      \
                   ${ADAMSBRIDGE_ROOT}/src/decompress/rtl/decompress_defines_pkg.sv           \
                   ${ADAMSBRIDGE_ROOT}/src/decompress/rtl/decompress_top.sv                   \
                   ${ADAMSBRIDGE_ROOT}/src/decompress/rtl/decompress.sv                       \
                   ${ADAMSBRIDGE_ROOT}/src/decompress/rtl/decompress_ctrl.sv                  \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_ctrl_pkg.sv                        \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_mem_if.sv                          \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_mem_top.sv                         \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_seq.sv                             \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_ctrl.sv                            \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_top.sv                             \
                   ${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_reg.sv

FPGA_TB_SV_FILES = $(FPGA_TB_DIR)/tb_abr_fpga.sv

INC_DIRS         := +incdir+${ADAMSBRIDGE_ROOT}/src/abr_top/rtl           \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/abr_libs/rtl          \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/abr_sampler_top/rtl   \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/rej_bounded/rtl       \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/rej_sampler/rtl       \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/exp_mask/rtl          \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/sample_in_ball/rtl    \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/cbd_sampler/rtl       \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/abr_sha3/rtl          \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/abr_prim/rtl          \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/abr_prim_generic/rtl  \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/ntt_top/rtl           \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/barrett_reduction/rtl \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/decompose/rtl         \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/sk_decode/rtl         \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/sk_encode/rtl         \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/makehint/rtl          \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/norm_check/rtl        \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/sig_encode_z/rtl      \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/sigdecode_h/rtl       \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/sig_decode_z/rtl      \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/pk_decode/rtl         \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/power2round/rtl       \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/compress/rtl          \
                    +incdir+${ADAMSBRIDGE_ROOT}/src/decompress/rtl

SIM_TOP_MODULE    ?= tb_abr_fpga

################################################################################

# FPGA Questa sim recipes

Q_BUILD_DIR    = $(BUILD_DIR)/questa_build

MODELSIM_INI_PATH = -ini $(Q_BUILD_DIR)/modelsim.ini

Q_FPGA_TB_LIB       = questa_fpga_tb_lib
Q_FPGA_TB_LIB_PATH  = $(Q_BUILD_DIR)/$(Q_FPGA_TB_LIB)

VLOG_OPTS     ?=
VLOG_OPTS     += -sv
VLOG_OPTS     += -mfcu
VLOG_OPTS     += $(MODELSIM_INI_PATH)
VLOG_OPTS     += -quiet
VLOG_OPTS     += -logfile $(LOG_DIR)/vlog_$(DATE).log
VLOG_OPTS     += $(INC_DIRS)
VLOG_OPTS     += +define+TECH_SPECIFIC_ICG
VLOG_OPTS     += +define+SIMULATION


VLOG_SUPPRESS ?= -suppress vlog-13314

VOPT_OPTS     ?=
VOPT_OPTS     += +acc
VOPT_OPTS     += $(MODELSIM_INI_PATH)
VOPT_OPTS     += -quiet
VOPT_OPTS     += -logfile $(LOG_DIR)/vopt_$(DATE).log

VOPT_SUPPRESS ?=

VSIM_OPTS     ?=
VSIM_OPTS     += $(MODELSIM_INI_PATH)
VSIM_OPTS     += -logfile $(LOG_DIR)/vsim_$(DATE).log
VSIM_OPTS     += -quiet

VSIM_SUPPRESS ?= -suppress vsim-3009

DO_FILE       ?= sim.do


.PHONY: sim_init sim_lib sim_compile sim_opt sim_gui sim sim_clean


sim_init: sim_clean
	@mkdir -p $(Q_BUILD_DIR)
	@mkdir -p $(LOG_DIR)


sim_lib: sim_init
	@cd $(Q_BUILD_DIR)                            && \
	 vlib $(Q_FPGA_TB_LIB_PATH)                  && \
	 vmap $(Q_FPGA_TB_LIB) $(Q_FPGA_TB_LIB_PATH)


sim_compile: sim_lib
	@vlog $(VLOG_OPTS) -work $(Q_FPGA_TB_LIB)  $(VLOG_SUPPRESS) $(ABR_SV_FILES) $(FPGA_SV_FILES) $(FPGA_TB_SV_FILES)


sim_opt: sim_compile
	@vopt $(VOPT_OPTS) -work $(Q_FPGA_TB_LIB) \
	$(VOPT_SUPPRESS) \
	$(SIM_TOP_MODULE) -o $(SIM_TOP_MODULE)_opt


sim_gui: sim_opt
	@vsim $(VSIM_OPTS) -work $(Q_FPGA_TB_LIB) \
	$(VSIM_SUPPRESS) \
	-onfinish stop \
	-do $(SIM_DIR)/$(DO_FILE) \
	$(SIM_TOP_MODULE)_opt


sim: sim_opt
	@vsim $(VSIM_OPTS) -work $(Q_FPGA_TB_LIB) \
	$(VSIM_SUPPRESS) \
	-c \
	-wlf $(Q_BUILD_DIR)/$(SIM_TOP_MODULE)_$(DATE).wlf \
	$(SIM_TOP_MODULE)_opt \
	-do "log -r /*; log -r /tb_abr_fpga/dut/result_pk; log -r /tb_abr_fpga/dut/result_sk; log -r /tb_abr_fpga/dut/result_sig; log -r /tb_abr_fpga/dut/result_vfy; run -all"


sim_clean:
	@rm -rf $(Q_BUILD_DIR)

################################################################################

# FPGA Verilator sim recipes

V_SRCS      = $(ABR_SV_FILES) $(FPGA_SV_FILES) $(FPGA_TB_SV_FILES)
V_INCLUDES  = $(INC_DIRS)
V_DEFINES   = -DTECH_SPECIFIC_ICG -DVERILATOR -DSIMULATION
V_BUILD_DIR = $(BUILD_DIR)/verilator_build

# Verilator flags
VFLAGS := \
	--binary \
	--timing \
	--trace-vcd \
	--top-module $(SIM_TOP_MODULE) \
	-Wall \
	-Wno-fatal \
	$(V_INCLUDES)

.PHONY: vinit vbuild vrun vclean

VLOG_FILE = $(LOG_DIR)/verilator_$(DATE).log

vinit: vclean
	@mkdir -p $(V_BUILD_DIR)
	@mkdir -p $(LOG_DIR)


vbuild : vinit $(V_BUILD_DIR)/V$(SIM_TOP_MODULE)
	@echo "Built Verilator model..."
	@cp -p $(V_BUILD_DIR)/V$(SIM_TOP_MODULE) $(BUILD_DIR)/V$(SIM_TOP_MODULE)


$(V_BUILD_DIR)/V$(SIM_TOP_MODULE): $(V_SRCS)
	@verilator $(VFLAGS) $(V_SRCS) --Mdir $(V_BUILD_DIR) --prefix V$(SIM_TOP_MODULE) \
		2>&1 | tee $(VLOG_FILE)

vclean:
	@rm -rf $(V_BUILD_DIR)
	@rm -f $(V_BUILD_DIR)/V$(SIM_TOP_MODULE)
	@rm -f $(BUILD_DIR)/V$(SIM_TOP_MODULE)
	@rm -f $(BUILD_DIR)/*.vcd
	@rm -f $(BUILD_DIR)/*.fst

################################################################################

# FPGA build recipes

FPGA_BUILD_DIR = $(CURR_DIR)/.fpga_build
FPGA_LOG_DIR   = $(FPGA_BUILD_DIR)/logs

export OOC_PROJECT_NAME = abr_fpga_ooc_${BOARD}
export OOC_PROJECT_DIR  = $(FPGA_BUILD_DIR)/$(OOC_PROJECT_NAME)
export OOC_TOP_MODULE   = abr_top_wrapper
export PROJECT_NAME     = abr_fpga_${BOARD}
export PROJECT_DIR      = $(FPGA_BUILD_DIR)/$(PROJECT_NAME)
export EDIF_DIR         = $(OOC_PROJECT_DIR)/ooc_netlist
export SCRIPT_DIR       = $(CURR_DIR)/scripts

export IP_DIR           = $(FPGA_BUILD_DIR)/ip

export BOARD            = cw310
export TOP_MODULE       = abr_fpga_$(BOARD)_top

# top clock IP params
export TOP_CLK_ID         = ip_top_clk
export INPUT_OSC_FREQ_MHZ =  20.000
export TOP_CLK_FREQ_MHZ   =  20.000

export IP_LIST = $(TOP_CLK_ID)

.PHONY: fpga_init fpga_build_ip fpga_clean_ip fpga_ooc_build fpga_ooc_clean fpga_main_build fpga_main_clean


fpga_init:
	@mkdir -p $(FPGA_BUILD_DIR)
	@mkdir -p $(FPGA_LOG_DIR)
	@mkdir -p $(IP_DIR)


fpga_build_ip: fpga_init $(IP_LIST)
	@echo "Finished generating the following Vivado IPs..."
	@echo "$(IP_LIST)"


$(IP_LIST):
	@echo "Building IP: $@"
	@mkdir -p $(IP_DIR)/$(BOARD)/$@ && \
	cd $(IP_DIR)/$(BOARD)/$@ && \
	vivado -mode batch -source $(SCRIPT_DIR)/$@.tcl -notrace -log \
    $(FPGA_LOG_DIR)/vivado_ip_$(BOARD)_$@_$(DATE).log
# ToDo: Copy IP netlist into rtl/ip_netlist dir

fpga_clean_ip:
	@echo "Cleaning Vivado IPs..."
	@rm -rf $(IP_DIR)

fpga_ooc_build: fpga_init fpga_ooc_clean
	@echo "Building $(OOC_PROJECT_NAME)..."
	@cd $(FPGA_BUILD_DIR) && \
	vivado -mode batch -source $(SCRIPT_DIR)/abr_top_ooc.tcl -notrace -log \
	  $(FPGA_LOG_DIR)/vivado_ooc_$(DATE).log


fpga_ooc_clean:
	@echo "Cleaning $(OOC_PROJECT_NAME) project..."
	@rm -rf $(OOC_PROJECT_DIR)


fpga_main_build:
	@echo "Building $(PROJECT_NAME)..."
	@cd $(FPGA_BUILD_DIR) && \
	vivado -mode batch -source $(SCRIPT_DIR)/abr_fpga_build.tcl -notrace -log \
	  $(FPGA_LOG_DIR)/vivado_main_$(DATE).log


fpga_main_clean:
	@echo "Cleaning $(PROJECT_NAME) project..."
	@rm -rf $(PROJECT_DIR)

fpga_clean:
	@echo "Cleaning FPGA projects..."
	@rm -rf $(FPGA_BUILD_DIR)

################################################################################

# Global
.PHONY: clean_all
clean_all:
	@rm -rf $(BUILD_DIR)
	@rm -rf $(FPGA_BUILD_DIR)