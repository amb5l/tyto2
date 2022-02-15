################################################################################
# design: mb_fb_digilent_nexys_video
################################################################################

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

################################################################################

# primary target
all: bit

################################################################################
# Vivado section

# project name
VIVADO_PROJ=fpga

# project language
VIVADO_LANG=VHDL

# FPGA part number
FPGA_PART=xc7a200tsbg484-1

# top entity names
VIVADO_DSN_TOP=mb_fb_digilent_nexys_video
VIVADO_SIM_TOP=tb_mb_fb_digilent_nexys_video

# design sources: VHDL
VIVADO_DSN_VHDL=
VIVADO_DSN_VHDL_2008=\
	$(SRC)/designs/mb_fb/digilent_nexys_video/mb_fb_digilent_nexys_video.vhd \
	$(SRC)/designs/mb_fb/mb_fb.vhd \
	$(SRC)/designs/mb_fb/digilent_nexys_video/global_pkg_digilent_nexys_video.vhd \
	$(SRC)/common/basic/tyto_types_pkg.vhd \
	$(SRC)/designs/mb_fb/mig_bridge_axi.vhd \
	$(SRC)/designs/mb_fb/mig_bridge_crtc.vhd \
	$(SRC)/designs/mb_fb/mig_hub.vhd \
	$(SRC)/designs/mb_fb/crtc.vhd \
	$(SRC)/designs/mb_fb/dvi_tx.vhd \
	$(SRC)/common/video_out/video_mode.vhd \
	$(SRC)/common/video_out/video_out_timing.vhd \
	$(SRC)/common/video_out/dvi_tx_encoder.vhd \
	$(SRC)/common/video_out/xilinx_7series/video_out_clock.vhd \
	$(SRC)/common/basic/xilinx_7series/serialiser_10to1_selectio.vhd

# design sources: TCL scripts to create IP cores (TCL filename should match IP core name)
VIVADO_DSN_IP_TCL=\
	$(SRC)/common/ddr3/digilent_nexys_video/ddr3.tcl

# design sources: TCL scripts to create block diagrams (TCL filename should match BD name)
VIVADO_DSN_BD_TCL=\
	$(SRC)/designs/mb_fb/microblaze.tcl

# design constraints (synthesis and implementation)
VIVADO_DSN_XDC=

# design constraints (synthesis only)
VIVADO_DSN_XDC_SYNTH=

# design constraints (implementation only)
VIVADO_DSN_XDC_IMPL=\
	$(SRC)/designs/mb_fb/digilent_nexys_video/mb_fb_digilent_nexys_video.xdc

# processor instance name
VIVADO_DSN_PROC_INST=cpu

# module containing processor instance (e.g. block diagram)
VIVADO_DSN_PROC_REF=microblaze

# build configuration of ELF file for implementation (Release or Debug)
VIVADO_DSN_ELF_CFG=Release

# simulation output file
VIVADO_SIM_FILE=simulate.log

# simulation sources: VHDL testbenches, models etc
VIVADO_SIM_VHDL=
VIVADO_SIM_VHDL_2008=\
	$(SRC)/designs/mb_fb/digilent_nexys_video/tb_mb_fb_digilent_nexys_video.vhd \
	$(SRC)/designs/mb_fb/tb_mb_fb.vhd \
	$(SRC)/designs/mb_fb/tb_crtc_etc.vhd \
	$(SRC)/common/ddr3/xilinx/model_mig.vhd \
	$(SRC)/common/basic/model_fifoctrl_s.vhd \
	$(SRC)/common/video_out/model_dvi_decoder.vhd \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd \
	$(SRC)/common/video_out/model_video_out_clock.vhd \
	$(SRC)/common/video_out/sim_video_out_pkg.vhd

# IP core simulation models (suffix = IP core name)
# NOTE: these paths are relative to $(VIVADO_PROJ).gen/sources_1/ip
VIVADO_SIM_IP_ddr3=\
	ddr3/ddr3/example_design/sim/ddr3_model.sv \
	ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh

# build configuration of ELF file for simulation (Release or Debug)
VIVADO_SIM_ELF_CFG=Debug

################################################################################
# Vitis section

# app name
VITIS_APP=microblaze

# Vitis app sources
VITIS_SRC=\
	$(SRC)/designs/mb_fb/microblaze/main.c \
	$(SRC)/designs/mb_fb/microblaze/hagl_hal.c \
	$(SRC)/designs/mb_fb/microblaze/hagl_hal.h \
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
	
# Vitis app include paths (Release and Debug configurations)
VITIS_INCLUDE=\
	$(SRC)/designs/mb_fb/microblaze \
    $(SRC)/common/basic/microblaze \
    $(SRC)/common/video_out/microblaze \
	$(SUBMODULES)/hagl/include

# Vitis app include paths (Release configuration only)
VITIS_INCLUDE_RELEASE=

# Vitis app include paths (Debug configuration only)
VITIS_INCLUDE_DEBUG=

# Vitis app symbols (Release and Debug configurations)
VITIS_SYMBOL=\
	NO_MENUCONFIG \
    HAGL_HAS_HAL_VARIABLE_DISPLAY_SIZE

# Vitis app symbols (Release configuration only)
VITIS_SYMBOL_RELEASE=

# Vitis app symbols (Debug configuration only)
VITIS_SYMBOL_DEBUG=\
	BUILD_CONFIG_DEBUG

################################################################################

include $(XILINX_MK)/xilinx.mk
