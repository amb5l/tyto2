ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_common))
SIM_SRC.osvvm_common:=\
	$(OsvvmLibraries)/Common/src/ModelParametersPkg.vhd \
	$(OsvvmLibraries)/Common/src/FifoFillPkg_slv.vhd \
	$(OsvvmLibraries)/Common/src/StreamTransactionPkg.vhd \
	$(OsvvmLibraries)/Common/src/StreamTransactionArrayPkg.vhd \
	$(OsvvmLibraries)/Common/src/AddressBusTransactionPkg.vhd \
	$(OsvvmLibraries)/Common/src/AddressBusTransactionArrayPkg.vhd \
	$(OsvvmLibraries)/Common/src/AddressBusResponderTransactionPkg.vhd \
	$(OsvvmLibraries)/Common/src/AddressBusResponderTransactionArrayPkg.vhd \
	$(OsvvmLibraries)/Common/src/AddressBusVersionCompatibilityPkg.vhd \
	$(OsvvmLibraries)/Common/src/InterruptGlobalSignalPkg.vhd \
	$(OsvvmLibraries)/Common/src/InterruptHandler.vhd \
	$(OsvvmLibraries)/Common/src/InterruptHandlerComponentPkg.vhd \
	$(OsvvmLibraries)/Common/src/InterruptGeneratorBit.vhd \
	$(OsvvmLibraries)/Common/src/InterruptGeneratorBitVti.vhd \
	$(OsvvmLibraries)/Common/src/InterruptGeneratorComponentPkg.vhd \
	$(OsvvmLibraries)/Common/src/OsvvmCommonContext.vhd
