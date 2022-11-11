# makefile for T65_functest

REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
SUBMODULES:=$(REPO_ROOT)/submodules
SRC:=$(REPO_ROOT)/src

# 6502 binary definitions

CA65:=ca65
LD65:=ld65
BUILD_6502_DIR:=6502
FUNCTEST:=6502_functional_test
FUNCTEST_BIN:=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC:=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG:=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg

# reference execution trace definitions

REF_DIR:=reftrace
REF_FILE:=$(REF_DIR)/$(FUNCTEST).txt
MOS6502_TRACE:=$(SUBMODULES)/mos6502-trace/trace
ifeq ($(OS),Windows_NT)
MOS6502_TRACE:=$(MOS6502_TRACE).exe
endif

# simulation

SIMULATORS:=ghdl nvc vsim xsim
SIM_TOP:=T65_functest
SIM_SRC:=\
	$(SUBMODULES)/T65/T65_Pack.vhd               \
	$(SUBMODULES)/T65/T65_MCode.vhd              \
	$(SUBMODULES)/T65/T65_ALU.vhd                \
	$(SUBMODULES)/T65/T65.vhd                    \
	$(SRC)/designs/T65_functest/$(SIM_TOP).vhd
SIM_RUN:=$(SIM_TOP),start_address=1024;bin_file=$(shell cygpath -m -a $(FUNCTEST_BIN));ref_file=$(shell cygpath -m -a $(REF_FILE))

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(SIM_TOP)

include $(REPO_ROOT)/build/build.mak

sim:: .EXTRA_PREREQS=$(FUNCTEST_BIN) $(REF_FILE)

# 6502 binary rules and recipes

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

.PHONY: functest
functest: $(FUNCTEST_BIN)

$(FUNCTEST_BIN): $(BUILD_6502_DIR)/$(FUNCTEST).o $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(FUNCTEST).map -C $(FUNCTEST_CFG)

$(BUILD_6502_DIR)/$(FUNCTEST).o: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(FUNCTEST).lst

# reference execution trace rules and recipes

$(REF_DIR):
	mkdir $(REF_DIR)

.PHONY: ref
ref: $(REF_FILE)

$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@
