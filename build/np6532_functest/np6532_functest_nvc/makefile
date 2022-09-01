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

BUILD_6502_DIR=6502/
CA65=ca65
LD65=ld65

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

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

#------------------------------------------------------------------------------
# reference execution trace

REF_DIR=ref/
REF_FILE=$(abspath $(REF_DIR)/$(FUNCTEST).txt)
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace

$(REF_DIR):
	mkdir $(REF_DIR)

ref: $(REF_FILE)

$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

#------------------------------------------------------------------------------
# Python scripts to build VHDL

BUILD_VHDL_DIR=vhdl/
PYTHON=python

$(BUILD_VHDL_DIR):
	mkdir $(BUILD_VHDL_DIR)

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

#------------------------------------------------------------------------------
# simulation

# NVC simulator and option flags (global, analysis, elaboration and runtime)
NVC=nvc
NVCGFLAGS=--std=08 -M 32m
NVCAFLAGS=--relaxed
NVCEFLAGS=-gvector_init=64512 -gref_file="$(REF_FILE)" -gstart_address=1024
NVCRFLAGS=

# simulation work library (and directory) name
NVC_WORK=work
NVC_WORK_DIR=$(NVC_WORK)/
NVC_WORK_NAME=$(shell echo $(NVC_WORK)| tr a-z A-Z)

# analysis dependancies and rules
define ANA
NVC_TOP=$(strip $(1))
NVC_IR=$(NVC_IR) $(NVC_WORK_DIR)$(NVC_WORK_NAME).$(strip $(1))
$(NVC_WORK_DIR)$(NVC_WORK_NAME).$(strip $(1)): $(2)
	$(NVC) $(NVCGFLAGS) -a $$< $(NVCAFLAGS)
endef
$(eval $(call ANA, TYTO_TYPES_PKG                      , $(SRC)/common/tyto_types_pkg.vhd                        ))
$(eval $(call ANA, RAM_SDP_A_32                        , $(SRC)/common/basic/$(VENDOR)/ram_sdp_a_32.vhd          ))
$(eval $(call ANA, RAM_TDP_S                           , $(SRC)/common/basic/ram_tdp_s.vhd                       ))
$(eval $(call ANA, LDCE_BUS                            , $(SRC)/common/basic/$(VENDOR)/ldce_bus.vhd              ))
$(eval $(call ANA, NP6532_RAM_INIT_PKG                 , $(RAM_INIT_VHD)                                         ))
$(eval $(call ANA, NP6532_RAM                          , $(SRC)/common/retro/np65/np6532_ram.vhd                 ))
$(eval $(call ANA, NP6532_CACHE                        , $(SRC)/common/retro/np65/np6532_cache.vhd               ))
$(eval $(call ANA, NP65_DECODER                        , $(DECODER_VHD)                                          ))
$(eval $(call ANA, NP6532_CORE                         , $(SRC)/common/retro/np65/np6532_core.vhd                ))
$(eval $(call ANA, NP6532                              , $(SRC)/common/retro/np65/np6532.vhd                     ))
$(eval $(call ANA, RNG_XOSHIRO128PLUSPLUS              , $(SUBMODULES)/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl ))
$(eval $(call ANA, $(shell echo $(DESIGN)| tr a-z A-Z) , $(SRC)/designs/$(DESIGN)/$(DESIGN).vhd                  ))

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
	rm -rf $(NVC_WORK)
	rm -rf $(BUILD_VHDL_DIR)
	rm -rf $(BUILD_6502_DIR)
	rm -rf $(REF_DIR)
