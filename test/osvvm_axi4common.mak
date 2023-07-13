ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_axi4))
SIM_SRC.osvvm_axi4:=$(SIM_SRC.osvvm_axi4) \
	$(OsvvmLibraries)/AXI4/common/src/Axi4InterfaceCommonPkg.vhd \
	$(OsvvmLibraries)/AXI4/common/src/Axi4LiteInterfacePkg.vhd \
	$(OsvvmLibraries)/AXI4/common/src/Axi4InterfacePkg.vhd \
	$(OsvvmLibraries)/AXI4/common/src/Axi4CommonPkg.vhd \
	$(OsvvmLibraries)/AXI4/common/src/Axi4ModelPkg.vhd \
	$(OsvvmLibraries)/AXI4/common/src/Axi4OptionsPkg.vhd \
	$(OsvvmLibraries)/AXI4/common/src/Axi4OptionsArrayPkg.vhd \
	$(OsvvmLibraries)/AXI4/common/src/Axi4VersionCompatibilityPkg.vhd
