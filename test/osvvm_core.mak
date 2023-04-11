OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB+=$(filter-out $(SIM_LIB),osvvm)
SIM_SRC.osvvm:=$(filter-out $(SIM_SRC.osvvm),$(wildcard $(OsvvmLibraries)/osvvm/*.vhd))

SIM_LIB+=$(filter-out $(SIM_LIB),osvvm_common)
SIM_SRC.osvvm_common:=$(filter-out $(SIM_SRC.osvvm_common),$(wildcard $(OsvvmLibraries)/common/src/*.vhd))
