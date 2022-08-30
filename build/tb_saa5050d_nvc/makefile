VARIANT=d

all: compare

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src

# NVC simulator and option flags (global, analysis, elaboration and runtime)
NVC=nvc
NVCGFLAGS=--std=08
NVCAFLAGS=--relaxed
NVCRFLAGS=--ieee-warnings=off

# simulation work library (and directory) name
NVC_WORK=work
NVC_WORK_DIR=$(NVC_WORK)/
NVC_WORK_NAME=$(shell echo $(NVC_WORK)| tr a-z A-Z)

# runtime rule/recipe for analysis dependancies
define RR_DEP
NVC_TOP=$(strip $(1))
NVC_IR=$(NVC_IR) $(NVC_WORK_DIR)$(NVC_WORK_NAME).$(strip $(1))
$(NVC_WORK_DIR)$(NVC_WORK_NAME).$(strip $(1)): $(2)
	$(NVC) $(NVCGFLAGS) -a $$< $(NVCAFLAGS)
endef

# design unit dependancies are declared here
$(eval $(call RR_DEP, TYTO_TYPES_PKG	   , $(SRC)/common/tyto_types_pkg.vhd				   ))
$(eval $(call RR_DEP, TYTO_UTILS_PKG	   , $(SRC)/common/tyto_utils_pkg.vhd				   ))
$(eval $(call RR_DEP, SAA5050_ROM_DATA	   , $(SRC)/common/retro/saa5050/saa5050_rom_data.vhd  ))
$(eval $(call RR_DEP, SAA5050$(VARIANT)	   , $(SRC)/common/retro/saa5050/saa5050$(VARIANT).vhd ))
$(eval $(call RR_DEP, HD6845			   , $(SRC)/common/retro/hd6845/hd6845.vhd			   ))
$(eval $(call RR_DEP, TYTO_SIM_PKG		   , $(SRC)/common/tyto_sim_pkg.vhd $(NVC_WORK_DIR)$(NVC_WORK_NAME).TYTO_TYPES_PKG ))
$(eval $(call RR_DEP, TB_SAA5050$(VARIANT) , $(SRC)/common/retro/saa5050/test/tb_saa5050$(VARIANT).vhd $(NVC_WORK_DIR)$(NVC_WORK_NAME).TYTO_SIM_PKG $(NVC_WORK_DIR)$(NVC_WORK_NAME).TYTO_TYPES_PKG ))

$(info $(NVC_IR))

# tests to run are listed here
TESTS=engtest scarybeasts parrot

# reference binaries and bitmaps directory is specified here
REF_DIR=$(SRC)/common/retro/saa5050/test

# fixed rules and recipes follow

# runtime DLL filename - derive from top entity name (or specify manually)
NVC_DLL=$(NVC_WORK_DIR)/$(shell echo _$(NVC_WORK_NAME).$(NVC_TOP)| tr a-z A-Z).elab.dll

# runtime rule/recipe for bitmap dependancies
define RR_BMP
$(1).bmp: $(REF_DIR)/$(1).bin $(NVC_IR)
	$(NVC) $(NVCGFLAGS) -e $(NVC_TOP) $(NVCEFLAGS) -gfilename=$$<
	$(NVC) $(NVCGFLAGS) -r $(NVC_TOP) $(NVCRFLAGS)
	mv $(NVC_TOP)_0.bmp $(1).bmp
$(REF_DIR)/$(1)$(VARIANT).bmp: $(1).bmp
	diff --binary $$@ $$<
	touch $$@
endef

$(foreach TEST,$(TESTS),$(eval $(call RR_BMP,$(TEST))))

compare: $(addsuffix $(VARIANT).bmp,$(addprefix $(REF_DIR)/,$(TESTS)))

clean:
	rm -rf *.bmp work
