DESIGN=np6532_functest
RAM_SIZE=64
VIVADO_PART=xc7a200tsbg484-1
VENDOR=xilinx
VENDOR_FAMILY=xilinx_7series


REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

BUILD_VHDL_DIR=vhdl
PYTHON=python
DECODER_PY=$(SRC)/common/retro/np65/$(VENDOR)/np65_decoder.py
DECODER_CSV=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.vhd
RAM_INIT_PY=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd
BUILD_6502_DIR=6502
CA65=ca65
LD65=ld65
FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg
INIT=init
INIT_BIN=$(BUILD_6502_DIR)/$(INIT).bin
INIT_SRC=$(SRC)/designs/$(DESIGN)/6502/$(INIT).a65
INIT_CFG=$(SRC)/designs/$(DESIGN)/6502/$(INIT).cfg
REF_DIR=ref
REF_FILE=$(abspath $(REF_DIR)/$(FUNCTEST).txt)
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace

all: sim

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_SIM_TOP=$(DESIGN)
VIVADO_SIM_OUT=simulate.log
VIVADO_SIM_VHDL=\
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/common/basic/tyto_types_pkg.vhd \
	$(SRC)/common/retro/np65/np6532.vhd \
	$(SRC)/common/retro/np65/np6532_core.vhd \
	$(DECODER_VHD) \
	$(SRC)/common/retro/np65/np6532_ram.vhd \
	$(SRC)/common/basic/ram_tdp_s.vhd \
	$(RAM_INIT_VHD) \
	$(SRC)/common/retro/np65/np6532_cache.vhd \
	$(SRC)/common/basic/$(VENDOR)/ram_sdp_a_32.vhd
VIVADO_SIM_GENERICS=\
	vector_init=64512 \
	start_address=1024 \
	ref_file=$(REF_FILE)
VIVADO_SIM_IN=\
	$(REF_FILE)

include $(XILINX_MK)/xilinx.mk

decoder: $(DECODER_VHD)
$(DECODER_VHD): $(DECODER_CSV) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(DECODER_PY) $< $(@D)/

raminit: $(RAM_INIT_VHD)
$(RAM_INIT_VHD): $(FUNCTEST_BIN) $(INIT_BIN) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(RAM_INIT_PY) $(RAM_SIZE) 0 $(FUNCTEST_BIN) FC00 $(INIT_BIN) > $@

$(BUILD_VHDL_DIR):
	mkdir $(BUILD_VHDL_DIR)

functest: $(FUNCTEST_BIN)
$(FUNCTEST_BIN): $(BUILD_6502_DIR)/$(FUNCTEST).o $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(FUNCTEST).map -C $(FUNCTEST_CFG)

$(BUILD_6502_DIR)/$(FUNCTEST).o: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(FUNCTEST).lst

init: $(INIT_BIN)
$(INIT_BIN): $(BUILD_6502_DIR)/$(INIT).o $(INIT_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(INIT).map -C $(INIT_CFG)

$(BUILD_6502_DIR)/$(INIT).o: $(INIT_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(INIT).lst

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

ref: $(REF_FILE)
$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

$(REF_DIR):
	mkdir $(REF_DIR)

clean::
	rm -rf $(BUILD_VHDL_DIR)
	rm -rf $(BUILD_6502_DIR)
	rm -rf ref
