DESIGN=mb_fb
BOARD=qmtech_wukong
VIVADO_PART=xc7a100tfgg676-1

REPO_ROOT=$(shell git rev-parse --show-toplevel)
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

VIVADO_DSN_VHDL_2008=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/global_pkg_$(BOARD).vhd \
	$(SRC)/common/basic/tyto_types_pkg.vhd \
	$(SRC)/designs/$(DESIGN)/mig_bridge_axi.vhd \
	$(SRC)/designs/$(DESIGN)/mig_bridge_crtc.vhd \
	$(SRC)/designs/$(DESIGN)/mig_hub.vhd \
	$(SRC)/designs/$(DESIGN)/crtc.vhd \
	$(SRC)/designs/$(DESIGN)/dvi_tx.vhd \
	$(SRC)/common/video_out/video_mode.vhd \
	$(SRC)/common/video_out/video_out_timing.vhd \
	$(SRC)/common/video_out/dvi_tx_encoder.vhd \
	$(SRC)/common/video_out/xilinx_7series/video_out_clock.vhd \
	$(SRC)/common/basic/xilinx_7series/serialiser_10to1_selectio.vhd \
	$(SRC)/common/basic/sync_reg.vhd

VIVADO_DSN_IP_TCL=\
	$(SRC)/common/ddr3/$(BOARD)/ddr3.tcl

VIVADO_DSN_BD_TCL=\
	$(SRC)/designs/$(DESIGN)/microblaze.tcl

VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).xdc

VIVADO_DSN_PROC_INST=cpu

VIVADO_DSN_PROC_REF=microblaze

VIVADO_DSN_ELF_CFG=Release

VIVADO_SIM_OUT=simulate.log

VIVADO_SIM_VHDL_2008=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_SIM_TOP).vhd \
	$(SRC)/designs/$(DESIGN)/tb_$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/tb_crtc_etc.vhd \
	$(SRC)/common/ddr3/xilinx/model_mig.vhd \
	$(SRC)/common/basic/model_fifoctrl_s.vhd \
	$(SRC)/common/video_out/model_dvi_decoder.vhd \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd \
	$(SRC)/common/video_out/model_video_out_clock.vhd \
	$(SRC)/common/video_out/sim_video_out_pkg.vhd

VIVADO_SIM_IP_ddr3=\
	ddr3/ddr3/example_design/sim/ddr3_model.sv \
	ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh

VIVADO_SIM_ELF_CFG=Debug

################################################################################
# Vitis section

VITIS_APP=microblaze

VITIS_SRC=\
	$(SRC)/designs/$(DESIGN)/microblaze/main.c \
	$(SRC)/designs/$(DESIGN)/microblaze/hagl_hal.c \
	$(SRC)/designs/$(DESIGN)/microblaze/hagl_hal.h \
	$(SRC)/common/basic/microblaze/peekpoke.h \
	$(SRC)/common/basic/microblaze/axi_gpio_p.h \
	$(SRC)/common/basic/microblaze/axi_gpio.h \
	$(SRC)/common/basic/microblaze/axi_gpio.c \
	$(SRC)/common/video_out/microblaze/fb.h \
	$(SRC)/common/video_out/microblaze/fb.c \
	$(SUBMODULES)/hagl/src/bitmap.c \
	$(SUBMODULES)/hagl/src/clip.c \
	$(SUBMODULES)/hagl/src/fontx.c \
	$(SUBMODULES)/hagl/src/hagl.c \
	$(SUBMODULES)/hagl/src/hsl.c \
	$(SUBMODULES)/hagl/src/rgb888.c \
	$(SUBMODULES)/hagl/src/rgb565.c \
	$(SUBMODULES)/hagl/src/tjpgd.c \
	$(SUBMODULES)/hagl/include/aps.h \
	$(SUBMODULES)/hagl/include/bitmap.h \
	$(SUBMODULES)/hagl/include/clip.h \
	$(SUBMODULES)/hagl/include/font5x7.h \
	$(SUBMODULES)/hagl/include/font5x8.h \
	$(SUBMODULES)/hagl/include/font6x9.h \
	$(SUBMODULES)/hagl/include/fontx.h \
	$(SUBMODULES)/hagl/include/fps.h \
	$(SUBMODULES)/hagl/include/hagl.h \
	$(SUBMODULES)/hagl/include/hsl.h \
	$(SUBMODULES)/hagl/include/rgb332.h \
	$(SUBMODULES)/hagl/include/rgb565.h \
	$(SUBMODULES)/hagl/include/rgb888.h \
	$(SUBMODULES)/hagl/include/tjpgd.h \
	$(SUBMODULES)/hagl/include/window.h
	
VITIS_INCLUDE=\
	$(SRC)/designs/$(DESIGN)/microblaze \
	$(SRC)/common/basic/microblaze \
	$(SRC)/common/video_out/microblaze \
	$(SUBMODULES)/hagl/include

VITIS_SYMBOL=\
	NO_MENUCONFIG \
	HAGL_HAS_HAL_VARIABLE_DISPLAY_SIZE

VITIS_SYMBOL_DEBUG=\
	BUILD_CONFIG_DEBUG

################################################################################

include $(XILINX_MK)/xilinx.mk
