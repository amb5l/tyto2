ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_axi4))
SIM_SRC.osvvm_axi4:=$(SIM_SRC.osvvm_axi4) \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4ComponentPkg.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4ComponentVtiPkg.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4Context.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4Manager.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4ManagerVti.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4Monitor_dummy.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4Subordinate.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4SubordinateVti.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4Memory.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4MemoryVti.vhd \
	$(OsvvmLibraries)/AXI4/Axi4/src/Axi4PassThru.vhd
