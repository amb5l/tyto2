REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules

all: run
	$(info $(shell date))

#------------------------------------------------------------------------------
# 6502 binary

CA65=ca65
LD65=ld65
BUILD_6502_DIR=6502
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

REF_DIR=ref
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
SIM_WORK=work

# top entity name
SIM_TOP=T65_functest

# VHDL source files
SIM_VHDL=\
	$(SUBMODULES)/T65/T65_Pack.vhd \
	$(SUBMODULES)/T65/T65_MCode.vhd \
	$(SUBMODULES)/T65/T65_ALU.vhd \
	$(SUBMODULES)/T65/T65.vhd \
	$(SRC)/designs/T65_functest/T65_functest.vhd

# runtime DLL filename - derive from top entity name (or specify manually)
SIM_DLL=$(SIM_WORK)/$(shell echo _$(SIM_WORK).$(SIM_TOP) | tr a-z A-Z).elab.dll

run: $(SIM_DLL) $(REF_FILE) $(FUNCTEST_BIN)
	$(info $(shell date))
	$(NVC) $(NVCGFLAGS) -r $(SIM_TOP) $(NVCRFLAGS)

# elaboration output depends on intermediate files produced by analysis
# can normally derive from source file names but may need to specify manually
SIM_IR=$(addprefix $(SIM_WORK)/,$(shell echo $(addprefix $(SIM_WORK).,$(basename $(notdir $(SIM_VHDL)))) | tr a-z A-Z))

elaborate: $(SIM_DLL)

$(SIM_DLL): $(SIM_IR)
	$(NVC) $(NVCGFLAGS) -e $(SIM_TOP) $(NVCEFLAGS)

analyse: $(SIM_IR)

# analysis output (intermediate files) depend on sources
# can normally auto-generate rules/dependencies but may need to specify manually
# each rule normally takes the form
# INTERMEDIATE_FILE: source_file
#     $(NVC) $(NVCGFLAGS) -a source_file $(NVCAFLAGS)
define RR_ANALYSE
$(SIM_WORK)/$(shell echo $(addprefix $(SIM_WORK).,$(basename $(notdir $(1)))) | tr a-z A-Z): $(1)
	$(NVC) $(NVCGFLAGS) -a $(1) $(NVCAFLAGS)
endef
$(foreach X,$(SIM_VHDL),$(eval $(call RR_ANALYSE,$X)))

#------------------------------------------------------------------------------
# cleanup

clean:
	rm -rf $(SIM_WORK)
	rm -rf $(BUILD_6502_DIR)
	rm -rf $(REF_DIR)
