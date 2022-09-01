# makefile for tb_saa5050d_multisim

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SUBMODULES=$(REPO_ROOT)/submodules
MULTISIM_MK=$(SUBMODULES)/multisim-mk
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)

VHDL_STANDARD=2008
VHDL_RELAXED=TRUE
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

include $(MULTISIM_MK)/multisim_pre.mk

SRC=$(REPO_ROOT)/src
VARIANT=d
$(eval $(call UNIT, tyto_types_pkg       , $(SRC)/common/tyto_types_pkg.vhd                          ,                             ))
$(eval $(call UNIT, saa5050_rom_data     , $(SRC)/common/retro/saa5050/saa5050_rom_data.vhd          ,                             ))
$(eval $(call UNIT, saa5050$(VARIANT)    , $(SRC)/common/retro/saa5050/saa5050$(VARIANT).vhd         ,                             ))
$(eval $(call UNIT, hd6845               , $(SRC)/common/retro/hd6845/hd6845.vhd                     ,                             ))
$(eval $(call UNIT, tyto_sim_pkg         , $(SRC)/common/tyto_sim_pkg.vhd                            , tyto_types_pkg              ))
$(eval $(call UNIT, tb_saa5050$(VARIANT) , $(SRC)/common/retro/saa5050/test/tb_saa5050$(VARIANT).vhd , tyto_sim_pkg tyto_types_pkg ))

include $(MULTISIM_MK)/multisim_post.mk

TESTS=engtest scarybeasts parrot
DATA_DIR=$(SRC)/common/retro/saa5050/test
INFILES=$(addprefix $(DATA_DIR)/,$(addsuffix .bin,$(TESTS)))
OUTFILES=$(addprefix $(MAKE_DIR)/,$(addsuffix $(VARIANT).bmp,$(TESTS)))
CMPFILES=$(addprefix $(DATA_DIR)/,$(addsuffix $(VARIANT).bmp,$(TESTS)))
define RR_OUTFILE
$1: $2 $(RUN_DEP)
	$(call RUN_CMD,infile=$2;outfile=$(basename $1))
endef
$(foreach OUTFILE,$(OUTFILES),$(eval $(call RR_OUTFILE,$(OUTFILE),$(call LOOKUP,$(OUTFILE),$(OUTFILES),$(INFILES)))))
define RR_CMPFILE
$1: $2
	diff --binary $$@ $$<
	touch $$@
endef
$(foreach CMPFILE,$(CMPFILES),$(eval $(call RR_CMPFILE,$(CMPFILE),$(call LOOKUP,$(CMPFILE),$(CMPFILES),$(OUTFILES)))))

run: $(CMPFILES)

clean::
	rm -f $(wildcard *.bmp)
