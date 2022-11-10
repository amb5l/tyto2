# np6532_poc.mak

REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
SUBMODULES:=$(REPO_ROOT)/submodules
SRC:=$(REPO_ROOT)/src

FPGA_VENDOR:=$(word 1,$(FPGA))
FPGA_FAMILY:=$(word 2,$(FPGA))
FPGA_DEVICE:=$(word 3,$(FPGA))

# definitions for generating VHDL source from data

BUILD_VHDL_DIR:=$(shell cygpath -m -a ./vhdl)
PYTHON:=python
DECODER_PY:=$(SRC)/common/retro/np65/$(FPGA_VENDOR)/np65_decoder.py
DECODER_CSV:=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD:=$(BUILD_VHDL_DIR)/np65_decoder.vhd
DECODER_MIF:=$(BUILD_VHDL_DIR)/np65_decoder.mif
RAM_INIT_PY:=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD:=$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd

# definitions for building 6502 binaries

BUILD_6502_DIR:=$(shell cygpath -m -a ./6502)
CA65:=ca65
LD65:=ld65
FUNCTEST:=6502_functional_test
FUNCTEST_SRC:=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG:=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg
FUNCTEST_OBJ:=$(BUILD_6502_DIR)/$(FUNCTEST).o
FUNCTEST_LST:=$(BUILD_6502_DIR)/$(FUNCTEST).lst
FUNCTEST_MAP:=$(BUILD_6502_DIR)/$(FUNCTEST).map
FUNCTEST_BIN:=$(BUILD_6502_DIR)/$(FUNCTEST).bin
INIT:=init
INIT_SRC:=$(SRC)/designs/$(DESIGN)/6502/$(INIT).a65
INIT_CFG:=$(SRC)/designs/$(DESIGN)/6502/$(INIT).cfg
INIT_OBJ:=$(BUILD_6502_DIR)/$(INIT).o
INIT_LST:=$(BUILD_6502_DIR)/$(INIT).lst
INIT_MAP:=$(BUILD_6502_DIR)/$(INIT).map
INIT_BIN:=$(BUILD_6502_DIR)/$(INIT).bin

# Vivado definitions

ifeq ($(FPGA_VENDOR),xilinx)

VIVADO_PART:=$(FPGA_DEVICE)
VIVADO_PROJ:=fpga
VIVADO_LANG:=VHDL
VIVADO_DSN_TOP:=$(DESIGN)_$(RAM_SIZE)k_$(BOARD)
VIVADO_DSN_VHDL:=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/ram_tdp_s.vhd \
	$(SRC)/common/basic/$(FPGA_VENDOR)/ram_sdp_a_32.vhd \
	$(SRC)/common/basic/$(FPGA_VENDOR)/ldce_bus.vhd \
	$(RAM_INIT_VHD) \
	$(SRC)/common/retro/np65/np6532_ram.vhd \
	$(SRC)/common/retro/np65/np6532_cache.vhd \
	$(DECODER_VHD) \
	$(SRC)/common/retro/np65/np6532_core.vhd \
	$(SRC)/common/retro/np65/np6532.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/mmcm.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).tcl
VIVADO_DSN_GENERICS=success_addr=$(shell printf "%d\n" 0x$(shell grep ";if you get here everything went well" $(FUNCTEST_LST) | cut -c 1-6))
VIVADO_SIM_TOP:=tb_$(VIVADO_DSN_TOP)
VIVADO_SIM_VHDL_2008:=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_SIM_TOP).vhd
VIVADO_SIM_GENERICS=success_addr=$(shell printf "%d\n" 0x$(shell grep ";if you get here everything went well" $(FUNCTEST_LST) | cut -c 1-6))

SIM_TOP:=$(VIVADO_SIM_TOP)
SIM_SRC:=$(VIVADO_DSN_VHDL) $(VIVADO_SIM_VHDL_2008)
GHDL_LIBS:=xilinx-vivado

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(VIVADO_DSN_TOP),$(VIVADO_SIM_TOP)
V4P_LIB_SRC:=\
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/LDCE.vhd

