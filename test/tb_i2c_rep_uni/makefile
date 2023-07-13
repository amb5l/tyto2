# makefile for tb_i2c_rep_uni

include $(shell realpath --relative-to . $(shell git rev-parse --show-toplevel))/submodules/make-fpga/make-fpga-h.mak

SRC:=$(REPO_ROOT)/src

SIM_TOP:=tb_i2c_rep_uni
SIM_SRC:=\
    $(SRC)/common/tyto_types_pkg.vhd \
    $(SRC)/common/i2c/i2c_ram1.vhd \
    $(SRC)/common/i2c/i2c_rep_uni.vhd \
    $(SRC)/common/i2c/test/tb_i2c_rep_uni.vhd
SIM_RUN=$(SIM_TOP)

VSCODE_TOP:=$(SIM_TOP)
VSCODE_SRC:=$(SIM_SRC)

include $(MAKE_FPGA)
