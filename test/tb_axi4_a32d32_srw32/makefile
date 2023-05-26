# makefile for tb_axi4_a32d32_srw32

REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src
TEST:=$(REPO_ROOT)/test

include $(TEST)/osvvm.mak
include $(TEST)/osvvm_common.mak
include $(TEST)/osvvm_axi4common.mak
include $(TEST)/osvvm_axi4.mak

SIM_LIB:=$(SIM_LIB) work
SIM_SRC.work:=\
    $(SRC)/common/axi/axi4_pkg.vhd \
	$(SRC)/common/axi/axi4_a32d32_srw32.vhd \
	$(SRC)/common/axi/test/axi4_a32d32_srw32/OsvvmTestCommonPkg.vhd \
	$(SRC)/common/axi/test/axi4_a32d32_srw32/TestCtrl_e.vhd \
	$(SRC)/common/axi/test/axi4_a32d32_srw32/tb_axi4_a32d32_srw32.vhd \
	$(SRC)/common/axi/test/axi4_a32d32_srw32/tb_axi4_a32d32_srw32_test1.vhd
SIM_TOP:=cfg_tb_axi4_a32d32_srw32_test1
SIM_RUN:=cfg_tb_axi4_a32d32_srw32_test1

NVC_GOPTS:=-H 32m

include $(MAKE_FPGA)
