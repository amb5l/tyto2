DESIGN=ps2
VIVADO_PART=xc7a200tsbg484-1

REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

all: sim

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_SIM_TOP=tb_$(DESIGN)
VIVADO_SIM_VHDL=\
	$(SRC)/common/retro/$(DESIGN)/tb_$(DESIGN).vhd \
	$(SRC)/common/retro/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/tyto_sim_pkg.vhd \

include $(XILINX_MK)/xilinx.mk
