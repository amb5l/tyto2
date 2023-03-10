# makefile for tb_memac_fcs

REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src

SIM_TOP:=tb_memac_fcs
SIM_SRC:=\
    $(SRC)/common/crc/crc32_eth_8_pkg.vhd \
    $(SRC)/common/ethernet/memac_fcs.vhd \
    $(SRC)/common/ethernet/test/$(SIM_TOP).vhd
SIM_RUN=$(SIM_TOP)

VSCODE_TOP:=$(SIM_TOP)
VSCODE_SRC:=$(SIM_SRC)

include $(MAKE_FPGA)
