DESIGN=hdmi_tpg
BOARD=qmtech_wukong
VIVADO_PART=xc7a100tfgg676-1

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
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/xilinx_7series/mmcm.vhd \
	$(SRC)/common/video_out/video_mode.vhd \
	$(SRC)/common/video_out/xilinx_7series/video_out_clock.vhd \
	$(SRC)/common/video_out/video_out_timing.vhd \
	$(SRC)/common/video_out/video_out_test_pattern.vhd \
	$(SRC)/common/video_out/vga_to_hdmi.vhd \
	$(SRC)/common/video_out/hdmi_tx_encoder.vhd \
	$(SRC)/common/audio_io/xilinx_7series/audio_clock.vhd \
	$(SRC)/common/audio_io/audio_out_test_tone.vhd \
	$(SRC)/common/basic/xilinx_7series/serialiser_10to1_selectio.vhd \
	$(SRC)/common/basic/sync_reg.vhd

VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).xdc

VIVADO_SIM_OUT=simulate.log

VIVADO_SIM_VHDL=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_SIM_TOP).vhd \
	$(SRC)/common/video_out/model_hdmi_decoder.vhd \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd \
	$(SRC)/common/video_out/model_video_out_clock.vhd \
	$(SRC)/common/tyto_sim_pkg.vhd

################################################################################

include $(XILINX_MK)/xilinx.mk
