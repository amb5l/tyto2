VARIANT=

all: compare

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src

GHDL=ghdl
GHDLAOPTS=--std=08 -frelaxed -fsynopsys
GHDLEOPTS=--std=08 -frelaxed
GHDLROPTS=--ieee-asserts=disable --unbuffered

# runtime rule/recipe for analysis dependancies
define RR_DEP
GHDL_TOP=$(strip $(1))
GHDL_OBJ=$(GHDL_OBJ) $(strip $(1)).o
$(strip $(1)).o: $(2)
	$(GHDL) -a $(GHDLAOPTS) $$<
endef

# design unit dependancies are declared here
$(eval $(call RR_DEP, tyto_types_pkg       , $(SRC)/common/tyto_types_pkg.vhd                  ))
$(eval $(call RR_DEP, saa5050_rom_data     , $(SRC)/common/retro/saa5050/saa5050_rom_data.vhd  ))
$(eval $(call RR_DEP, saa5050$(VARIANT)    , $(SRC)/common/retro/saa5050/saa5050$(VARIANT).vhd ))
$(eval $(call RR_DEP, hd6845               , $(SRC)/common/retro/hd6845/hd6845.vhd             ))
$(eval $(call RR_DEP, tyto_sim_pkg         , $(SRC)/common/tyto_sim_pkg.vhd tyto_types_pkg.o   ))
$(eval $(call RR_DEP, tb_saa5050$(VARIANT) , $(SRC)/common/retro/saa5050/test/tb_saa5050$(VARIANT).vhd tyto_sim_pkg.o tyto_types_pkg.o ))

# tests to run are listed here
TESTS=engtest scarybeasts parrot

# reference binaries and bitmaps directory is specified here
REF_DIR=$(SRC)/common/retro/saa5050/test

# fixed rules and recipes follow

ifeq ($(OS),Windows_NT)
	GHDL_EXE=./$(GHDL_TOP).exe
else
	GHDL_EXE=./$(GHDL_TOP)
endif

$(GHDL_EXE): $(GHDL_OBJ)
	ghdl -e $(GHDLEOPTS) $(GHDL_TOP)

analyse: $(GHDL_OBJ)

elaborate: $(GHDL_EXE)

# runtime rule/recipe for bitmap dependancies
define RR_BMP
$(1).bmp: $(REF_DIR)/$(1).bin $(GHDL_EXE)
	$(GHDL_EXE) $(GHDLROPTS) -gfilename=$$<
	mv $(GHDL_TOP)_0.bmp $(1).bmp
$(REF_DIR)/$(1)$(VARIANT).bmp: $(1).bmp
	diff --binary $$@ $$<
	touch $$@
endef

$(foreach TEST,$(TESTS),$(eval $(call RR_BMP,$(TEST))))

compare: $(addsuffix $(VARIANT).bmp,$(addprefix $(REF_DIR)/,$(TESTS)))

clean:
	rm -f *.bmp $(GHDL_EXE) *.cf *.o *.lst
