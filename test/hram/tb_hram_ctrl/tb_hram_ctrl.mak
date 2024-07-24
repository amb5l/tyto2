#################################################################################
# tb_hram_ctrl.mak
#################################################################################

default: bit

toplevel=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

DUT=hram_ctrl
TB=tb_$(DUT)

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/tyto_sim_pkg.vhd \
	$(toplevel)/src/common/hram/test/model_hram.vhd \
	$(toplevel)/src/common/basic/xilinx/7series/ram_sdp_32x6.vhd \
	$(toplevel)/src/common/hram/$(FPGA_FAMILY)/$(DUT).vhd \
	$(toplevel)/src/common/hram/test/$(TB).vhd
VIVADO_SIM_RUN=$(TB)
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/ODDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUF.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
# GHDL

GHDL_LRM=$(VIVADO_VHDL_LRM)
GHDL_SRC=$(VIVADO_SIM_SRC)
GHDL_RUN=$(VIVADO_SIM_RUN)

include $(toplevel)/submodules/make-fpga/ghdl.mak

################################################################################
# NVC

NVC_VHDL_LRM=$(VIVADO_VHDL_LRM)
NVC_SRC=$(VIVADO_SIM_SRC)
NVC_RUN=$(VIVADO_SIM_RUN)

include $(toplevel)/submodules/make-fpga/nvc.mak

################################################################################
# ModelSim/Questa/etc

VSIM_VHDL_LRM=$(VIVADO_VHDL_LRM)
VSIM_SRC=$(VIVADO_SIM_SRC)
VSIM_RUN=$(VIVADO_SIM_RUN)

include $(toplevel)/submodules/make-fpga/vsim.mak

################################################################################