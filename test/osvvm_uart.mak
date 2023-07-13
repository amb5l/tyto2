ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_uart))
SIM_SRC.osvvm_uart:=\
	$(OsvvmLibraries)/osvvm/UART/src/UartTbPkg.vhd \
	$(OsvvmLibraries)/osvvm/UART/src/ScoreboardPkg_Uart.vhd \
	$(OsvvmLibraries)/osvvm/UART/src/UartTxComponentPkg.vhd \
	$(OsvvmLibraries)/osvvm/UART/src/UartRxComponentPkg.vhd \
	$(OsvvmLibraries)/osvvm/UART/src/UartContext.vhd \
	$(OsvvmLibraries)/osvvm/UART/src/UartTx.vhd \
	$(OsvvmLibraries)/osvvm/UART/src/UartRx.vhd
