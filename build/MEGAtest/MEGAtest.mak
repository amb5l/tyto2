#################################################################################
# MEGAtest.mak
#################################################################################

default: bit

git_commit_hex=$(shell git rev-parse --short=8 HEAD)
git_commit_dec=$(shell printf "%d" 0x$(git_commit_hex))
toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

ROWS_LOG2=13
COLS_LOG2=9

#################################################################################
# Vitis

VITIS_FLOW=classic
VITIS_ARCH=riscv
VITIS_SRC=\
	$(toplevel)/src/common/video/microblaze/cb.c \
	$(toplevel)/src/common/video/microblaze/cb.h \
	$(toplevel)/src/common/basic/microblaze/printf.c \
	$(toplevel)/src/common/basic/microblaze/printf.h \
	$(toplevel)/src/common/basic/microblaze/peekpoke.h \
	$(toplevel)/src/designs/$(DESIGN)/software/hram_test.c \
	$(toplevel)/src/designs/$(DESIGN)/software/hram_test.h \
	$(toplevel)/src/designs/$(DESIGN)/software/xadc.c \
	$(toplevel)/src/designs/$(DESIGN)/software/xadc.h \
	$(toplevel)/src/designs/$(DESIGN)/software/bsp.c \
	$(toplevel)/src/designs/$(DESIGN)/software/bsp.h \
	$(toplevel)/src/designs/$(DESIGN)/software/main.c
VITIS_INC=\
	$(toplevel)/src/common/basic/microblaze \
	$(toplevel)/src/common/video/microblaze \
	$(toplevel)/src/designs/$(DESIGN)/software
VITIS_SYM=APP_NAME=$(DESIGN)$(addprefix _,$(BOARD_VARIANT))
VITIS_SYM_RLS=BUILD_CFG_RLS
VITIS_SYM_DBG=BUILD_CFG_DBG

include $(make_fpga)/vitis.mak

################################################################################
# autogenerated VHDL package

random_1to1_py=$(toplevel)/src/designs/MEGAtest/random_1to1.py
random_1to1_vhd=$(abspath ./random_1to1.vhd)

$(random_1to1_vhd): $(random_1to1_py)
	python $(random_1to1_py) $(ROWS_LOG2) > $@

clean::
	@rm -f $(random_1to1_vhd)

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(DESIGN)$(addprefix _,$(BOARD_VARIANT))
VIVADO_DSN_GEN=GIT_COMMIT=$(git_commit_dec)
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/basic/xilinx/sync.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm_v2.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm_drp.vhd \
	$(toplevel)/src/designs/$(DESIGN)/clk_rst.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/ram_tdp_ar_8kx32.vhd \
	$(toplevel)/src/common/video/video_mode_v2.vhd \
	$(toplevel)/src/common/video/$(FPGA_VENDOR)/$(FPGA_FAMILY)/video_out_clock_v2.vhd \
	$(toplevel)/src/common/video/video_out_timing_v2.vhd \
	$(toplevel)/src/common/video/char_rom_437_8x16.vhd \
	$(toplevel)/src/common/video/vga_text.vhd \
	$(toplevel)/src/common/video/dvi_tx_encoder.vhd \
 	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/serialiser_10to1_selectio.vhd \
	$(toplevel)/src/designs/$(DESIGN)/display.vhd \
	$(toplevel)/src/common/basic/csr.vhd \
	$(toplevel)/src/designs/MEGAtest/overclock.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/ram_sdp_32x6.vhd \
	$(toplevel)/src/common/basic/xilinx/mux2.vhd \
	$(toplevel)/src/common/hram/$(FPGA_VENDOR)/$(FPGA_FAMILY)/hram_ctrl.vhd \
	$(random_1to1_vhd) \
	$(toplevel)/submodules/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl \
	$(toplevel)/src/designs/MEGAtest/hram_test.vhd \
	$(toplevel)/src/designs/MEGAtest/temp_sense.vhd \
	$(toplevel)/src/common/mb/mcs/mb_mcs_wrapper.vhd \
	$(toplevel)/src/designs/$(DESIGN)/cpu.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(DESIGN).vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(VIVADO_DSN_TOP).vhd
