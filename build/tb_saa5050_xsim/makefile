DESIGN=tb_saa5050
VIVADO_PART=xc7a200tsbg484-1

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

all: compare

# tests to run are listed here
TESTS=engtest scarybeasts parrot

# reference binaries and bitmaps directory is specified here
REF_DIR=$(SRC)/common/retro/saa5050/test

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_SIM_TOP=$(DESIGN)
VIVADO_SIM_VHDL=\
	$(SRC)/common/retro/saa5050/test/$(DESIGN).vhd \
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/retro/saa5050/saa5050.vhd \
	$(SRC)/common/retro/saa5050/saa5050_rom_data.vhd \
	$(SRC)/common/retro/hd6845/hd6845.vhd

include $(XILINX_MK)/xilinx.mk

# runtime rule/recipe for bitmap dependancies
define RR_BMP
$(VIVADO_SIM_PATH)/$(1).bmp: $(REF_DIR)/$(1).bin $(VIVADO_PROJ_FILE)
	$(VIVADO_MK) simulate gen: filename=$$<
	mv $(VIVADO_SIM_PATH)/$(VIVADO_SIM_TOP)_0.bmp $(VIVADO_SIM_PATH)/$(1).bmp
$(REF_DIR)/$(1).bmp: $(VIVADO_SIM_PATH)/$(1).bmp
	diff --binary $$@ $$<
	touch $$@
endef

$(foreach TEST,$(TESTS),$(eval $(call RR_BMP,$(TEST))))

compare: $(addsuffix .bmp,$(addprefix $(REF_DIR)/,$(TESTS)))
