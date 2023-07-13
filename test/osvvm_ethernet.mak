ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_ethernet))
SIM_SRC.osvvm_ethernet:=\
	$(OsvvmLibraries)/Ethernet/src/xMiiTbPkg.vhd \
	$(OsvvmLibraries)/Ethernet/src/xMiiComponentPkg.vhd \
	$(OsvvmLibraries)/Ethernet/src/xMiiPhyRxTransmitter.vhd \
	$(OsvvmLibraries)/Ethernet/src/xMiiPhyTxReceiver.vhd \
	$(OsvvmLibraries)/Ethernet/src/xMiiPhy.vhd \
	$(OsvvmLibraries)/Ethernet/src/xMiiMacTransmitter.vhd \
	$(OsvvmLibraries)/Ethernet/src/xMiiMacReceiver.vhd \
	$(OsvvmLibraries)/Ethernet/src/xMiiMac.vhd \
	$(OsvvmLibraries)/Ethernet/src/xMiiContext.vhd
