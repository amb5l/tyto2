REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules

all: run
	$(info $(shell date))

#------------------------------------------------------------------------------
# 6502 binary

CA65=ca65
LD65=ld65
BUILD_6502_DIR=6502/
FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg

bin: $(FUNCTEST_BIN)

$(FUNCTEST_BIN): $(BUILD_6502_DIR)/$(FUNCTEST).o $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(FUNCTEST).map -C $(FUNCTEST_CFG)

$(BUILD_6502_DIR)/$(FUNCTEST).o: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(FUNCTEST).lst

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

#------------------------------------------------------------------------------
# reference execution trace

REF_DIR=ref/
REF_FILE=$(REF_DIR)/$(FUNCTEST).txt
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace.exe

ref: $(REF_FILE)

$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

$(REF_DIR):
	mkdir $(REF_DIR)

#------------------------------------------------------------------------------
# simulation

# NVC simulator and option flags (global, analysis, elaboration and runtime)
NVC=nvc
NVCGFLAGS=--std=08
NVCAFLAGS=--relaxed
NVCEFLAGS=-gbin_file="$(FUNCTEST_BIN)" -gref_file="$(REF_FILE)" -gstart_address=1024
NVCRFLAGS=

# simulation work library (and directory) name
NVC_WORK=work
NVC_WORK_DIR=$(NVC_WORK)/
NVC_WORK_NAME=$(shell echo $(NVC_WORK)| tr a-z A-Z)

# analysis dependancies and rules
define ANA
NVC_TOP=$(1)
NVC_IR=$(NVC_IR) $(NVC_WORK_DIR)$(NVC_WORK_NAME).$(1)
$(NVC_WORK_DIR)$(NVC_WORK_NAME).$(1): $(2)
	$(NVC) $(NVCGFLAGS) -a $$< $(NVCAFLAGS)
endef
$(eval $(call ANA,T65_PACK,     $(SUBMODULES)/T65/T65_Pack.vhd))
$(eval $(call ANA,T65_MCODE,    $(SUBMODULES)/T65/T65_MCode.vhd))
$(eval $(call ANA,T65_ALU,      $(SUBMODULES)/T65/T65_ALU.vhd))
$(eval $(call ANA,T65,          $(SUBMODULES)/T65/T65.vhd))
$(eval $(call ANA,T65_FUNCTEST, $(SRC)/designs/T65_functest/T65_functest.vhd))

analyse: $(NVR_IR)

# runtime DLL filename - derive from top entity name (or specify manually)
NVC_DLL=$(NVC_WORK_DIR)/$(shell echo _$(NVC_WORK_NAME).$(NVC_TOP)| tr a-z A-Z).elab.dll

# elaborate
elaborate: $(NVC_DLL)

$(NVC_DLL): $(NVC_IR)
	$(NVC) $(NVCGFLAGS) -e $(NVC_TOP) $(NVCEFLAGS)

# run
run: $(NVC_DLL) $(REF_FILE) $(FUNCTEST_BIN)
	$(info $(shell date))
	$(NVC) $(NVCGFLAGS) -r $(NVC_TOP) $(NVCRFLAGS)

#------------------------------------------------------------------------------
# cleanup

clean:
	rm -rf $(SIM_WORK)
	rm -rf $(BUILD_6502_DIR)
	rm -rf $(REF_DIR)
