# makefile for T65_functest

# path to root of this repository
REPO_ROOT=$(shell git rev-parse --show-toplevel)

# path to this repository's submodules
SUBMODULES=$(REPO_ROOT)/submodules

# path to multisim.mk include
MULTISIM_MK=$(SUBMODULES)/multisim-mk

# this repository's source directory
SRC=$(REPO_ROOT)/src

################################################################################
# 6502 binary

CA65=ca65
LD65=ld65
BUILD_6502_DIR=6502

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg

functest: $(FUNCTEST_BIN)

$(FUNCTEST_BIN): $(BUILD_6502_DIR)/$(FUNCTEST).o $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(FUNCTEST).map -C $(FUNCTEST_CFG)

$(BUILD_6502_DIR)/$(FUNCTEST).o: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(FUNCTEST).lst

################################################################################
# reference execution trace

REF_DIR=ref
REF_FILE=$(abspath $(REF_DIR)/$(FUNCTEST).txt)
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace$(DOT_EXE)

$(REF_DIR):
	mkdir $(REF_DIR)

ref: $(REF_FILE)

$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

################################################################################
# simulation

SOURCES=\
	$(SUBMODULES)/T65/T65_Pack.vhd               \
	$(SUBMODULES)/T65/T65_MCode.vhd              \
	$(SUBMODULES)/T65/T65_ALU.vhd                \
	$(SUBMODULES)/T65/T65.vhd                    \
	$(SRC)/designs/T65_functest/T65_functest.vhd
GENERICS=start_address=1024;bin_file=$(FUNCTEST_BIN);ref_file=$(REF_FILE)
TOP=T65_functest
VHDL_STANDARD=2008
VHDL_RELAXED=TRUE
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE
SIM_DEPS=$(FUNCTEST_BIN) $(REF_FILE)

include $(MULTISIM_MK)/multisim.mk

################################################################################
# cleanup

clean::
	rm -rf $(BUILD_6502_DIR)
	rm -rf $(REF_DIR)
