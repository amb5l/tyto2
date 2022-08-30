all: run

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
$(eval $(call RR_DEP, TYTO_TYPES_PKG , $(SRC)/common/tyto_types_pkg.vhd ))
$(eval $(call RR_DEP, TYTO_SIM_PKG	 , $(SRC)/common/tyto_sim_pkg.vhd $(NVC_WORK_DIR)$(NVC_WORK_NAME).TYTO_TYPES_PKG ))
$(eval $(call RR_DEP, PS2_HOST		 , $(SRC)/common/ps2/ps2_host.vhd ))
$(eval $(call RR_DEP, TB_PS2_HOST	 , $(SRC)/common/ps2/tb_ps2_host.vhd $(NVC_WORK_DIR)$(NVC_WORK_NAME).PS2_HOST $(NVC_WORK_DIR)$(NVC_WORK_NAME).TYTO_SIM_PKG ))

# runtime DLL filename - derive from top entity name (or specify manually)
NVC_DLL=$(NVC_WORK_DIR)/$(shell echo _$(NVC_WORK_NAME).$(NVC_TOP)| tr a-z A-Z).elab.dll

$(NVC_DLL): $(NVC_IR)
	$(NVC) $(NVCGFLAGS) -e $(NVC_TOP) $(NVCEFLAGS)

elaborate: $(NVC_IR)

run: $(NVC_DLL)
	$(NVC) $(NVCGFLAGS) -r $(NVC_TOP) $(NVCRFLAGS)

clean:
	rm -rf *.bmp work
