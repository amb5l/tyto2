#################################################################################
# MEGAtest.mak
#################################################################################

default: bit

toplevel=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

#################################################################################
# Vitis

VITIS_FLOW=classic
VITIS_SRC=\
	$(toplevel)/src/common/video/microblaze/cb.c \
	$(toplevel)/src/common/video/microblaze/cb.h \
	$(toplevel)/src/common/basic/microblaze/printf.c \
	$(toplevel)/src/common/basic/microblaze/printf.h \
	$(toplevel)/src/common/basic/microblaze/peekpoke.h \
	$(toplevel)/src/designs/$(DESIGN)/software/bsp.c \
	$(toplevel)/src/designs/$(DESIGN)/software/bsp.h \
	$(toplevel)/src/designs/$(DESIGN)/software/main.c
VITIS_INC=\
	$(toplevel)/src/common/basic/microblaze \
	$(toplevel)/src/common/video/microblaze \
	$(toplevel)/src/designs/$(DESIGN)/software
VITIS_SYM=APP_NAME=$(DESIGN)$(addprefix _,$(BOARD_VARIANT))
VITIS_SYM_RLS=BUILD_CONFIG_RLS
VITIS_SYM_DBG=BUILD_CONFIG_DBG

include $(make_fpga)/vitis.mak

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(DESIGN)$(addprefix _,$(BOARD_VARIANT))
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm_v2.vhd \
	$(toplevel)/src/designs/$(DESIGN)/clk_rst.vhd \
	$(toplevel)/src/common/mb/mcs/mb_mcs_wrapper.vhd \
	$(toplevel)/src/designs/$(DESIGN)/cpu.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/ram_tdp_ar_8kx32_16kx16.vhd \
	$(toplevel)/src/common/video/video_mode_v2.vhd \
	$(toplevel)/src/common/basic/sync_reg.vhd \
	$(toplevel)/src/common/video/$(FPGA_VENDOR)/$(FPGA_FAMILY)/video_out_clock.vhd \
	$(toplevel)/src/common/basic/sync_reg_u.vhd \
	$(toplevel)/src/common/video/video_out_timing_v2.vhd \
	$(toplevel)/src/common/video/char_rom_437_8x16.vhd \
	$(toplevel)/src/common/video/vga_text.vhd \
	$(toplevel)/src/common/video/dvi_tx_encoder.vhd \
 	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/serialiser_10to1_selectio.vhd \
	$(toplevel)/src/designs/$(DESIGN)/display.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(DESIGN).vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(VIVADO_DSN_TOP).vhd
VIVADO_BD_TCL=\
	$(toplevel)/src/common/mb/mcs/mb_mcs.tcl=mbv;100000000;1
VIVADO_PROC_REF=mb_mcs
VIVADO_PROC_CELL=cpu/U0/microblaze_I
VIVADO_DSN_ELF=$(VITIS_DIR)/$(VITIS_ELF_RLS)
VIVADO_SIM_SRC=\
	$(toplevel)/src/designs/$(DESIGN)/tb_$(VIVADO_DSN_TOP).vhd
VIVADO_SIM_ELF=$(VITIS_DIR)/$(VITIS_ELF_DBG)
VIVADO_SIM_RUN=tb_$(VIVADO_DSN_TOP)
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
