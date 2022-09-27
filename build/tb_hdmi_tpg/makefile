# makefile for tb_hdmi_tpg

# path to root of this repository
REPO_ROOT=$(shell git rev-parse --show-toplevel)

# path to this repository's submodules
SUBMODULES=$(REPO_ROOT)/submodules

# path to multisim.mk include
MULTISIM_MK=$(SUBMODULES)/multisim-mk

# this repository's source directory
SRC=$(REPO_ROOT)/src

# number of video modes to test (1..15)
MODES=1

# option: use simulation model instead of encrypted vendor model
NO_SECURE_IP=TRUE

# source files in compilation order
SOURCES:=\
	$(SRC)/common/tyto_types_pkg.vhd                                 \
	$(SRC)/common/tyto_utils_pkg.vhd                                 \
	$(SRC)/common/basic/sync_reg.vhd                                 \
	$(SRC)/common/video_out/video_mode.vhd                           \
	$(SRC)/common/video_out/xilinx_7series/video_out_clock.vhd       \
	$(SRC)/common/video_out/video_out_timing.vhd                     \
	$(SRC)/common/video_out/video_out_test_pattern.vhd               \
	$(SRC)/common/video_out/hdmi_tx_encoder.vhd                      \
	$(SRC)/common/video_out/vga_to_hdmi.vhd                          \
	$(SRC)/common/audio_io/xilinx_7series/audio_clock.vhd            \
	$(SRC)/common/audio_io/audio_out_test_tone.vhd                   \
	$(SRC)/common/basic/xilinx_7series/serialiser_10to1_selectio.vhd \
	$(SRC)/designs/hdmi_tpg/hdmi_tpg.vhd                             \
	$(SRC)/common/tyto_sim_pkg.vhd                                   \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd                   \
	$(SRC)/common/video_out/model_hdmi_decoder.vhd                   \
	$(SRC)/common/video_out/model_vga_sink.vhd                       \
	$(SRC)/common/basic/xilinx_7series/secureip.vhd                  \
	$(SRC)/designs/hdmi_tpg/tb_hdmi_tpg.vhd

ifneq ($(NO_SECURE_IP),)
SOURCES:=$(SOURCES) $(SRC)/designs/hdmi_tpg/cfg_tb_hdmi_tpg_no_secure_ip.vhd
else
SOURCES:=$(SOURCES) $(SRC)/designs/hdmi_tpg/cfg_tb_hdmi_tpg_secure_ip.vhd
endif

GENERICS=modes=$(MODES)

# top unit name
TOP=cfg_tb_hdmi_tpg

# VHDL standard
VHDL_STANDARD=2008

# relaxed VHDL rules e.g. impure behaviour by pure functions
VHDL_RELAXED=TRUE

# suppress IEEE assertions e.g. metavalues in to_integer
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

# GHDL libraries
GHDL_LIBS=xilinx-vivado

# NVC heap size
NVC_GOPTS:=-H 32m $(NVC_GOPTS)

# include multisim.mk here
include $(MULTISIM_MK)/multisim.mk

# custom cleanup
clean::
	rm -f $(wildcard *.bmp)
