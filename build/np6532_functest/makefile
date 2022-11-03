# makefile for np6532_functest

# path to root of this repository
REPO_ROOT=$(shell cygpath -m $(shell git rev-parse --show-toplevel))

# path to this repository's submodules
SUBMODULES=$(REPO_ROOT)/submodules

# path to multisim.mk include
MULTISIM_MK=$(SUBMODULES)/multisim-mk

# this repository's source directory
SRC=$(REPO_ROOT)/src

# make directory
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)

################################################################################
# design definitions

DESIGN=np6532_functest
RAM_SIZE=128
VENDOR=xilinx

################################################################################
# 6502 binaries

CA65=ca65
LD65=ld65
BUILD_6502_DIR=6502

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

# functional test

FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg

.PHONY: functest
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

.PHONY: init
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

.PHONY: nmi
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

.PHONY: irq
irq: $(IRQ_BIN)

$(IRQ_BIN): $(BUILD_6502_DIR)/$(IRQ).o $(IRQ_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(IRQ).map -C $(IRQ_CFG)

$(BUILD_6502_DIR)/$(IRQ).o: $(IRQ_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(IRQ).lst

################################################################################
# reference execution trace

REF_DIR=reftrace
REF_FILE=$(REF_DIR)/$(FUNCTEST).txt
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace$(DOT_EXE)

$(REF_DIR):
	mkdir $(REF_DIR)

.PHONY: ref
ref: $(REF_FILE)

$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

################################################################################
# Python scripts to build VHDL

BUILD_VHDL_DIR=vhdl
PYTHON=python3

$(BUILD_VHDL_DIR):
	mkdir $(BUILD_VHDL_DIR)

# decoder
DECODER_PY=$(SRC)/common/retro/np65/$(VENDOR)/np65_decoder.py
DECODER_CSV=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.vhd

# RAM init
RAM_INIT_PY=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd

.PHONY: decoder
decoder: $(DECODER_VHD)

$(DECODER_VHD): $(DECODER_CSV) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(DECODER_PY) $< $(@D)/

.PHONY: raminit
raminit: $(RAM_INIT_VHD)

$(RAM_INIT_VHD): $(FUNCTEST_BIN) $(NMI_BIN) $(IRQ_BIN) $(INIT_BIN) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(RAM_INIT_PY) $(RAM_SIZE) 0 $(FUNCTEST_BIN) F000 $(NMI_BIN) F100 $(IRQ_BIN) FC00 $(INIT_BIN) > $@

################################################################################
# simulation

SOURCES=\
	$(SRC)/common/tyto_types_pkg.vhd                        \
	$(SRC)/common/tyto_utils_pkg.vhd                        \
	$(SRC)/common/basic/$(VENDOR)/ram_sdp_a_32.vhd          \
	$(SRC)/common/basic/ram_tdp_s.vhd                       \
	$(SRC)/common/basic/$(VENDOR)/ldce_bus.vhd              \
	$(RAM_INIT_VHD)                                         \
	$(SRC)/common/retro/np65/np6532_ram.vhd                 \
	$(SRC)/common/retro/np65/np6532_cache.vhd               \
	$(DECODER_VHD)                                          \
	$(SRC)/common/retro/np65/np6532_core.vhd                \
	$(SRC)/common/retro/np65/np6532.vhd                     \
	$(SUBMODULES)/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd
GENERICS=vector_init=64512;start_address=1024;ref_file=$(shell cygpath -m -a $(REF_FILE));progress_interval=1000
TOP=$(DESIGN)
VHDL_STANDARD=2008
VHDL_RELAXED=TRUE
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

# simulation prerequisites
sim:: $(RAM_INIT_VHD) $(DECODER_VHD) $(FUNCTEST_BIN) $(REF_FILE)

# GHDL libraries
GHDL_LIBS=xilinx-vivado

# larger heap size needed for NVC
NVC_GOPTS:=-M 32m $(NVC_GOPTS)

include $(MULTISIM_MK)/multisim.mk

################################################################################
# cleanup

clean::
	rm -rf $(BUILD_6502_DIR)
	rm -rf $(BUILD_VHDL_DIR)
	rm -rf $(REF_DIR)
