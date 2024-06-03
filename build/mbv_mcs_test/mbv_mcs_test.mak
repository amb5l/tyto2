# mbv_mcs_test.mak

toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

#################################################################################
# Vitis

flow=classic
VITIS_FLOW=$(flow)
VITIS_SRC=\
	$(toplevel)/src/designs/$(DESIGN)/software/main.c

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
VIVADO_DSN_BD_TCL=\
	$(toplevel)/src/designs/$(DESIGN)/$(DESIGN)_cpu.tcl
VIVADO_DSN_ELF=$(VITIS_DIR)/$(VITIS_ELF_RELEASE)
VIVADO_DSN_XDC=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl=IMPL

VIVADO_SIM_SRC=\
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/tb_$(DESIGN)_$(BOARD).vhd
VIVADO_SIM_ELF=$(VITIS_DIR)/$(VITIS_ELF_DEBUG)
VIVADO_SIM_RUN=tb_$(DESIGN)

all: bit

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

include $(make_fpga)/vscode.mak

################################################################################