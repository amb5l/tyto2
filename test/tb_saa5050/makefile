# makefile for tb_saa5050

include $(shell realpath --relative-to . $(shell git rev-parse --show-toplevel))/submodules/make-fpga/make-fpga-h.mak

SRC:=$(REPO_ROOT)/src

DESIGN?=tb_saa5050
VARIANT?=

SIM_TOP:=$(DESIGN)$(VARIANT)
SIM_SRC:=\
	$(SRC)/common/tyto_types_pkg.vhd                          \
	$(SRC)/common/retro/saa5050/saa5050_rom_data.vhd          \
	$(SRC)/common/retro/saa5050/saa5050$(VARIANT).vhd         \
	$(SRC)/common/retro/hd6845/hd6845.vhd                     \
	$(SRC)/common/tyto_sim_pkg.vhd                            \
	$(SRC)/common/retro/saa5050/test/tb_saa5050$(VARIANT).vhd

VSCODE_TOP:=$(SIM_TOP)
VSCODE_SRC:=$(SIM_SRC)

MAKE_DIR:=$(realpath $(dir $(lastword $(MAKEFILE_LIST))))
ifeq ($(OS),Windows_NT)
MAKE_DIR:=$(shell cygpath -m $(MAKE_DIR))
endif
TESTS:=engtest scarybeasts parrot
DATA_DIR:=$(SRC)/common/retro/saa5050/test
SIM_RUN=$(foreach t,$(TESTS),$t,$(SIM_TOP),infile=$(DATA_DIR)/$t.bin;outfile=$(MAKE_DIR)$(VARIANT)/$(notdir $(SIM_DIR))/$t$(VARIANT))

include $(MAKE_FPGA)

# check correctness of outputs
sim:: $(addprefix $(DATA_DIR)/,$(addsuffix $(VARIANT).bmp.sha256,$(TESTS)))
	$(foreach d,$(SIM_DIR),cd $d && echo $d: && cat $^ | dos2unix | sha256sum -c && cd ..; )
