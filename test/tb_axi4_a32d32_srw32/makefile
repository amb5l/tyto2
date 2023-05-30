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

TESTDIR:=$(SRC)/common/axi/test/axi4_a32d32_srw32
TESTBENCH:=tb_axi4_a32d32_srw32
TESTSRC:=$(wildcard $(TESTDIR)/$(TESTBENCH)_test*.vhd)
TESTS:=$(foreach f,$(TESTSRC),$(subst $(TESTDIR)/$(TESTBENCH)_,,$(subst .vhd,,$f)))

SIM_LIB:=$(SIM_LIB) work
SIM_SRC.work:=\
    $(SRC)/common/basic/fifo_pkg.vhd \
    $(SRC)/common/axi/axi4_pkg.vhd \
	$(SRC)/common/axi/axi4_a32d32_srw32.vhd \
	$(TESTDIR)/OsvvmTestCommonPkg.vhd \
	$(TESTDIR)/TestCtrl_e.vhd \
	$(TESTDIR)/tb_axi4_a32d32_srw32.vhd \
	$(TESTSRC)
SIM_TOP:=tb_axi4_a32d32_srw32
SIM_RUN:=$(foreach t,$(TESTS),$t,cfg_tb_axi4_a32d32_srw32_$t)

NVC_GOPTS:=-H 32m

include $(MAKE_FPGA)

sim::
	@grep -q ERROR $(wildcard $(SIM_DIR)/*test*.txt) && echo "errors found!" && exit 1 || echo "all tests passed!"
