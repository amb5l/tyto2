ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_dpram))
SIM_SRC.osvvm_dpram:=\
	$(OsvvmLibraries)/DpRam/src/DpRam_Singleton.vhd \
	$(OsvvmLibraries)/DpRam/src/DpRamController_Blocking.vhd \
	$(OsvvmLibraries)/DpRam/src/DpRamComponentPkg.vhd \
	$(OsvvmLibraries)/DpRam/src/DpRamContext.vhd
