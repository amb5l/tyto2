#################################################################################
# makefile for tb_model_hram
#################################################################################

default: sim

toplevel=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga
include $(make_fpga)/head.mak

################################################################################
# Vivado

src=$(toplevel)/src

VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_SIM_SRC=\
	$(src)/common/tyto_fifo_pkg.vhd \
	$(src)/common/hram/test/model_hram_ctrl.vhd \
	$(src)/common/hram/test/model_hram.vhd \
	$(src)/common/hram/test/tb_model_hram.vhd
VIVADO_SIM_RUN=\
	sim=tb_model_hram

include $(make_fpga)/vivado.mak

################################################################################
# ModelSim/Questa/etc

VSIM_VHDL_LRM=$(VIVADO_VHDL_LRM)
VSIM_SRC=$(VIVADO_SIM_SRC)
VSIM_RUN=$(VIVADO_SIM_RUN)

include $(make_fpga)/vsim.mak

################################################################################
