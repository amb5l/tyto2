REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(SUBMODULES)/6502_65C02_functional_tests/bin_files/$(FUNCTEST).bin
REF_DIR=ref
REF_FILE=$(abspath $(REF_DIR)/$(FUNCTEST).txt)
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace.exe

all: sim

ref: $(REF_FILE)
$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

$(REF_DIR):
	mkdir $(REF_DIR)

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
	bin_file=$(FUNCTEST_BIN) \
	ref_file=$(REF_FILE) \
	start_address=1024
VIVADO_SIM_IN=\
	$(FUNCTEST_BIN) \
	$(REF_FILE)

include $(XILINX_MK)/xilinx.mk

clean::
	rm -rf ref
