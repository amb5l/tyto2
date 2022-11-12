# makefile for np6532_functest

all: fail

MAKE_DIR:=$(shell cygpath -m -a .)
REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
SUBMODULES:=$(REPO_ROOT)/submodules
SRC:=$(REPO_ROOT)/src

DESIGN:=np6532_functest
FPGA_VENDOR:=xilinx
RAM_SIZE:=128

# 6502 binary definitions

CA65:=ca65
LD65:=ld65
BUILD_6502_DIR:=6502
FUNCTEST:=6502_functional_test
FUNCTEST_SRC:=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG:=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg
FUNCTEST_BIN:=$(BUILD_6502_DIR)/$(FUNCTEST).bin
INIT:=init
INIT_BIN:=$(BUILD_6502_DIR)/$(INIT).bin
NMI:=nmi
NMI_BIN:=$(BUILD_6502_DIR)/$(NMI).bin
IRQ:=irq
IRQ_BIN:=$(BUILD_6502_DIR)/$(IRQ).bin

# reference execution trace defintions

REF_DIR:=reftrace
REF_FILE:=$(REF_DIR)/$(FUNCTEST).txt
MOS6502_TRACE:=$(SUBMODULES)/mos6502-trace/trace
ifeq ($(OS),Windows_NT)
MOS6502_TRACE:=$(MOS6502_TRACE).exe
endif

# definitions for generating VHDL source from data

BUILD_VHDL_DIR:=vhdl
PYTHON:=python3
DECODER_PY:=$(SRC)/common/retro/np65/$(FPGA_VENDOR)/np65_decoder.py
DECODER_CSV:=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD:=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.vhd
RAM_INIT_PY:=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD:=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd

# simulation

SIMULATORS:=ghdl nvc vsim xsim
SIM_TOP:=$(DESIGN)
SIM_SRC:=\
	$(SRC)/common/tyto_types_pkg.vhd                        \
	$(SRC)/common/tyto_utils_pkg.vhd                        \
	$(SRC)/common/basic/$(FPGA_VENDOR)/ram_sdp_a_32.vhd     \
	$(SRC)/common/basic/ram_tdp_s.vhd                       \
	$(SRC)/common/basic/$(FPGA_VENDOR)/ldce_bus.vhd         \
	$(RAM_INIT_VHD)                                         \
	$(SRC)/common/retro/np65/np6532_ram.vhd                 \
	$(SRC)/common/retro/np65/np6532_cache.vhd               \
	$(DECODER_VHD)                                          \
	$(SRC)/common/retro/np65/np6532_core.vhd                \
	$(SRC)/common/retro/np65/np6532.vhd                     \
	$(SUBMODULES)/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd

SIM_RUN:=$(SIM_TOP),vector_init=64512;start_address=1024;ref_file=$(shell cygpath -m -a $(REF_FILE));progress_interval=1000

GHDL_LIBS:=xilinx-vivado
NVC_GOPTS:=-M 32m

# Visual Studio Code and V4P support

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(SIM_TOP)
V4P_LIB_SRC:=\
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/LDCE.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/RAM64X1D.vhd

# heavy lifting

include $(REPO_ROOT)/build/build.mak

# additional simulation prerequisites

sim:: .EXTRA_PREREQS=$(REF_FILE)

# 6502 binary rules and recipes

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

.PHONY: functest
functest: $(FUNCTEST_BIN)

$(FUNCTEST_BIN): $(BUILD_6502_DIR)/$(FUNCTEST).o $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(FUNCTEST).map -C $(FUNCTEST_CFG)

$(BUILD_6502_DIR)/$(FUNCTEST).o: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	echo "ca65 target is $@, prereqs are $?"
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(FUNCTEST).lst

.PHONY: init
init: $(INIT_BIN)

.PHONY: nmi
nmi: $(NMI_BIN)

.PHONY: irq
irq: $(IRQ_BIN)

$(BUILD_6502_DIR)/%.bin: $(BUILD_6502_DIR)/%.o $(SRC)/designs/$(DESIGN)/6502/%.cfg
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(basename $(@F)).map -C $(SRC)/designs/$(DESIGN)/6502/$(basename $(@F)).cfg

$(BUILD_6502_DIR)/%.o: $(SRC)/designs/$(DESIGN)/6502/%.a65 | $(BUILD_6502_DIR)
	echo "ca65 target is $<"
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(basename $(@F)).lst

# reference execution trace rules and recipes

$(REF_DIR):
	mkdir $(REF_DIR)

.PHONY: ref
ref: $(REF_FILE)

$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

# rules and recipes for generating VHDL source from data

$(BUILD_VHDL_DIR):
	mkdir $(BUILD_VHDL_DIR)

.PHONY: decoder
decoder: $(DECODER_VHD)

$(DECODER_VHD): $(DECODER_CSV) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(DECODER_PY) $< $(@D)/

.PHONY: raminit
raminit: $(RAM_INIT_VHD)

$(RAM_INIT_VHD): $(FUNCTEST_BIN) $(NMI_BIN) $(IRQ_BIN) $(INIT_BIN) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(RAM_INIT_PY) $(RAM_SIZE) 0 $(FUNCTEST_BIN) F000 $(NMI_BIN) F100 $(IRQ_BIN) FC00 $(INIT_BIN) > $@
