REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

all: sim

$(SUBMODULES)/mos6502-trace/6502_functional_test.txt: $(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin
	$(SUBMODULES)/mos6502-trace/trace.exe $< 0400 FD 34 > $@

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL
FPGA_PART=xc7a200tsbg484-1
VIVADO_SIM_TOP=T65_functest
VIVADO_SIM_OUT=simulate.log
VIVADO_SIM_VHDL=\
	$(SRC)/designs/T65_functest/T65_functest.vhd \
	$(SUBMODULES)/T65/T65.vhd \
	$(SUBMODULES)/T65/T65_ALU.vhd \
	$(SUBMODULES)/T65/T65_MCode.vhd \
	$(SUBMODULES)/T65/T65_Pack.vhd
VIVADO_SIM_GENERICS=\
	bin_file=$(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin \
	ref_file=$(SUBMODULES)/mos6502-trace/6502_functional_test.txt \
	start_address=1024
VIVADO_SIM_IN=\
	$(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin \
	$(SUBMODULES)/mos6502-trace/6502_functional_test.txt

include $(XILINX_MK)/xilinx.mk
