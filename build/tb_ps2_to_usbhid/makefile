# makefile for tb_ps2_to_usbhid

# path to multisim.mk include
REPO_ROOT=$(shell git rev-parse --show-toplevel)
SUBMODULES=$(REPO_ROOT)/submodules
MULTISIM_MK=$(SUBMODULES)/multisim-mk

# source files in compilation order
SRC=$(REPO_ROOT)/src
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