endif

# Quartus definitions

ifeq ($(FPGA_VENDOR),intel)

QUARTUS_PART:=$(FPGA_DEVICE)
QUARTUS_TOP:=$(DESIGN)_$(RAM_SIZE)k_$(BOARD)
QUARTUS_MAP_OPTIMIZE:=speed
QUARTUS_FIT_EFFORT:=auto
QUARTUS_QIP:=$(SRC)/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/pll_otus_50m_96m_32m__28/pll_otus_50m_96m_32m.qip
QUARTUS_SIP:=$(SRC)/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/pll_otus_50m_96m_32m__28/pll_otus_50m_96m_32m.sip
QUARTUS_MIF:=$(DECODER_MIF)
QUARTUS_VHDL:=\
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
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(QUARTUS_TOP).vhd
QUARTUS_SDC:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).sdc \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).sdc
QUARTUS_TCL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).tcl
QUARTUS_GEN=success_addr=$(shell printf "%d\n" 0x$(shell grep ";if you get here everything went well" $(FUNCTEST_LST) | cut -c 1-6))

SIM_TOP:=tb_$(QUARTUS_TOP)
SIM_SRC:=\
	$(QUARTUS_VHDL) \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(SIM_TOP).vhd
GHDL_LIBS:=intel

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(QUARTUS_TOP) $(SIM_TOP)
V4P_LIB_SRC:=\
	work;$(SRC)/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/pll_otus_50m_96m_32m/pll_otus_50m_96m_32m_sim/pll_otus_50m_96m_32m.vho \
	altera_lnsim;$(QUARTUS_ROOTDIR)/libraries/vhdl/altera_lnsim/altera_lnsim_components.vhd \
	altera_mf;$(QUARTUS_ROOTDIR)/libraries/vhdl/altera_mf/altera_mf_components.vhd
	
endif

# simulation definitions

SIMULATORS:=ghdl nvc vsim xsim
SIM_RUN=$(SIM_TOP),success_addr=$(shell printf "%d\n" 0x$(shell grep ";if you get here everything went well" $(FUNCTEST_LST) | cut -c 1-6))

# heavy lifting

include $(REPO_ROOT)/build/build.mak

# rules and recipes for generated VHDL source and 6502 binaries

.PHONY: decoder
decoder: $(DECODER_VHD) $(DECODER_MIF)
$(DECODER_VHD) $(DECODER_MIF) &: $(DECODER_CSV) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(DECODER_PY) $< $(@D)/

.PHONY: raminit
raminit: $(RAM_INIT_VHD)
$(RAM_INIT_VHD): $(FUNCTEST_BIN) $(INIT_BIN) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(RAM_INIT_PY) $(RAM_SIZE) 0 $(FUNCTEST_BIN) FC00 $(INIT_BIN) > $@

$(BUILD_VHDL_DIR):
	mkdir -p $(BUILD_VHDL_DIR)

.PHONY: functest
functest: $(FUNCTEST_BIN)
$(FUNCTEST_BIN): $(FUNCTEST_OBJ) $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(FUNCTEST_MAP) -C $(FUNCTEST_CFG)

$(FUNCTEST_OBJ) $(FUNCTEST_LST) &: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $(FUNCTEST_SRC) -o $(FUNCTEST_OBJ) -l $(FUNCTEST_LST)

.PHONY: init
init: $(INIT_BIN)
$(INIT_BIN): $(INIT_OBJ) $(INIT_CFG)
	$(LD65) $< -o $@ -m $(INIT_MAP) -C $(INIT_CFG)

$(INIT_OBJ) $(INIT_LST) &: $(INIT_SRC) | $(BUILD_6502_DIR)
	$(CA65) $(INIT_SRC) -o $(INIT_OBJ) -l $(INIT_LST)

$(BUILD_6502_DIR):
	mkdir -p $(BUILD_6502_DIR)
