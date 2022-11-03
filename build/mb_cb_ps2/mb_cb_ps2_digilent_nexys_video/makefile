DESIGN=mb_cb_ps2
BOARD=digilent_nexys_video
VIVADO_PART=xc7a200tsbg484-1
VENDOR=xilinx
VENDOR_FAMILY=xilinx_7series

REPO_ROOT=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

################################################################################
# Vivado section

all: bit

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)
VIVADO_SIM_TOP=tb_$(DESIGN)_$(BOARD)

VIVADO_DSN_VHDL=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/mb_cb/cb.vhd \
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/common/basic/$(VENDOR_FAMILY)/ram_tdp_ar_2kx32_4kx16.vhd \
	$(SRC)/common/ps2/ps2_host.vhd \
	$(SRC)/common/ps2/ps2_to_usbhid.vhd \
	$(SRC)/common/ps2/ps2set2_to_usbhid_pkg.vhd \
	$(SRC)/common/usb/usb_hid_codes_pkg.vhd \
	$(SRC)/common/video_out/char_rom_437_8x16.vhd \
	$(SRC)/common/video_out/video_out_timing.vhd \
	$(SRC)/common/video_out/vga_to_hdmi.vhd \
	$(SRC)/common/video_out/hdmi_tx_encoder.vhd \
	$(SRC)/common/basic/$(VENDOR_FAMILY)/mmcm.vhd \
	$(SRC)/common/basic/$(VENDOR_FAMILY)/serialiser_10to1_selectio.vhd

VIVADO_DSN_BD_TCL=\
	$(SRC)/designs/mb_cb/microblaze.tcl

VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).tcl

VIVADO_DSN_PROC_INST=cpu

VIVADO_DSN_PROC_REF=microblaze

VIVADO_DSN_ELF_CFG=Release

VIVADO_SIM_OUT=simulate.log

VIVADO_SIM_VHDL=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_SIM_TOP).vhd \
	$(SRC)/designs/$(DESIGN)/tb_$(DESIGN).vhd \
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/video_out/model_dvi_decoder.vhd \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd

VIVADO_SIM_ELF_CFG=Debug

################################################################################
# Vitis section

VITIS_APP=microblaze

VITIS_SRC=\
	$(SRC)/designs/$(DESIGN)/microblaze/main.c \
	$(SRC)/common/basic/microblaze/peekpoke.h \
	$(SRC)/common/basic/microblaze/axi_gpio_p.h \
	$(SRC)/common/basic/microblaze/axi_gpio.h \
	$(SRC)/common/basic/microblaze/axi_gpio.c \
	$(SRC)/common/video_out/microblaze/cb.h \
	$(SRC)/common/video_out/microblaze/cb.c \
	$(SRC)/common/basic/microblaze/printf.h \
	$(SRC)/common/basic/microblaze/printf.c
	
VITIS_INCLUDE=\
	$(SRC)/designs/$(DESIGN)/microblaze \
	$(SRC)/common/basic/microblaze \
	$(SRC)/common/video_out/microblaze

################################################################################

include $(XILINX_MK)/xilinx.mk
