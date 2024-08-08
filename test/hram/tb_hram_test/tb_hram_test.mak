#################################################################################
# tb_hram_ctrl.mak
#################################################################################

default: sim_gui

toplevel=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

DUT=hram_test
TB=tb_$(DUT)

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/basic/sync_reg_u.vhd \
	$(toplevel)/src/common/hram/test/model_hram.vhd \
	$(toplevel)/src/common/basic/csr.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm_drp.vhd \
	$(toplevel)/src/designs/MEGAtest/overclock.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/ram_sdp_32x6.vhd \
	$(toplevel)/src/common/hram/$(FPGA_VENDOR)/$(FPGA_FAMILY)/hram_ctrl.vhd \
	$(toplevel)/src/designs/MEGAtest/$(DUT).vhd \
	$(toplevel)/submodules/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl \
	$(toplevel)/src/designs/MEGAtest/test/$(TB).vhd
VIVADO_SIM_RUN=$(TB);OUTPUT_DELAY="MAX"
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_VPKG.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDELAYE2.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/ODDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IOBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/RAM32M.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
