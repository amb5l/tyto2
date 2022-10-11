# makefile for tb_ps2_host

# basic definitions
REPO_ROOT=$(shell git rev-parse --show-toplevel)
SUBMODULES=$(REPO_ROOT)/submodules
MULTISIM_MK=$(SUBMODULES)/multisim-mk
SRC=$(REPO_ROOT)/src

# source files in compilation order
SOURCES=\
    $(SRC)/common/ps2/ps2_host.vhd    \
    $(SRC)/common/ps2/tb_ps2_host.vhd

# top unit name
TOP=tb_ps2_host

# VHDL options
VHDL_STANDARD=2008
VHDL_RELAXED=TRUE
#VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

# include multisim.mk here
include $(MULTISIM_MK)/multisim.mk
