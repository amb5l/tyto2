ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_axi4))
SIM_SRC.osvvm_axi4:=$(SIM_SRC.osvvm_axi4) \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamOptionsPkg.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamOptionsArrayPkg.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamTbPkg.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamTransmitter.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamTransmitterVti.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamReceiver.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamReceiverVti.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamComponentPkg.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamContext.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamGenericSignalsPkg.vhd \
	$(OsvvmLibraries)/AXI4/Axi4Stream/src/AxiStreamSignalsPkg_32.vhd
