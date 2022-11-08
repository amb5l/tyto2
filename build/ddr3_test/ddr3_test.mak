# ddr3_test.mak

SRC:=$(REPO_ROOT)/src

DSN_TOP:=$(DESIGN)_$(BOARD)
DSN_SRC:=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/ddr3_wrapper_$(BOARD).vhd \
	$(SUBMODULES)/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).vhd

SIMULATORS:=vivado xsim
SIM_TOP:=tb_$(DSN_TOP)
SIM_SRC:=$(SRC)/designs/$(DESIGN)/$(BOARD)/$(SIM_TOP).vhd

VIVADO_PART:=$(PART)
VIVADO_PROJ:=fpga
VIVADO_LANG:=VHDL
VIVADO_DSN_TOP:=$(DSN_TOP)
VIVADO_DSN_VHDL_2008:=$(DSN_SRC)
VIVADO_DSN_IP_TCL:=\
	$(SRC)/common/ddr3/$(BOARD)/ddr3.tcl
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).xdc
VIVADO_SIM_TOP:=$(SIM_TOP)
VIVADO_SIM_VHDL_2008:=$(SIM_SRC)
VIVADO_SIM_IP_ddr3:=\
    ddr3/ddr3/example_design/sim/ddr3_model.sv \
    ddr3/ddr3/example_design/sim/ddr3_model_parameters.vh
