ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_axi4))
SIM_SRC.osvvm_axi4:=$(SIM_SRC.osvvm_axi4) \
	$(OsvvmLibraries)/AXI4/Axi4Lite/src/Axi4LiteComponentPkg.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Lite/src/Axi4LiteContext.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Lite/src/Axi4LiteManager.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Lite/src/Axi4LiteMonitor_dummy.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Lite/src/Axi4LiteSubordinate.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Lite/src/Axi4LiteMemory.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Lite/src/Axi4LitePassThru.vhd
