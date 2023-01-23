# makefile for tb_hdmi_rx_selectio_clk

REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src

FPGA_VENDOR:=xilinx
FPGA_FAMILY:=7series

# note that Xilinx Vivado libraries must be pre-compiled
SIMULATORS:=ghdl nvc vsim xsim
GHDL_LIBS:=xilinx-vivado

SIM_TOP:=tb_hdmi_rx_selectio_clk
SIM_SRC:=\
    $(SRC)/common/tyto_types_pkg.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/hdmi_rx_selectio_fm.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/hdmi_rx_selectio_clk.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/test/$(SIM_TOP).vhd
SIM_RUN=$(SIM_TOP)

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(SIM_TOP)
V4P_LIB_SRC:=\
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd

include $(MAKE_FPGA)
