ifeq ($(OS),Windows_NT)
pacman -S --needed mingw-w64-x86_64-tcllib
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(SIM_LIB) osvvm
SIM_SRC.osvvm:=$(wildcard $(OsvvmLibraries)/osvvm/*.vhd)

SIM_LIB:=$(SIM_LIB) osvvm_common
SIM_SRC.osvvm_common:=$(wildcard $(OsvvmLibraries)/common/src/*.vhd)

SIM_LIB:=$(SIM_LIB) osvvm_uart
SIM_SRC.osvvm_uart:=$(wildcard $(OsvvmLibraries)/common/src/*.vhd)

SIM_LIB:=$(SIM_LIB) osvvm_axi4
SIM_SRC.osvvm_axi4:=\
	$(wildcard $(OsvvmLibraries)/AXI4/common/src/*.vhd) \
	$(wildcard $(OsvvmLibraries)/AXI4/Axi4/src/*.vhd) \
	$(wildcard $(OsvvmLibraries)/AXI4/Axi4Lite/src/*.vhd) \
	$(wildcard $(OsvvmLibraries)/AXI4/Axi4Stream/src/*.vhd)

SIM_LIB:=$(SIM_LIB) osvvm_dpram_pt
SIM_SRC.osvvm_dpram_pt:=\
	$(OsvvmLibraries)/DpRam/src/DpRam_PT.vhd

SIM_LIB:=$(SIM_LIB) osvvm_dpram
SIM_SRC.osvvm_dpram:=\
	$(OsvvmLibraries)/DpRam/src/DpRam_Singleton.vhd \
	$(OsvvmLibraries)/DpRam/src/DpRamController_Blocking.vhd \
	$(OsvvmLibraries)/DpRam/src/DpRamComponentPkg.vhd \
	$(OsvvmLibraries)/DpRam/src/DpRamContext.vhd

SIM_LIB:=$(SIM_LIB) osvvm_ethernet
SIM_SRC.osvvm_ethernet:=$(wildcard $(OsvvmLibraries)/Ethernet/src/*.vhd)

SIM_LIB:=$(SIM_LIB) osvvm_cosim
SIM_SRC.osvvm_cosim:=$(wildcard $(OsvvmLibraries)/CoSim/src/*.vhd)
