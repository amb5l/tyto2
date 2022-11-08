# makefile for tb_saa5050

# path to root of this repository
REPO_ROOT=$(shell cygpath -m $(shell git rev-parse --show-toplevel))

# path to this repository's submodules
SUBMODULES=$(REPO_ROOT)/submodules

# path to multisim.mk include
MULTISIM_MK=$(SUBMODULES)/multisim-mk

# this repository's source directory
SRC=$(REPO_ROOT)/src

# saa5050 variant suffix (blank or d)
VARIANT=

# source files in compilation order
SOURCES=\
	$(SRC)/common/tyto_types_pkg.vhd                          \
	$(SRC)/common/retro/saa5050/saa5050_rom_data.vhd          \
	$(SRC)/common/retro/saa5050/saa5050$(VARIANT).vhd         \
	$(SRC)/common/retro/hd6845/hd6845.vhd                     \
	$(SRC)/common/tyto_sim_pkg.vhd                            \
	$(SRC)/common/retro/saa5050/test/tb_saa5050$(VARIANT).vhd

# tests and associated generics
TESTS=engtest scarybeasts parrot
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
DATA_DIR=$(SRC)/common/retro/saa5050/test
GENERICS=$(foreach TEST,$(TESTS),infile=$(DATA_DIR)/$(TEST).bin;outfile=$(basename $(MAKE_DIR)/$(TEST)$(VARIANT).bmp))

# top unit name
TOP=tb_saa5050$(VARIANT)

# VHDL standard
VHDL_STANDARD=2008

# relaxed VHDL rules e.g. impure behaviour by pure functions
VHDL_RELAXED=TRUE

# suppress IEEE assertions e.g. metavalues in to_integer
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

# include multisim.mk here
include $(MULTISIM_MK)/multisim.mk

# post simulation recipes
define RR_CHECK
sim::
	sha256sum --check $1
endef
$(foreach TEST,$(TESTS),$(eval $(call RR_CHECK,$(DATA_DIR)/$(TEST)$(VARIANT).bmp.sha256)))

# custom cleanup
clean::
	rm -f $(wildcard *.bmp)
