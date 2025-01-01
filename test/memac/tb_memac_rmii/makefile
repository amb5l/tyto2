#################################################################################
# makefile for tb_memac_rmii
#################################################################################

default: nvc

toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

TB=tb_memac_rmii

################################################################################
# Vivado

VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/ethernet/memac_pkg.vhd \
	$(toplevel)/src/common/ethernet/test/memac_sim.vhd \
	$(toplevel)/src/common/ethernet/test/model_rmii_tx.vhd \
	$(toplevel)/src/common/ethernet/test/model_rmii_rx.vhd \
	$(toplevel)/src/common/ethernet/test/$(TB).vhd
VIVADO_SIM_RUN=$(TB);LOOPS=10

include $(make_fpga)/vivado.mak

################################################################################
# GHDL

################################################################################
# NVC

################################################################################
# ModelSim etc

################################################################################
