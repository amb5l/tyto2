ifndef toplevel
toplevel:=$(shell git rev-parse --show-toplevel)
endif
OsvvmLibraries?=$(toplevel)/submodules/OsvvmLibraries

VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/IfElsePkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmTypesPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmScriptSettingsPkg_default.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmSettingsPkg_default.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/TextUtilPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ResolutionPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/NamePkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmGlobalPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/CoverageVendorApiPkg_default.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/TranscriptPkg.vhd=osvvm
ifeq (2019,$(VIVADO_VHDL_LRM))
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/FileLinePathPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/LanguageSupport2019Pkg.vhd=osvvm
else
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/FileLinePathPkg_c.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/LanguageSupport2019Pkg_c.vhd=osvvm
endif
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/AlertLogPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/TbUtilPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/NameStorePkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/MessageListPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/SortListPkg_int.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/RandomBasePkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/RandomPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/RandomProcedurePkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/CoveragePkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/DelayCoveragePkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ClockResetPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ResizePkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardGenericPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_slv.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_int.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_signed.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_unsigned.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ScoreboardPkg_IntV.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/MemorySupportPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/MemoryGenericPkg_xilinx.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/MemoryPkg.vhd=osvvm
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/ReportPkg.vhd=osvvm
ifeq (2019,$(XSIM_VHDL_LRM))
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/RandomPkg2019.vhd=osvvm
else
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/deprecated/RandomPkg2019_c.vhd=osvvm
endif
VIVADO_SIM_SRC+=$(OsvvmLibraries)/osvvm/OsvvmContext.vhd=osvvm 
