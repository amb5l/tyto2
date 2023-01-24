# makefile for tb_ps2_host

REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src

SIMULATOR:=ghdl nvc vsim xsim

SIM_TOP:=tb_ps2_host
SIM_SRC:=\
    $(SRC)/common/ps2/ps2_host.vhd    \
    $(SRC)/common/ps2/$(SIM_TOP).vhd
SIM_RUN=$(SIM_TOP)

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(SIM_TOP)

include $(MAKE_FPGA)
