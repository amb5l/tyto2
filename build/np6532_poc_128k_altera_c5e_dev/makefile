DESIGN=np6532_poc
RAM_SIZE=128
BOARD=altera_c5e_dev
QUARTUS_PART=5CEFA7F31I7
VENDOR_FAMILY=intel_cyclone_v
VENDOR=intel

REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
QUARTUS_MK=$(SUBMODULES)/quartus-mk

RAM_SIZE_LOG2=$(shell awk 'BEGIN{print 10+log($(RAM_SIZE))/log(2)}')
BUILD_VHDL_DIR=vhdl
PYTHON=python
DECODER_PY=$(SRC)/common/retro/np65/$(VENDOR)/np65_decoder.py
DECODER_CSV=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.vhd
DECODER_MIF=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.mif
RAM_INIT_PY=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd
BUILD_6502_DIR=6502
CA65=ca65
LD65=ld65
FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg
SUCCESS_ADDR_HEX=$(shell grep ";if you get here everything went well" $(BUILD_6502_DIR)/$(FUNCTEST).lst | cut -c 1-6)
SUCCESS_ADDR=$(shell printf "%d\n" 0x$(SUCCESS_ADDR_HEX))
INIT=init
INIT_BIN=$(BUILD_6502_DIR)/$(INIT).bin
INIT_SRC=$(SRC)/designs/$(DESIGN)/6502/$(INIT).a65
INIT_CFG=$(SRC)/designs/$(DESIGN)/6502/$(INIT).cfg

all: sof

QUARTUS_TOP=$(DESIGN)_$(RAM_SIZE)k_$(BOARD)
QUARTUS_MAP_OPTIMIZE=speed
QUARTUS_FIT_EFFORT=auto

QUARTUS_QIP=\
	$(SRC)/common/basic/intel_cyclone_v/pll_otus_50m_96m_32m__28/pll_otus_50m_96m_32m.qip
QUARTUS_SIP=\
	$(SRC)/common/basic/intel_cyclone_v/pll_otus_50m_96m_32m__28/pll_otus_50m_96m_32m.sip
QUARTUS_MIF=\
	$(DECODER_MIF)
QUARTUS_VHDL=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(QUARTUS_TOP).vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/common/basic/tyto_types_pkg.vhd \
	$(SRC)/common/retro/np65/np6532.vhd \
	$(SRC)/common/retro/np65/np6532_core.vhd \
	$(DECODER_VHD) \
	$(SRC)/common/retro/np65/np6532_ram.vhd \
	$(SRC)/common/basic/ram_tdp_s.vhd \
	$(RAM_INIT_VHD) \
	$(SRC)/common/retro/np65/np6532_cache.vhd \
	$(SRC)/common/basic/intel_cyclone_v/ram_sdp_a_32.vhd \
	$(SRC)/common/basic/intel/ldce_bus.vhd
QUARTUS_SDC=\
	$(SRC)/boards/$(BOARD)/$(BOARD).sdc \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).sdc
QUARTUS_TCL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).tcl
QUARTUS_GEN=\
	success_addr=$(SUCCESS_ADDR)

include $(QUARTUS_MK)/quartus.mk

decoder: $(DECODER_VHD) $(DECODER_MIF)
$(DECODER_VHD) $(DECODER_MIF): $(DECODER_CSV) | $(BUILD_VHDL_DIR)
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

clean::
	rm -rf $(BUILD_VHDL_DIR)
	rm -rf $(BUILD_6502_DIR)
