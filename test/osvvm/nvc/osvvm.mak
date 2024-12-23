ifndef toplevel
toplevel:=$(shell git rev-parse --show-toplevel)
endif
OsvvmLibraries?=$(toplevel)/submodules/OsvvmLibraries

NVC_SRC+=$(OsvvmLibraries)/osvvm/IfElsePkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/OsvvmTypesPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/TextUtilPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ResolutionPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/NamePkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/OsvvmGlobalPkg.vhd=osvvm
#NVC_SRC+=$(OsvvmLibraries)/osvvm/CoverageVendorApiPkg_NVC.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/CoverageVendorApiPkg_default.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/TranscriptPkg.vhd=osvvm
ifeq (2019,$(NVC_VHDL_LRM))
NVC_SRC+=$(OsvvmLibraries)/osvvm/FileLinePathPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/LanguageSupport2019Pkg.vhd=osvvm
else
NVC_SRC+=$(OsvvmLibraries)/osvvm/deprecated/FileLinePathPkg_c.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/deprecated/LanguageSupport2019Pkg_c.vhd=osvvm
endif
NVC_SRC+=$(OsvvmLibraries)/osvvm/AlertLogPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/TbUtilPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/NameStorePkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/MessageListPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/SortListPkg_int.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/RandomBasePkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/RandomPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/RandomProcedurePkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/CoveragePkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/DelayCoveragePkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ClockResetPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ResizePkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardGenericPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_slv.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_int.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_signed.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_unsigned.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_IntV.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/MemorySupportPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/MemoryGenericPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/MemoryPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/ReportPkg.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg_default.vhd=osvvm
NVC_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg_default.vhd=osvvm
ifeq (2019,$(NVC_VHDL_LRM))
NVC_SRC+=$(OsvvmLibraries)/osvvm/ RandomPkg2019.vhd=osvvm
else
NVC_SRC+=$(OsvvmLibraries)/osvvm/deprecated/RandomPkg2019_c.vhd=osvvm
endif
NVC_SRC+=$(OsvvmLibraries)/osvvm/OsvvmContext.vhd=osvvm
