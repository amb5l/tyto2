#################################################################################
# mb_cb.mak
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
	$(toplevel)/src/designs/$(DESIGN)/microblaze/main.c \
	$(toplevel)/src/common/basic/microblaze/peekpoke.h \
	$(toplevel)/src/common/basic/microblaze/axi_gpio_p.h \
	$(toplevel)/src/common/basic/microblaze/axi_gpio.h \
	$(toplevel)/src/common/basic/microblaze/axi_gpio.c \
	$(toplevel)/src/common/video/microblaze/cb.h \
	$(toplevel)/src/common/video/microblaze/cb.c \
	$(toplevel)/src/common/basic/microblaze/printf.h \
	$(toplevel)/src/common/basic/microblaze/printf.c
VITIS_INC=\
	$(toplevel)/src/designs/$(DESIGN)/microblaze \
	$(toplevel)/src/common/basic/microblaze \
	$(toplevel)/src/common/video/microblaze
VITIS_SYM=APP_NAME=$(DESIGN)
VITIS_SYM_RLS=BUILD_CONFIG_RLS
VITIS_SYM_DBG=BUILD_CONFIG_DBG

include $(make_fpga)/vitis.mak

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)$(addprefix _,$(BOARD_VARIANT))
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/basic/sync_reg.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/ram_tdp_ar_2kx32_4kx16.vhd \
	$(toplevel)/src/common/video/char_rom_437_8x16.vhd \
	$(toplevel)/src/common/video/video_out_timing.vhd \
	$(toplevel)/src/common/video/vga_to_hdmi.vhd \
	$(toplevel)/src/common/video/hdmi_tx_encoder.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/serialiser_10to1_selectio.vhd \
	$(toplevel)/src/designs/$(DESIGN)/cb.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(DESIGN).vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
VIVADO_BD_TCL=$(toplevel)/src/designs/$(DESIGN)/microblaze.tcl
VIVADO_PROC_REF=microblaze
VIVADO_PROC_CELL=cpu
VIVADO_DSN_ELF=$(VITIS_DIR)/$(VITIS_ELF_RLS)
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/tyto_sim_pkg.vhd \
	$(toplevel)/src/common/video/test/model_tmds_cdr_des.vhd \
	$(toplevel)/src/common/video/test/model_dvi_decoder.vhd \
	$(toplevel)/src/common/video/test/model_vga_sink.vhd \
	$(toplevel)/src/designs/$(DESIGN)/tb_$(DESIGN).vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/tb_$(VIVADO_DSN_TOP).vhd
VIVADO_SIM_ELF=$(VITIS_DIR)/$(VITIS_ELF_DBG)
VIVADO_SIM_RUN=tb_$(VIVADO_DSN_TOP)
VIVADO_XDC=\
	$(toplevel)/src/boards/$(BOARD)/$(BOARD)$(addprefix _,$(BOARD_VARIANT)).tcl=IMPL \
	$(toplevel)/src/designs/$(DESIGN)/$(DESIGN).tcl=IMPL
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/RAMB36E1.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/secureip/OSERDESE2.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
