#################################################################################
# mbv_mcs_test.mak
#################################################################################

all: bit

toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

#################################################################################
# Vitis

VITIS_FLOW=classic
VITIS_SRC=$(toplevel)/src/designs/$(DESIGN)/software/main.c
VITIS_SYM=APP_NAME=mbv_mcs_test
VITIS_SYM_RLS=BUILD_CONFG=Release
VITIS_SYM_DBG=BUILD_CONFG=Debug

include $(make_fpga)/vitis.mak

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL-2008
VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/mmcm.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(DESIGN)_cpu_wrapper.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).vhd
VIVADO_BD_TCL=$(toplevel)/src/designs/$(DESIGN)/$(DESIGN)_cpu.tcl
VIVADO_PROC_REF=$(DESIGN)_$(BOARD)_cpu
VIVADO_PROC_CELL=cpu/U0/microblaze_I
VIVADO_DSN_ELF=$(VITIS_DIR)/$(VITIS_ELF_RLS)
VIVADO_SIM_SRC=$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/tb_$(DESIGN)_$(BOARD).vhd
VIVADO_SIM_ELF=$(VITIS_DIR)/$(VITIS_ELF_DBG)
VIVADO_SIM_RUN=tb_$(DESIGN)
VIVADO_XDC=$(toplevel)/src/boards/$(BOARD)/$(BOARD).tcl=IMPL

include $(make_fpga)/vivado.mak

################################################################################
# Visual Studio Code

VSCODE_TOP=$(DESIGN) tb_$(DESIGN)
VSCODE_LIB=work unisim
VSCODE_SRC.work=\
	$(call VIVADO_SRC_FILE,$(VIVADO_DSN_SRC)) \
	$(call VIVADO_SRC_FILE,$(VIVADO_SIM_SRC))
VSCODE_SRC.unisim=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd

include $(make_fpga)/vscode.mak

################################################################################
