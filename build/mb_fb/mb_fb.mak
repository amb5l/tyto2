# mb_fb.mak

SRC:=$(REPO_ROOT)/src

DSN_TOP:=$(DESIGN)_$(BOARD)
DSN_SRC:=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
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
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/global_pkg_$(BOARD).vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).vhd

SIMULATORS:=vivado xsim
SIM_TOP:=tb_$(DSN_TOP)
SIM_SRC:=\
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/basic/model_fifoctrl_s.vhd \
	$(SRC)/common/ddr3/xilinx/model_mig.vhd \
	$(SRC)/common/video_out/model_video_out_clock.vhd \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd \
	$(SRC)/common/video_out/model_dvi_decoder.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd \
	$(SRC)/designs/$(DESIGN)/tb_crtc_etc.vhd \
	$(SRC)/designs/$(DESIGN)/tb_$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(SIM_TOP).vhd

VIVADO_PART:=$(PART)
VIVADO_PROJ=fpga
VIVADO_LANG=VHDL
VIVADO_DSN_TOP=$(DSN_TOP)
VIVADO_DSN_VHDL_2008=$(DSN_SRC)
VIVADO_DSN_IP_TCL=$(SRC)/common/ddr3/$(BOARD)/ddr3.tcl
VIVADO_DSN_BD_TCL=$(SRC)/designs/$(DESIGN)/microblaze.tcl
VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).xdc
VIVADO_DSN_PROC_INST=cpu
VIVADO_DSN_PROC_REF=microblaze
VIVADO_DSN_ELF_CFG=Release
VIVADO_SIM_TOP=tb_$(DESIGN)_$(BOARD)
VIVADO_SIM_VHDL_2008=$(SIM_SRC)
VIVADO_SIM_IP_ddr3=\
	ddr3/ddr3/example_design/sim/ddr3_model.sv \
	ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh
VIVADO_SIM_ELF_CFG=Debug

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
