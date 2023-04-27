OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(SIM_LIB) $(filter-out $(SIM_LIB),osvvm_axi4)
SIM_SRC.osvvm_axi4:=\
	$(filter-out $(SIM_SRC.osvvm_axi4),$(wildcard $(OsvvmLibraries)/AXI4/common/src/*.vhd)) \
	$(filter-out $(SIM_SRC.osvvm_axi4),$(wildcard $(OsvvmLibraries)/AXI4/Axi4Stream/src/*.vhd))
