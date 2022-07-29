DESIGN=tb_saa5050d
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
	diff --binary $(VIVADO_SIM_PATH)/$(DESIGN)_0.bmp ../../src/common/retro/saa5050/test/$(DESIGN)_0.bmp
	diff --binary $(VIVADO_SIM_PATH)/$(DESIGN)_1.bmp ../../src/common/retro/saa5050/test/tb_saa5050_1.bmp
	diff --binary $(VIVADO_SIM_PATH)/$(DESIGN)_2.bmp ../../src/common/retro/saa5050/test/tb_saa5050_2.bmp

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_SIM_TOP=$(DESIGN)
VIVADO_SIM_OUT=$(DESIGN)_2.bmp
VIVADO_SIM_VHDL=\
	$(SRC)/common/retro/saa5050/test/$(DESIGN).vhd \
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/retro/saa5050/saa5050d.vhd \
	$(SRC)/common/retro/saa5050/saa5050_rom_data.vhd \
	$(SRC)/common/retro/hd6845/hd6845.vhd

include $(XILINX_MK)/xilinx.mk
