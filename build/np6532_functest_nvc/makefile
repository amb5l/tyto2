DESIGN=np6532_functest
RAM_SIZE=128
VENDOR=xilinx

REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules

all: run
	$(info $(shell date))

#------------------------------------------------------------------------------
# 6502 binaries

BUILD_6502_DIR=6502
CA65=ca65
LD65=ld65

# functional test

FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg

functest: $(FUNCTEST_BIN)
$(FUNCTEST_BIN): $(BUILD_6502_DIR)/$(FUNCTEST).o $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(FUNCTEST).map -C $(FUNCTEST_CFG)

$(BUILD_6502_DIR)/$(FUNCTEST).o: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(FUNCTEST).lst

# init

INIT=init
INIT_BIN=$(BUILD_6502_DIR)/$(INIT).bin
INIT_SRC=$(SRC)/designs/$(DESIGN)/6502/$(INIT).a65
INIT_CFG=$(SRC)/designs/$(DESIGN)/6502/$(INIT).cfg

init: $(INIT_BIN)
$(INIT_BIN): $(BUILD_6502_DIR)/$(INIT).o $(INIT_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(INIT).map -C $(INIT_CFG)

$(BUILD_6502_DIR)/$(INIT).o: $(INIT_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(INIT).lst

# NMI handler

NMI=nmi
NMI_BIN=$(BUILD_6502_DIR)/$(NMI).bin
NMI_SRC=$(SRC)/designs/$(DESIGN)/6502/$(NMI).a65
NMI_CFG=$(SRC)/designs/$(DESIGN)/6502/$(NMI).cfg

nmi: $(NMI_BIN)
$(NMI_BIN): $(BUILD_6502_DIR)/$(NMI).o $(NMI_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(NMI).map -C $(NMI_CFG)

$(BUILD_6502_DIR)/$(NMI).o: $(NMI_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(NMI).lst

# IRQ handler

IRQ=irq
IRQ_BIN=$(BUILD_6502_DIR)/$(IRQ).bin
IRQ_SRC=$(SRC)/designs/$(DESIGN)/6502/$(IRQ).a65
IRQ_CFG=$(SRC)/designs/$(DESIGN)/6502/$(IRQ).cfg

irq: $(IRQ_BIN)
$(IRQ_BIN): $(BUILD_6502_DIR)/$(IRQ).o $(IRQ_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(IRQ).map -C $(IRQ_CFG)

$(BUILD_6502_DIR)/$(IRQ).o: $(IRQ_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(IRQ).lst

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

#------------------------------------------------------------------------------
# reference execution trace

REF_DIR=ref
REF_FILE=$(abspath $(REF_DIR)/$(FUNCTEST).txt)
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace

ref: $(REF_FILE)
$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

$(REF_DIR):
	mkdir $(REF_DIR)

#------------------------------------------------------------------------------
# Python scripts to build VHDL

BUILD_VHDL_DIR=vhdl
PYTHON=python

# decoder
DECODER_PY=$(SRC)/common/retro/np65/$(VENDOR)/np65_decoder.py
DECODER_CSV=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.vhd

# RAM init
RAM_INIT_PY=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd

decoder: $(DECODER_VHD)
$(DECODER_VHD): $(DECODER_CSV) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(DECODER_PY) $< $(@D)/

raminit: $(RAM_INIT_VHD)
$(RAM_INIT_VHD): $(FUNCTEST_BIN) $(NMI_BIN) $(IRQ_BIN) $(INIT_BIN) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(RAM_INIT_PY) $(RAM_SIZE) 0 $(FUNCTEST_BIN) F000 $(NMI_BIN) F100 $(IRQ_BIN) FC00 $(INIT_BIN) > $@

$(BUILD_VHDL_DIR):
	mkdir $(BUILD_VHDL_DIR)

#------------------------------------------------------------------------------
# simulation

# NVC simulator and option flags (global, analysis, elaboration and runtime)
NVC=nvc
NVCGFLAGS=--std=08 -M 32m
NVCAFLAGS=--relaxed
NVCEFLAGS=-gvector_init=64512 -gbin_file="$(FUNCTEST_BIN)" -gref_file="$(REF_FILE)" -gstart_address=1024
NVCRFLAGS=

# simulation work library (and directory) name
SIM_WORK=work

# top entity name
SIM_TOP=$(DESIGN)

# VHDL source files
SIM_VHDL=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/basic/$(VENDOR)/ram_sdp_a_32.vhd \
	$(SRC)/common/basic/ram_tdp_s.vhd \
	$(SRC)/common/basic/$(VENDOR)/ldce_bus.vhd \
	$(RAM_INIT_VHD) \
	$(SRC)/common/retro/np65/np6532_ram.vhd \
	$(SRC)/common/retro/np65/np6532_cache.vhd \
	$(DECODER_VHD) \
	$(SRC)/common/retro/np65/np6532_core.vhd \
	$(SRC)/common/retro/np65/np6532.vhd \
	$(SUBMODULES)/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd

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

clean::
	rm -rf $(SIM_WORK)
	rm -rf $(BUILD_VHDL_DIR)
	rm -rf $(BUILD_6502_DIR)
	rm -rf $(REF_DIR)
