toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

DUT=memac_rx_rgmii
DESIGN=test_fit_$(DUT)
BOARD=
FPGA=xilinx 7series xc7s50fgga484-1

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

include $(make_fpga)/head.mak

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL-2008
VIVADO_DSN_TOP=$(DESIGN)
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/mmcm.vhd \
	$(toplevel)/src/common/basic/sync_reg_u.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/iddr.vhd \
	$(toplevel)/src/common/ethernet/memac_util_pkg.vhd \
	$(toplevel)/src/common/ethernet/memac_spd.vhd \
	$(toplevel)/src/common/ethernet/$(DUT).vhd \
	$(toplevel)/src/common/ethernet/$(FPGA_VENDOR)_$(FPGA_FAMILY)/$(DUT)_io.vhd \
	$(toplevel)/src/common/ethernet/test/$(DESIGN).vhd
VIVADO_XDC=$(toplevel)/src/common/ethernet/test/$(DESIGN).tcl=IMPL

include $(make_fpga)/vivado.mak

################################################################################
# Visual Studio Code

VSCODE_TOP=$(DESIGN)
VSCODE_LIB=work unisim
VSCODE_SRC.work=$(call VIVADO_SRC_FILE,$(VIVADO_DSN_SRC))
VSCODE_SRC.unisim=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IBUF.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFIO.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFR.vhd
VSCODE_AUX=$(call VIVADO_SRC_FILE,$(VIVADO_XDC))

include $(make_fpga)/vscode.mak

################################################################################
