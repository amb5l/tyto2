DESIGN=otus
BOARD=qmtech_wukong
VIVADO_PART=xc7a100tfgg676-1
VENDOR=xilinx
VENDOR_FAMILY=xilinx_7series

REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

TESTCARD=$(SRC)/common/retro/saa5050/test/engtest.bin

all: sim

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)
# VIVADO_SIM_TOP=tb_$(VIVADO_DSN_TOP)
VIVADO_SIM_TOP=tb_otus_video_out_ttx

#	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
#	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd
VIVADO_DSN_VHDL=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/designs/otus/otus_conductor.vhd \
	$(SRC)/common/retro/hd6845/hd6845.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/designs/otus/otus_overscan.vhd \
	$(SRC)/common/retro/saa5050/saa5050d.vhd \
	$(SRC)/common/retro/saa5050/saa5050_rom_data.vhd \
	$(SRC)/designs/otus/otus_vidproc.vhd \
	$(SRC)/common/video_out/video_mode.vhd \
	$(SRC)/common/video_out/video_out_timing.vhd \
	$(SRC)/designs/otus/otus_upscale.vhd \
	$(SRC)/common/basic/$(VENDOR)/ram_tdp_ar.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd

VIVADO_SIM_OUT=simulate.log
VIVADO_SIM_VHDL=\
	$(SRC)/designs/otus/test/tb_otus_video_out_ttx.vhd \
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/basic/model_clk_src.vhd
VIVADO_SIM_GENERICS=\
	filename=$(abspath $(TESTCARD))
VIVADO_SIM_IN=\
	$(TESTCARD)

include $(XILINX_MK)/xilinx.mk
