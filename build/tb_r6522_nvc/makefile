REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src

all: run
	$(info $(shell date))

#------------------------------------------------------------------------------
# simulation

include ../gmsl

# NVC simulator and option flags (global, analysis, elaboration and runtime)
NVC=nvc
NVCGFLAGS=--std=08
NVCAFLAGS=
NVCEFLAGS=-gValidatedResultsDir=$(SRC)/common/retro/r6522/test/
NVCRFLAGS=--wave --format=vcd --stop-time=1us

# simulation work library (and directory) name
NVC_WORK=work
NVC_WORK_DIR=$(NVC_WORK)/
NVC_WORK_NAME=$(shell echo $(NVC_WORK)| tr a-z A-Z)

# analysis dependancies and rules
define ANA
NVC_TOP=$(1)
NVC_IR=$(NVC_IR) $(NVC_WORK_DIR)$(NVC_WORK_NAME).$(1)
$(NVC_WORK_DIR)$(NVC_WORK_NAME).$(1): $(2)
	$(NVC) $(NVCGFLAGS) -a $$< $(NVCAFLAGS)
endef
$(eval $(call ANA,R6522,             $(SRC)/common/retro/r6522/r6522.vhd))
$(eval $(call ANA,TESTCTRL,          $(SRC)/common/retro/r6522/test/TestCtrl.vhd))
$(eval $(call ANA,TESTCTRL-PORTAOUT, $(SRC)/common/retro/r6522/test/TbR6522_PortAOut.vhd $(NVC_WORK_DIR)$(NVC_WORK_NAME).TESTCTRL))
$(eval $(call ANA,REGMASTER,         $(SRC)/common/retro/r6522/test/RegMaster.vhd))
$(eval $(call ANA,TBR6522,           $(SRC)/common/retro/r6522/test/TbR6522.vhd))

analyse: $(NVR_IR)

# runtime DLL filename - derive from top entity name (or specify manually)
NVC_DLL=$(NVC_WORK_DIR)/$(shell echo _$(NVC_WORK_NAME).$(NVC_TOP)| tr a-z A-Z).elab.dll

# elaborate
elaborate:
$(NVC_DLL): $(NVC_IR)
	$(NVC) $(NVCGFLAGS) -e $(NVC_TOP) $(NVCEFLAGS)

# run
run: $(NVC_DLL) $(REF_FILE)
	$(info $(shell date))
	$(NVC) $(NVCGFLAGS) -r $(NVC_TOP) $(NVCRFLAGS)

#------------------------------------------------------------------------------
# cleanup

clean:
	rm -rf $(NVC_WORK)
