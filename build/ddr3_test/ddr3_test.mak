# ddr3_test.mak

ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif
SUBMODULES:=$(REPO_ROOT)/submodules
MAKE_FPGA:=$(SUBMODULES)/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src

FPGA_TOOL:=vivado

VIVADO_DSN_TOP:=$(DESIGN)_$(BOARD)
VIVADO_DSN_VHDL_2008:=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/ddr3_wrapper_$(BOARD).vhd \
	$(SUBMODULES)/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
VIVADO_DSN_IP_TCL:=\
	$(SRC)/common/ddr3/$(BOARD)/ddr3.tcl
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).xdc
VIVADO_SIM_TOP:=tb_$(VIVADO_DSN_TOP)
VIVADO_SIM_VHDL_2008:=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_SIM_TOP).vhd
VIVADO_SIM_IP_ddr3:=\
    ddr3/ddr3/example_design/sim/ddr3_model.sv \
    ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh

SIMULATOR:=xsim_cmd xsim_ide
SIM_TOP:=$(VIVADO_SIM_TOP)
SIM_SRC:=$(VIVADO_DSN_VHDL_2008) $(VIVADO_SIM_VHDL_2008)
SIM_RUN:=$(SIM_TOP)

VSCODE_TOP:=$(VIVADO_DSN_TOP),$(VIVADO_SIM_TOP)
VSCODE_SRC:=$(VIVADO_DSN_VHDL_2008) $(VIVADO_SIM_VHDL_2008)

include $(MAKE_FPGA)
