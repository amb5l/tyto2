# ddr3_test.mak

REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
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

SIMULATORS:=xsim
SIM_TOP:=$(VIVADO_SIM_TOP)
SIM_SRC:=$(VIVADO_DSN_VHDL_2008) $(VIVADO_SIM_VHDL_2008)
SIM_RUN:=$(SIM_TOP)

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(VIVADO_DSN_TOP),$(VIVADO_SIM_TOP)

include $(REPO_ROOT)/build/build.mak
