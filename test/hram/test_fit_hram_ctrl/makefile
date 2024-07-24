#################################################################################
# makefile for test_fit_hram_ctrl
#################################################################################

default: bit

toplevel=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

DUT=hram_ctrl
TOP=test_fit_$(DUT)
TB=tb_$(TOP)
FPGA=xilinx 7series xc7s50fgga484-1

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(TOP)
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/basic
	$(toplevel)/src/common/hram/$(FPGA_VENDOR)/$(DUT).vhd \
	$(toplevel)/src/common/hram/test/$(TOP).vhd
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/hram/test/$(TB).vhd
VIVADO_SIM_RUN=$(TB)
VIVADO_XDC=$(toplevel)/src/common/hram/test/$(TOP).tcl=IMPL
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/ODDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUF.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
