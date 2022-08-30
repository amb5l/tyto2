VARIANT=d

all: compare

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src

# Questa/Modelsim executables and options
SIM_WORK=work
VCOM=vcom
VCOMOPTS=-work $(SIM_WORK) -2008 -explicit -vopt -stats=none
VCOM_LOG_EXT=vcom.log
VSIM=vsim
VSIMOPTS=-t ps -c -onfinish stop -do "set NumericStdNoWarnings 1; onfinish exit; run -all"

# runtime rule/recipe for analysis dependancies
define RR_DEP
SIM_TOP=$(strip $(1))
VCOM_LOG=$(VCOM_LOG) $(strip $(1)).$(VCOM_LOG_EXT)
$(strip $(1)).$(VCOM_LOG_EXT): $(2)
	$(VCOM) $(VCOMOPTS) $$< >$(strip $(1)).$(VCOM_LOG_EXT)
endef

# design unit dependancies are declared here
$(eval $(call RR_DEP, tyto_types_pkg       , $(SRC)/common/tyto_types_pkg.vhd                  ))
$(eval $(call RR_DEP, saa5050_rom_data     , $(SRC)/common/retro/saa5050/saa5050_rom_data.vhd  ))
$(eval $(call RR_DEP, saa5050$(VARIANT)    , $(SRC)/common/retro/saa5050/saa5050$(VARIANT).vhd ))
$(eval $(call RR_DEP, hd6845               , $(SRC)/common/retro/hd6845/hd6845.vhd             ))
$(eval $(call RR_DEP, tyto_sim_pkg         , $(SRC)/common/tyto_sim_pkg.vhd tyto_types_pkg.$(VCOM_LOG_EXT) ))
$(eval $(call RR_DEP, tb_saa5050$(VARIANT) , $(SRC)/common/retro/saa5050/test/tb_saa5050$(VARIANT).vhd tyto_sim_pkg.$(VCOM_LOG_EXT) tyto_types_pkg.$(VCOM_LOG_EXT) ))

# tests to run are listed here
TESTS=engtest scarybeasts parrot

# reference binaries and bitmaps directory is specified here
REF_DIR=$(SRC)/common/retro/saa5050/test

# fixed rules and recipes follow

# runtime rule/recipe for bitmap dependancies
define RR_BMP
$(1).bmp: $(REF_DIR)/$(1).bin $(VCOM_LOG)
	$(VSIM) $(VSIMOPTS) -gfilename=$$< $(SIM_TOP)
	mv $(SIM_TOP)_0.bmp $(1).bmp
$(REF_DIR)/$(1)$(VARIANT).bmp: $(1).bmp
	diff --binary $$@ $$<
	touch $$@
endef

$(foreach TEST,$(TESTS),$(eval $(call RR_BMP,$(TEST))))

compare: $(addsuffix $(VARIANT).bmp,$(addprefix $(REF_DIR)/,$(TESTS)))

clean:
	rm -rf *.bmp *.log transcript work
