#################################################################################
# makefile for null design on MEGA65 R4
#################################################################################

board=mega65
board_variant=r4

default: bit

toplevel=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga
include $(make_fpga)/head.mak
src=$(toplevel)/src

VIVADO_PART=xc7a200tfbg484-2
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(board)
VIVADO_DSN_SRC=$(src)/boards/$(board)/$(board)$(addprefix _,$(board_variant)).vhd
VIVADO_XDC=$(src)/boards/$(board)/$(board)$(addprefix _,$(board_variant)).tcl=IMPL
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd=unisim

include $(make_fpga)/vivado.mak
