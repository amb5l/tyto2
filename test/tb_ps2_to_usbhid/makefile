# makefile for tb_ps2_to_usbhid

REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src

SIM_TOP:=tb_ps2_to_usbhid
SIM_SRC:=\
	$(SRC)/common/usb/usb_hid_codes_pkg.vhd     \
	$(SRC)/common/ps2/ps2_host.vhd              \
	$(SRC)/common/ps2/ps2set2_to_usbhid_pkg.vhd \
	$(SRC)/common/ps2/ps2_to_usbhid.vhd         \
	$(SRC)/common/ps2/$(SIM_TOP).vhd
SIM_RUN=$(SIM_TOP)

VSCODE_TOP:=$(SIM_TOP)
VSCODE_SRC:=$(SIM_SRC)

include $(MAKE_FPGA)
