ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

OsvvmLibraries?=$(REPO_ROOT)/submodules/OsvvmLibraries

SIM_LIB:=$(strip $(SIM_LIB) $(filter-out $(SIM_LIB),osvvm))
SIM_SRC.osvvm:=\
	$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg.vhd \
	$(OsvvmLibraries)/osvvm/TextUtilPkg.vhd \
	$(OsvvmLibraries)/osvvm/ResolutionPkg.vhd \
	$(OsvvmLibraries)/osvvm/NamePkg.vhd \
	$(OsvvmLibraries)/osvvm/OsvvmGlobalPkg.vhd \
	$(OsvvmLibraries)/osvvm/VendorCovApiPkg.vhd \
	$(OsvvmLibraries)/osvvm/TranscriptPkg.vhd \
	$(OsvvmLibraries)/osvvm/AlertLogPkg.vhd \
	$(OsvvmLibraries)/osvvm/NameStorePkg.vhd \
	$(OsvvmLibraries)/osvvm/MessageListPkg.vhd \
	$(OsvvmLibraries)/osvvm/SortListPkg_int.vhd \
	$(OsvvmLibraries)/osvvm/RandomBasePkg.vhd \
	$(OsvvmLibraries)/osvvm/RandomPkg.vhd \
	$(OsvvmLibraries)/osvvm/RandomProcedurePkg.vhd \
	$(OsvvmLibraries)/osvvm/CoveragePkg.vhd \
	$(OsvvmLibraries)/osvvm/ResizePkg.vhd \
	$(OsvvmLibraries)/osvvm/ScoreboardGenericPkg.vhd \
	$(OsvvmLibraries)/osvvm/ScoreboardPkg_slv.vhd \
	$(OsvvmLibraries)/osvvm/ScoreboardPkg_int.vhd \
	$(OsvvmLibraries)/osvvm/MemorySupportPkg.vhd \
	$(OsvvmLibraries)/osvvm/MemoryGenericPkg.vhd \
	$(OsvvmLibraries)/osvvm/MemoryPkg.vhd \
	$(OsvvmLibraries)/osvvm/TbUtilPkg.vhd \
	$(OsvvmLibraries)/osvvm/ReportPkg.vhd \
	$(OsvvmLibraries)/osvvm/OsvvmTypesPkg.vhd \
	$(OsvvmLibraries)/osvvm/OsvvmContext.vhd  \
	$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg_default.vhd
