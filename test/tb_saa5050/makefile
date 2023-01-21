REPO_ROOT:=$(shell git rev-parse --show-toplevel)

DESIGN?=tb_saa5050
VARIANT?=
SRC:=$(REPO_ROOT)/src

SIMULATORS:=ghdl nvc vsim xsim
SIM_TOP:=$(DESIGN)$(VARIANT)
SIM_SRC:=\
	$(SRC)/common/tyto_types_pkg.vhd                          \
	$(SRC)/common/retro/saa5050/saa5050_rom_data.vhd          \
	$(SRC)/common/retro/saa5050/saa5050$(VARIANT).vhd         \
	$(SRC)/common/retro/hd6845/hd6845.vhd                     \
	$(SRC)/common/tyto_sim_pkg.vhd                            \
	$(SRC)/common/retro/saa5050/test/tb_saa5050$(VARIANT).vhd

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(SIM_TOP)

TESTS=engtest scarybeasts parrot
DATA_DIR=$(SRC)/common/retro/saa5050/test
SIM_RUNS=$(foreach t,$(TESTS),$t,$(SIM_TOP),infile=$(DATA_DIR)/$t.bin;outfile=$t$(VARIANT))

include $(REPO_ROOT)/build/build.mak

sim:: $(addprefix $(DATA_DIR)/,$(addsuffix $(VARIANT).bmp.sha256,$(TESTS)))
	cd $(SIM_DIR) && sha256sum --check $^
