# np6532.mak

SRC=$(REPO_ROOT)/src

# definitions for building VHDL source from data

BUILD_VHDL_DIR=vhdl
PYTHON=python
DECODER_PY=$(SRC)/common/retro/np65/$(VENDOR)/np65_decoder.py
DECODER_CSV=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.vhd
DECODER_MIF=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.mif
RAM_INIT_PY=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd

# definitions for building 6502 binaries

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

# vendor independant definitions

DSN_TOP=$(DESIGN)_$(RAM_SIZE)k_$(BOARD)

SIMULATORS=vivado xsim ghdl nvc vsim
SIM_TOP=tb_$(DSN_TOP)
SIM_SRC=$(SRC)/designs/$(DESIGN)/$(BOARD)/$(SIM_TOP).vhd

GENERICS=success_addr=$(SUCCESS_ADDR)

# Vivado definitions

ifeq ($(VENDOR),xilinx)

DSN_SRC=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
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
	$(SRC)/common/basic/$(VENDOR)_$(FAMILY)/mmcm.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).vhd

VIVADO_PART=$(PART)
VIVADO_PROJ=fpga
VIVADO_LANG=VHDL
VIVADO_DSN_TOP=$(DSN_TOP)
VIVADO_DSN_VHDL=$(DSN_SRC)
VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).tcl
VIVADO_DSN_GENERICS=$(GENERICS)
VIVADO_SIM_TOP=$(SIM_TOP)
VIVADO_SIM_VHDL_2008=$(SIM_SRC)
VIVADO_SIM_GENERICS=$(GENERICS)

V4P_XSRC=\
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/LDCE.vhd

endif

# Quartus definitions

ifeq ($(VENDOR),intel)

DSN_SRC=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/ram_tdp_s.vhd \
	$(SRC)/common/basic/intel_cyclone_v/ram_sdp_a_32.vhd \
	$(SRC)/common/basic/intel/ldce_bus.vhd \
	$(RAM_INIT_VHD) \
	$(SRC)/common/retro/np65/np6532_ram.vhd \
	$(SRC)/common/retro/np65/np6532_cache.vhd \
	$(DECODER_VHD) \
	$(SRC)/common/retro/np65/np6532_core.vhd \
	$(SRC)/common/retro/np65/np6532.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).vhd

QUARTUS_PART=$(PART)
QUARTUS_TOP=$(DSN_TOP)
QUARTUS_MAP_OPTIMIZE=speed
QUARTUS_FIT_EFFORT=auto
QUARTUS_QIP=$(SRC)/common/basic/$(VENDOR)_$(FAMILY)/pll_otus_50m_96m_32m__28/pll_otus_50m_96m_32m.qip
QUARTUS_SIP=$(SRC)/common/basic/$(VENDOR)_$(FAMILY)/pll_otus_50m_96m_32m__28/pll_otus_50m_96m_32m.sip
QUARTUS_MIF=$(DECODER_MIF)
QUARTUS_VHDL=$(DSN_SRC)
QUARTUS_SDC=\
	$(SRC)/boards/$(BOARD)/$(BOARD).sdc \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).sdc
QUARTUS_TCL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).tcl
QUARTUS_GEN=$(GENERICS)
QUARTUS_PGM_DEV=$(JTAG_POS)

V4P_XSRC=\
	work;$(SRC)/common/basic/$(VENDOR)_$(FAMILY)/pll_otus_50m_96m_32m/pll_otus_50m_96m_32m_sim/pll_otus_50m_96m_32m.vho \
	altera_lnsim;$(QUARTUS_ROOTDIR)/libraries/vhdl/altera_lnsim/altera_lnsim_components.vhd \
	altera_mf;$(QUARTUS_ROOTDIR)/libraries/vhdl/altera_mf/altera_mf_components.vhd

endif

# targets and recipes for VHDL source and 6502 binaries

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
