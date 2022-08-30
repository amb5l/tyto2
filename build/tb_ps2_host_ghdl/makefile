all: run

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src

# GHDL simulator and option flags (analysis, elaboration and runtime)
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
$(eval $(call RR_DEP, tyto_types_pkg , $(SRC)/common/tyto_types_pkg.vhd ))
$(eval $(call RR_DEP, tyto_sim_pkg	 , $(SRC)/common/tyto_sim_pkg.vhd tyto_types_pkg.o ))
$(eval $(call RR_DEP, ps2_host		 , $(SRC)/common/ps2/ps2_host.vhd ))
$(eval $(call RR_DEP, tb_ps2_host	 , $(SRC)/common/ps2/tb_ps2_host.vhd ps2_host.o tyto_sim_pkg.o ))

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

run: $(GHDL_EXE)
	$(GHDL_EXE) $(GHDLROPTS)

clean:
	rm -f $(GHDL_EXE) *.cf *.o *.lst
