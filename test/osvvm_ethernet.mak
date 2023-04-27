OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_ethernet)
SIM_SRC.osvvm_ethernet:=$(filter-out $(SIM_SRC.osvvm_ethernet),$(wildcard $(OsvvmLibraries)/AXI4/Ethernet/src/*.vhd))
