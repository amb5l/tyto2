#################################################################################
# makefile for tb_model_hram
#################################################################################

default: sim

toplevel:=$(shell git rev-parse --show-toplevel)

################################################################################
# Vivado

src=$(toplevel)/src

VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_SIM_SRC=\
	$(src)/common/tyto_types_pkg.vhd \
	$(src)/common/tyto_sim_pkg.vhd \
	$(src)/common/tyto_fifo_pkg.vhd \
	$(src)/common/hram/test/model_hram_ctrl.vhd \
	$(src)/common/hram/test/model_hram.vhd \
	$(src)/common/hram/test/tb_model_hram.vhd
VIVADO_SIM_RUN=\
	sim=tb_model_hram

include $(toplevel)/submodules/make-fpga/vivado.mak

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
