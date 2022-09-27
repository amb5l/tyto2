# makefile for tb_ps2_to_usbhid

# path to root of this repository
REPO_ROOT=$(shell git rev-parse --show-toplevel)

# path to this repository's submodules
SUBMODULES=$(REPO_ROOT)/submodules

# path to multisim.mk include
MULTISIM_MK=$(SUBMODULES)/multisim-mk

# this repository's source directory
SRC=$(REPO_ROOT)/src

# source files in compilation order
SOURCES=\
	$(SRC)/common/usb/usb_hid_codes_pkg.vhd     \
	$(SRC)/common/ps2/ps2_host.vhd              \
	$(SRC)/common/ps2/ps2set2_to_usbhid_pkg.vhd \
	$(SRC)/common/ps2/ps2_to_usbhid.vhd         \
	$(SRC)/common/ps2/tb_ps2_to_usbhid.vhd

# top unit name
TOP=tb_ps2_to_usbhid

# VHDL standard
VHDL_STANDARD=2008

# relaxed VHDL rules e.g. impure behaviour by pure functions
VHDL_RELAXED=TRUE

# suppress IEEE assertions e.g. metavalues in to_integer
#VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

# include multisim.mk here
include $(MULTISIM_MK)/multisim.mk
