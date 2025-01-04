#################################################################################
# makefile for tb_memac_rmii
#################################################################################

default: nvc

toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

TB=tb_memac_rmii

SIM_LRM=2008
SIM_SRC=\
	$(toplevel)/src/common/ethernet/memac_pkg.vhd=memac \
	$(toplevel)/src/common/ethernet/memac_rmii_pkg.vhd=memac \
	$(toplevel)/src/common/ethernet/memac_rx_rmii.vhd=memac \
	$(toplevel)/src/common/ethernet/memac_tx_rmii.vhd=memac \
	$(toplevel)/src/common/ethernet/test/memac_sim_pkg.vhd=memac \
	$(toplevel)/src/common/ethernet/test/memac_sim_rmii_pkg.vhd=memac \
	$(toplevel)/src/common/ethernet/test/$(TB).vhd=work
SIM_RUN=$(TB)

################################################################################
# Vivado

VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=$(SIM_LRM)
VIVADO_SIM_SRC=$(SIM_SRC)
VIVADO_SIM_RUN=$(SIM_RUN)

include $(make_fpga)/vivado.mak

################################################################################
# XSim

XSIM_VHDL_LRM=$(SIM_LRM)
XSIM_SRC=$(SIM_SRC)
XSIM_RUN=$(SIM_RUN)

include $(make_fpga)/xsim.mak

################################################################################
# GHDL

GHDL_LRM=$(SIM_LRM)
GHDL_SRC=$(SIM_SRC)
GHDL_RUN=$(SIM_RUN)

include $(toplevel)/submodules/make-fpga/ghdl.mak

################################################################################
# NVC

NVC_VHDL_LRM=$(SIM_LRM)
NVC_SRC=$(SIM_SRC)
NVC_RUN=$(SIM_RUN)
NVC_G_OPTS=-L. -M 128M

include $(toplevel)/submodules/make-fpga/nvc.mak

################################################################################
# ModelSim etc

VSIM_VHDL_LRM=$(SIM_LRM)
VSIM_SRC=$(SIM_SRC)
VSIM_RUN=$(SIM_RUN)

include $(toplevel)/submodules/make-fpga/vsim.mak

################################################################################
