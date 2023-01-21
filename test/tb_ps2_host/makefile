# makefile for tb_ps2_host

REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))

SRC:=$(REPO_ROOT)/src

SIMULATORS:=ghdl nvc vsim xsim
SIM_TOP:=tb_ps2_host
SIM_SRC:=\
    $(SRC)/common/ps2/ps2_host.vhd    \
    $(SRC)/common/ps2/$(SIM_TOP).vhd
SIM_RUN=$(SIM_TOP)

VSCODE_SRC:=$(SIM_SRC)
V4P_TOP:=$(SIM_TOP)

include $(REPO_ROOT)/build/build.mak
