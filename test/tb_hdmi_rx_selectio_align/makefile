# makefile for tb_hdmi_rx_selectio_align

REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src

FPGA_VENDOR:=xilinx
FPGA_FAMILY:=7series

# TODO: add open source models of IDELAYE2, ISERDESE2 note that Xilinx Vivado libraries must be pre-compiled
SIMULATOR:=xsim_cmd xsim_ide

SIM_TOP:=tb_hdmi_rx_selectio_align
SIM_SRC:=\
	$(SRC)/common/tyto_types_pkg.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/hdmi_rx_selectio_align.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/test/$(SIM_TOP).vhd
SIM_RUN=$(SIM_TOP)

VSCODE_TOP:=$(SIM_TOP)
VSCODE_SRC:=$(SIM_SRC)
VSCODE_XLIB:=unisim
VSCODE_XSRC.unisim:=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd

include $(MAKE_FPGA)
