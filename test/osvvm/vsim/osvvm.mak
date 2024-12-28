ifndef toplevel
toplevel:=$(shell git rev-parse --show-toplevel)
endif
OsvvmLibraries?=$(toplevel)/submodules/OsvvmLibraries

VSIM_SRC+=$(OsvvmLibraries)/osvvm/IfElsePkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmTypesPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/TextUtilPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ResolutionPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/NamePkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmGlobalPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/CoverageVendorApiPkg_default.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/TranscriptPkg.vhd=osvvm
ifeq (2019,$(GHDL_LRM))
VSIM_SRC+=$(OsvvmLibraries)/osvvm/FileLinePathPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/LanguageSupport2019Pkg.vhd=osvvm
else
VSIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/FileLinePathPkg_c.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/LanguageSupport2019Pkg_c.vhd=osvvm
endif
VSIM_SRC+=$(OsvvmLibraries)/osvvm/AlertLogPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/TbUtilPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/NameStorePkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/MessageListPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/SortListPkg_int.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/RandomBasePkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/RandomPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/RandomProcedurePkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/CoveragePkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/DelayCoveragePkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ClockResetPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ResizePkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardGenericPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_slv.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_int.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_signed.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_unsigned.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_IntV.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/MemorySupportPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/MemoryGenericPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/MemoryPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ReportPkg.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg_default.vhd=osvvm
VSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg_default.vhd=osvvm
ifeq (2019,$(NVC_VHDL_LRM))
VSIM_SRC+=$(OsvvmLibraries)/osvvm/ RandomPkg2019.vhd=osvvm
else
VSIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/RandomPkg2019_c.vhd=osvvm
endif
VSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmContext.vhd=osvvm