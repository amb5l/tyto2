DESIGN=np6532_poc
RAM_SIZE=256
BOARD=qmtech_wukong
VIVADO_PART=xc7a100tfgg676-1
VENDOR_FAMILY=xilinx_7series
VENDOR=xilinx

REPO_ROOT=$(shell git rev-parse --show-toplevel)
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

RAM_SIZE_LOG2=$(shell awk 'BEGIN{print 10+log($(RAM_SIZE))/log(2)}')
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
SUCCESS_ADDR_HEX=$(shell grep ";if you get here everything went well" $(BUILD_6502_DIR)/$(FUNCTEST).lst | cut -c 1-6)
SUCCESS_ADDR=$(shell printf "%d\n" 0x$(SUCCESS_ADDR_HEX))
INIT=init
INIT_BIN=$(BUILD_6502_DIR)/$(INIT).bin
INIT_SRC=$(SRC)/designs/$(DESIGN)/6502/$(INIT).a65
INIT_CFG=$(SRC)/designs/$(DESIGN)/6502/$(INIT).cfg

all: bit

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_DSN_TOP=$(DESIGN)_$(RAM_SIZE)k_$(BOARD)
VIVADO_SIM_TOP=tb_$(DESIGN)_$(RAM_SIZE)k_$(BOARD)

VIVADO_DSN_VHDL=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/common/basic/tyto_types_pkg.vhd \
	$(SRC)/common/retro/np65/np6532.vhd \
	$(SRC)/common/retro/np65/np6532_core.vhd \
	$(DECODER_VHD) \
	$(SRC)/common/retro/np65/np6532_ram.vhd \
	$(SRC)/common/basic/ram_tdp_s.vhd \
	$(RAM_INIT_VHD) \
	$(SRC)/common/retro/np65/np6532_cache.vhd \
	$(SRC)/common/basic/$(VENDOR)/ram_sdp_a_32.vhd \
	$(SRC)/common/basic/$(VENDOR)/ldce_bus.vhd
VIVADO_DSN_VHDL_2008=\
	$(SRC)/common/basic/$(VENDOR_FAMILY)/mmcm.vhd

VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).tcl

VIVADO_DSN_GENERICS=\
	success_addr=$(SUCCESS_ADDR)

VIVADO_SIM_OUT=simulate.log

VIVADO_SIM_VHDL_2008=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/tb_$(VIVADO_DSN_TOP).vhd \

VIVADO_SIM_GENERICS=\
	success_addr=$(SUCCESS_ADDR)

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

clean::
	rm -rf $(BUILD_VHDL_DIR)
	rm -rf $(BUILD_6502_DIR)
	rm -rf .Xil