VIVADO_BD_TCL=\
	$(toplevel)/src/common/mb/mcs/mb_mcs.tcl=mbv;100000000;1
VIVADO_PROC_REF=mb_mcs
VIVADO_PROC_CELL=cpu/U0/microblaze_I
VIVADO_DSN_ELF=$(VITIS_DIR)/$(VITIS_ELF_RLS)
VIVADO_SIM_SRC=\
	$(abspath $(XILINX_VIVADO))/data/verilog/src/glbl.v \
	$(toplevel)/src/common/tyto_sim_pkg.vhd \
	$(toplevel)/src/common/video/test/model_tmds_cdr_des.vhd \
	$(toplevel)/src/common/video/test/model_dvi_decoder.vhd \
	$(toplevel)/src/common/video/test/model_vga_sink.vhd \
	$(toplevel)/src/common/hram/test/model_hram.vhd \
	$(toplevel)/src/designs/$(DESIGN)/test/tb_$(VIVADO_DSN_TOP).vhd
VIVADO_SIM_ELF=$(VITIS_DIR)/$(VITIS_ELF_DBG)
VIVADO_SIM_RUN=tb_$(VIVADO_DSN_TOP)
VIVADO_XDC=\
	$(toplevel)/src/boards/$(BOARD)/$(BOARD)$(addprefix _,$(BOARD_VARIANT)).tcl=IMPL \
	$(toplevel)/src/designs/$(DESIGN)/$(VIVADO_DSN_TOP).tcl=IMPL \
	$(toplevel)/src/designs/$(DESIGN)/$(DESIGN).tcl=IMPL
VIVADO_XDC_REF=\
	$(toplevel)/src/common/basic/xilinx/sync.tcl=sync
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_VPKG.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/LUT3.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDELAYCTRL.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/ODDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFT.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDELAYE2.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/RAM32X1D.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/RAM32M.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
# timing simulation (Questa/ModelSim)

netlist=$(VIVADO_DIR)/$(VIVADO_DSN_TOP)_timesim.v
$(foreach p,slow fast,$(eval sdf_$p=$(VIVADO_DIR)/$(VIVADO_DSN_TOP)_$p.sdf))

tsim_vhdl=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/tyto_sim_pkg.vhd \
	$(toplevel)/src/common/video/test/model_tmds_cdr_des.vhd \
	$(toplevel)/src/common/video/test/model_dvi_decoder.vhd \
	$(toplevel)/src/common/video/test/model_vga_sink.vhd \
	$(toplevel)/src/common/hram/test/model_hram.vhd \
	$(toplevel)/src/designs/$(DESIGN)/test/tb_$(VIVADO_DSN_TOP).vhd

# $1 = SDF process corner (slow or fast), $2 = delay (max or min)
define rr_tsim
.PHONY: $1_$2
sim_$1_$2:
	@$$(MKDIR) -p $$@
$1_$2: $$(netlist) $$(sdf_$1) | sim_$1_$2
	cd sim_$1_$2 && vlog -incr -mfcu -work work $$(abspath $$(netlist))
	cd sim_$1_$2 && vcom -2008 -work work $$(abspath $$(tsim_vhdl))
	cd sim_$1_$2 && vopt -sdf$2 DUT=$$(abspath $$(sdf_$1)) +acc=npr -suppress 10016 -L work -L simprims_ver -L secureip -work work tb_$$(VIVADO_DSN_TOP) glbl -o tb_$$(VIVADO_DSN_TOP)_opt
	cd sim_$1_$2 && vsim -t ps -sdf$2 DUT=$$(abspath $$(sdf_$1)) +transport_int_delays +pulse_e/0 +pulse_int_e/0 +pulse_r/0 +pulse_int_r/0 -lib work tb_$$(VIVADO_DSN_TOP)_opt
endef

$(foreach p,slow fast,$(foreach d,max min,$(eval $(call rr_tsim,$p,$d))))

################################################################################
