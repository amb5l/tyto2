#################################################################################
# makefile for tb_memac_rmii_rx_spd
#################################################################################

default: xsim

toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

################################################################################
# DUT source

DUT=memac_rmii_rx_spd

DUT_SRC=\
	$(toplevel)/src/common/ethernet/$(DUT).vhd=memac

################################################################################
# Vivado post simulation/implementation netlist generation

# list of DUTs
VIVADO_POST_UNIT=$(DUT)

# source per DUT
VIVADO_POST_SRC.$(DUT)=$(DUT_SRC)

# heavy lifting
include $(make_fpga)/vivado_post.mak

################################################################################
# simulation sources and runs
# using post-synthesis functional simulation netlist of DUT

TB=tb_$(DUT)
CFG_BEHAVIOURAL=cfg_$(TB)_behavioural
CFG_POST_SYN_FUNC=cfg_$(TB)_post_syn_func

SIM_SRC=\
	$(DUT_SRC) \
	$(VIVADO_POST_SYN_FUNC.$(DUT).vhd)=memac_psf \
	$(toplevel)/src/common/ethernet/test/memac_sim_pkg.vhd=memac \
	$(toplevel)/src/common/ethernet/test/$(TB).vhd=work
SIM_RUN=\
	beh=$(CFG_BEHAVIOURAL) \
	psf=$(CFG_POST_SYN_FUNC)

################################################################################
# Vivado (GUI) simulation support

VIVADO_SIM_SRC=$(SIM_SRC)
VIVADO_SIM_RUN=$(SIM_RUN)

# heavy lifting
include $(make_fpga)/vivado.mak

################################################################################
# XSim (batch mode) simulation support

XSIM_SRC=$(SIM_SRC)
XSIM_RUN=$(SIM_RUN)
XSIM_EDIT=0

# heavy lifting
include $(make_fpga)/xsim.mak

################################################################################
# GHDL simulation support

GHDL_SRC=$(SIM_SRC)
GHDL_RUN=$(SIM_RUN)
GHDL_VENDOR_LIB=xilinx-vivado
GHDL_EDIT=0

# heavy lifting
include $(toplevel)/submodules/make-fpga/ghdl.mak

################################################################################
# NVC simulation support

NVC_SRC=$(SIM_SRC)
NVC_RUN=$(SIM_RUN)
NVC_G_OPTS=-L. -M 128M
NVC_EDIT=0

# heavy lifting
include $(toplevel)/submodules/make-fpga/nvc.mak

################################################################################
# ModelSim etc simulation support

VSIM_SRC=$(SIM_SRC)
VSIM_RUN=$(SIM_RUN)
VSIM_EDIT=0

# heavy lifting
include $(toplevel)/submodules/make-fpga/vsim.mak

################################################################################
