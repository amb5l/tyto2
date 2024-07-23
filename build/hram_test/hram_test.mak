#################################################################################
# hram_test.mak
#################################################################################

default: bit

toplevel=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

################################################################################
# Vivado

src=$(toplevel)/src

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)$(addprefix _,$(BOARD_VARIANT))
VIVADO_DSN_SRC=\
	$(src)/common/hram/xilinx/hram.vhd
VIVADO_SIM_SRC=\
	$(src)/common/tyto_fifo_pkg.vhd \
	$(src)/common/hram/test/model_hram_ctrl.vhd \
	$(src)/common/hram/test/model_hram.vhd \
	$(src)/common/hram/test/tb_model_hram.vhd
VIVADO_SIM_RUN=tb_model_hram

include $(make_fpga)/vivado.mak

################################################################################
