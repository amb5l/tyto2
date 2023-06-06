ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_axi4))
SIM_SRC.osvvm_axi4:=$(SIM_SRC.osvvm_axi4) \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamOptionsPkg.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamOptionsArrayPkg.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamTbPkg.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamTransmitter.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamTransmitterVti.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamReceiver.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamReceiverVti.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamComponentPkg.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamContext.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamGenericSignalsPkg.vhd \
	$(OsvvmLibraries)/AXI4/AxiStream/src/AxiStreamSignalsPkg_32.vhd
