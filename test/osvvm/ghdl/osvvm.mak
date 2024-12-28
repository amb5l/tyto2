ifndef toplevel
toplevel:=$(shell git rev-parse --show-toplevel)
endif
OsvvmLibraries?=$(toplevel)/submodules/OsvvmLibraries

GHDL_SRC+=$(OsvvmLibraries)/osvvm/IfElsePkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/OsvvmTypesPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/TextUtilPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ResolutionPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/NamePkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/OsvvmGlobalPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/CoverageVendorApiPkg_default.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/TranscriptPkg.vhd=osvvm
ifeq (2019,$(GHDL_LRM))
GHDL_SRC+=$(OsvvmLibraries)/osvvm/FileLinePathPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/LanguageSupport2019Pkg.vhd=osvvm
else
GHDL_SRC+=$(OsvvmLibraries)/osvvm/deprecated/FileLinePathPkg_c.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/deprecated/LanguageSupport2019Pkg_c.vhd=osvvm
endif
GHDL_SRC+=$(OsvvmLibraries)/osvvm/AlertLogPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/TbUtilPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/NameStorePkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/MessageListPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/SortListPkg_int.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/RandomBasePkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/RandomPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/RandomProcedurePkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/CoveragePkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/DelayCoveragePkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ClockResetPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ResizePkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardGenericPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_slv.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_int.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_signed.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_unsigned.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_IntV.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/MemorySupportPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/MemoryGenericPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/MemoryPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ReportPkg.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg_default.vhd=osvvm
GHDL_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg_default.vhd=osvvm
ifeq (2019,$(NVC_VHDL_LRM))
GHDL_SRC+=$(OsvvmLibraries)/osvvm/ RandomPkg2019.vhd=osvvm
else
GHDL_SRC+=$(OsvvmLibraries)/osvvm/deprecated/RandomPkg2019_c.vhd=osvvm
endif
GHDL_SRC+=$(OsvvmLibraries)/osvvm/OsvvmContext.vhd=osvvm