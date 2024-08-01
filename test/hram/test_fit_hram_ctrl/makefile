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

VIVADO_PATH=$(abspath $(value XILINX_VIVADO))

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(TOP)
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm_v2.vhd \
	$(toplevel)/src/common/basic/xilinx/7series/ram_sdp_32x6.vhd \
	$(toplevel)/src/common/hram/$(FPGA_VENDOR)/$(FPGA_FAMILY)/$(DUT).vhd \
	$(toplevel)/src/common/hram/test/$(TOP).vhd
VIVADO_SIM_SRC=\
	$(VIVADO_PATH)/data/verilog/src/glbl.v \
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_sim_pkg.vhd \
	$(toplevel)/src/common/hram/test/model_hram.vhd \
	$(toplevel)/src/common/hram/test/$(TB).vhd
VIVADO_SIM_RUN=$(TB)
VIVADO_XDC=$(toplevel)/src/common/hram/test/$(TOP).tcl=IMPL
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_VPKG.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDELAYCTRL.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/ODDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFT.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDELAYE2.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/RAM32M.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
