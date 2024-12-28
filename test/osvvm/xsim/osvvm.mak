ifndef toplevel
toplevel:=$(shell git rev-parse --show-toplevel)
endif
OsvvmLibraries?=$(toplevel)/submodules/OsvvmLibraries

XSIM_SRC+=$(OsvvmLibraries)/osvvm/IfElsePkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmTypesPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg_default.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg_default.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/TextUtilPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ResolutionPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/NamePkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmGlobalPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/CoverageVendorApiPkg_default.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/TranscriptPkg.vhd=osvvm
ifeq (2019,$(XSIM_VHDL_LRM))
XSIM_SRC+=$(OsvvmLibraries)/osvvm/FileLinePathPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/LanguageSupport2019Pkg.vhd=osvvm
else
XSIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/FileLinePathPkg_c.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/LanguageSupport2019Pkg_c.vhd=osvvm
endif
XSIM_SRC+=$(OsvvmLibraries)/osvvm/AlertLogPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/TbUtilPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/NameStorePkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/MessageListPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/SortListPkg_int.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/RandomBasePkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/RandomPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/RandomProcedurePkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/CoveragePkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/DelayCoveragePkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ClockResetPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ResizePkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardGenericPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_slv.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_int.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_signed.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_unsigned.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_IntV.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/MemorySupportPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/MemoryGenericPkg_xilinx.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/MemoryPkg.vhd=osvvm
XSIM_SRC+=$(OsvvmLibraries)/osvvm/ReportPkg.vhd=osvvm
ifeq (2019,$(XSIM_VHDL_LRM))
XSIM_SRC+=$(OsvvmLibraries)/osvvm/RandomPkg2019.vhd=osvvm
else
XSIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/RandomPkg2019_c.vhd=osvvm
endif
XSIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmContext.vhd=osvvm
