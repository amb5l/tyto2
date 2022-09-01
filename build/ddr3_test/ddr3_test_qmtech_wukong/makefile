DESIGN=ddr3_test
BOARD=qmtech_wukong
VIVADO_PART=xc7a100tfgg676-1

REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

all: bit

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)
VIVADO_SIM_TOP=tb_$(DESIGN)_$(BOARD)

VIVADO_DSN_VHDL_2008=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/ddr3_wrapper_$(BOARD).vhd \
	$(SUBMODULES)/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl

VIVADO_DSN_IP_TCL=\
	$(SRC)/common/ddr3/$(BOARD)/ddr3.tcl

VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).xdc

VIVADO_SIM_OUT=simulate.log

VIVADO_SIM_VHDL_2008=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/tb_$(VIVADO_DSN_TOP).vhd \

VIVADO_SIM_IP_ddr3=\
    ddr3/ddr3/example_design/sim/ddr3_model.sv \
    ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh

include $(XILINX_MK)/xilinx.mk
