# mb_fb.mak

ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif
SUBMODULES:=$(REPO_ROOT)/submodules
SRC:=$(REPO_ROOT)/src

FPGA_VENDOR:=$(word 1,$(FPGA))
FPGA_FAMILY:=$(word 2,$(FPGA))
FPGA_DEVICE:=$(word 3,$(FPGA))

VIVADO_PART:=$(FPGA_DEVICE)
VIVADO_PROJ:=fpga
VIVADO_LANG:=VHDL
VIVADO_DSN_TOP:=$(DESIGN)_$(BOARD)
VIVADO_DSN_VHDL_2008:=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/designs/$(DESIGN)/mig_bridge_axi.vhd \
	$(SRC)/designs/$(DESIGN)/mig_bridge_crtc.vhd \
	$(SRC)/designs/$(DESIGN)/mig_hub.vhd \
	$(SRC)/designs/$(DESIGN)/crtc.vhd \
	$(SRC)/designs/$(DESIGN)/dvi_tx.vhd \
	$(SRC)/common/video/video_mode.vhd \
	$(SRC)/common/video/video_out_timing.vhd \
	$(SRC)/common/video/dvi_tx_encoder.vhd \
	$(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/video_out_clock.vhd \
	$(SRC)/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/serialiser_10to1_selectio.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/global_pkg_$(BOARD).vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
VIVADO_DSN_IP_TCL:=$(SRC)/common/ddr3/$(BOARD)/ddr3.tcl
VIVADO_DSN_BD_TCL:=$(SRC)/designs/$(DESIGN)/microblaze.tcl
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).xdc
VIVADO_DSN_PROC_INST:=cpu
VIVADO_DSN_PROC_REF:=microblaze
VIVADO_DSN_ELF_CFG:=Release
VIVADO_SIM_TOP:=tb_$(VIVADO_DSN_TOP)
VIVADO_SIM_VHDL_2008:=\
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/basic/model_fifoctrl_s.vhd \
	$(SRC)/common/ddr3/xilinx/model_mig.vhd \
	$(SRC)/common/video/model_video_out_clock.vhd \
	$(SRC)/common/video/model_tmds_cdr_des.vhd \
	$(SRC)/common/video/model_dvi_decoder.vhd \
	$(SRC)/common/video/model_vga_sink.vhd \
	$(SRC)/designs/$(DESIGN)/tb_crtc_etc.vhd \
	$(SRC)/designs/$(DESIGN)/tb_$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_SIM_TOP).vhd
VIVADO_SIM_IP_ddr3=\
	ddr3/ddr3/example_design/sim/ddr3_model.sv \
	ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh
VIVADO_SIM_ELF_CFG:=Debug

VITIS_APP:=microblaze
VITIS_SRC:=\
	$(SRC)/designs/$(DESIGN)/microblaze/main.c \
	$(SRC)/designs/$(DESIGN)/microblaze/hagl_hal.c \
	$(SRC)/designs/$(DESIGN)/microblaze/hagl_hal.h \
	$(SRC)/common/basic/microblaze/peekpoke.h \
	$(SRC)/common/basic/microblaze/axi_gpio_p.h \
	$(SRC)/common/basic/microblaze/axi_gpio.h \
	$(SRC)/common/basic/microblaze/axi_gpio.c \
	$(SRC)/common/video/microblaze/fb.h \
	$(SRC)/common/video/microblaze/fb.c \
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
VITIS_INCLUDE:=\
	$(SRC)/designs/$(DESIGN)/microblaze \
	$(SRC)/common/basic/microblaze \
	$(SRC)/common/video/microblaze \
	$(SUBMODULES)/hagl/include
VITIS_SYMBOL:=\
	NO_MENUCONFIG \
	HAGL_HAS_HAL_VARIABLE_DISPLAY_SIZE
VITIS_SYMBOL_DEBUG:=\
	BUILD_CONFIG_DEBUG

SIMULATORS:=vivado xsim
SIM_TOP:=$(VIVADO_SIM_TOP)
SIM_SRC:=$(VIVADO_DSN_VHDL_2008) $(VIVADO_SIM_VHDL_2008)

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(VIVADO_DSN_TOP),$(VIVADO_SIM_TOP)
V4P_LIB_SRC:=\
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/secureip/OSERDESE2.vhd

include $(REPO_ROOT)/build/build.mak
