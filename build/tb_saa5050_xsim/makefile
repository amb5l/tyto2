DESIGN=tb_saa5050
VIVADO_PART=xc7a200tsbg484-1
VENDOR=xilinx
VENDOR_FAMILY=xilinx_7series

REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

all: check

check: sim
	sha1sum -c $(DESIGN)_0.bmp.sha1

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_SIM_TOP=$(DESIGN)
VIVADO_SIM_OUT=$(DESIGN)_0.bmp
VIVADO_SIM_VHDL=\
	$(SRC)/common/retro/saa5050/$(DESIGN).vhd \
    $(SRC)/common/video_out/sim_video_out_pkg.vhd \
	$(SRC)/common/retro/saa5050/saa5050.vhd \
	$(SRC)/common/retro/saa5050/saa5050_rom_data.vhd \
	$(SRC)/common/retro/hd6845/hd6845.vhd

include $(XILINX_MK)/xilinx.mk
