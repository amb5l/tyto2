DESIGN=np6532_poc
RAM_SIZE=128
BOARD=digilent_nexys_video
VIVADO_PART=xc7a200tsbg484-1
VENDOR_FAMILY=xilinx_7series
VENDOR=xilinx

REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

all: bit

#------------------------------------------------------------------------------
# 6502 binaries from assembler source

BUILD_6502_DIR=6502
CA65=ca65
LD65=ld65

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

# functional test

FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg
SUCCESS_ADDR_HEX=$(shell grep ";if you get here everything went well" $(BUILD_6502_DIR)/$(FUNCTEST).lst | cut -c 1-6)
SUCCESS_ADDR=$(shell printf "%d\n" 0x$(SUCCESS_ADDR_HEX))

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

#------------------------------------------------------------------------------
# VHDL source from data files

BUILD_VHDL_DIR=vhdl
PYTHON=python

$(BUILD_VHDL_DIR):
	mkdir $(BUILD_VHDL_DIR)

# decoder

DECODER_PY=$(SRC)/common/retro/np65/$(VENDOR)/np65_decoder.py
DECODER_CSV=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.vhd

decoder: $(DECODER_VHD)
$(DECODER_VHD): $(DECODER_CSV) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(DECODER_PY) $< $(@D)/

# RAM init

RAM_INIT_PY=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd

raminit: $(RAM_INIT_VHD)
$(RAM_INIT_VHD): $(FUNCTEST_BIN) $(INIT_BIN) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(RAM_INIT_PY) $(RAM_SIZE) 0 $(FUNCTEST_BIN) FC00 $(INIT_BIN) > $@

#------------------------------------------------------------------------------
# Vivado build and simulation

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_DSN_TOP=$(DESIGN)_$(RAM_SIZE)k_$(BOARD)
VIVADO_SIM_TOP=tb_$(DESIGN)_$(RAM_SIZE)k_$(BOARD)

VIVADO_DSN_VHDL=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/basic/ram_tdp_s.vhd \
	$(SRC)/common/basic/$(VENDOR)/ram_sdp_a_32.vhd \
	$(SRC)/common/basic/$(VENDOR)/ldce_bus.vhd \
	$(RAM_INIT_VHD) \
	$(SRC)/common/retro/np65/np6532_ram.vhd \
	$(SRC)/common/retro/np65/np6532_cache.vhd \
	$(DECODER_VHD) \
	$(SRC)/common/retro/np65/np6532_core.vhd \
	$(SRC)/common/retro/np65/np6532.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/common/basic/$(VENDOR_FAMILY)/mmcm.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd

VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).tcl

VIVADO_DSN_GENERICS=\
	success_addr=$(SUCCESS_ADDR)

VIVADO_SIM_OUT=simulate.log

VIVADO_SIM_VHDL_2008=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/tb_$(VIVADO_DSN_TOP).vhd

VIVADO_SIM_GENERICS=\
	success_addr=$(SUCCESS_ADDR)

include $(XILINX_MK)/xilinx.mk

#------------------------------------------------------------------------------
# NVC simulation

include ../gmsl

nvc: nvc_run
	$(info $(shell date))

# NVC simulator and option flags (global, analysis, elaboration and runtime)
NVC=nvc
NVCGFLAGS=--std=08 -M 32m
NVCAFLAGS=--relaxed
NVCEFLAGS=-gsuccess_addr=$(SUCCESS_ADDR)
NVCRFLAGS=

# simulation work library (and directory) name
NVC_WORK=work
NVC_WORK_DIR=$(NVC_WORK)
NVC_WORK_NAME=$(shell echo $(NVC_WORK) | tr a-z A-Z)

# top entity name
NVC_TOP=$(VIVADO_SIM_TOP)

# VHDL source files
NVC_VHDL=$(VIVADO_DSN_VHDL) $(VIVADO_SIM_VHDL_2008)

# intermediate files
NVC_IR=\
	TYTO_TYPES_PKG \
	RAM_TDP_S \
	RAM_SDP_A_32 \
	LDCE_BUS \
	NP6532_RAM_INIT_PKG \
	NP6532_RAM \
	NP6532_CACHE \
	NP65_DECODER \
	NP6532_CORE \
	NP6532 \
	NP6532_POC \
	MMCM \
	NP6532_POC_DIGILENT_NEXYS_VIDEO \
    TB_NP6532_POC_DIGILENT_NEXYS_VIDEO
NVC_IR_FILES=$(addprefix $(NVC_WORK_DIR)/$(NVC_WORK_NAME).,$(NVC_IR))
zip=$(1)&$(2)
NVC_IR_DEPS:=$(call pairmap,zip,$(NVC_IR_FILES),$(NVC_VHDL))

# runtime DLL filename - derive from top entity name (or specify manually)
NVC_DLL=$(NVC_WORK)/$(shell echo _$(NVC_WORK).$(NVC_TOP) | tr a-z A-Z).elab.dll

nvc_run: $(NVC_DLL)
	$(info $(shell date))
	$(NVC) $(NVCGFLAGS) -r $(NVC_TOP) $(NVCRFLAGS)

nvc_elaborate: $(NVC_DLL)

$(NVC_DLL): $(NVC_IR_FILES)
	$(NVC) $(NVCGFLAGS) -e $(NVC_TOP) $(NVCEFLAGS)

nvc_analyse: $(NVC_IR_FILES)

define RR_ANALYSE
$(word 1,$(subst &, ,$(1))): $(word 2,$(subst &, ,$(1)))
	$(NVC) $(NVCGFLAGS) -a $(word 2,$(subst &, ,$(1))) $(NVCAFLAGS)
endef
$(foreach X,$(NVC_IR_DEPS),$(eval $(call RR_ANALYSE,$X)))

#------------------------------------------------------------------------------
# cleanup

clean::
	rm -rf $(BUILD_VHDL_DIR)
	rm -rf $(BUILD_6502_DIR)
	rm -rf .Xil
