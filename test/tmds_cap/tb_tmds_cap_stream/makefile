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
#include $(TEST)/osvvm_axi4common.mak
include $(TEST)/osvvm_axistream.mak

DUT:=tmds_cap_stream
TESTDIR:=$(SRC)/designs/tmds_cap/test/$(DUT)
TESTBENCH:=tb_$(DUT)
TESTSRC:=$(wildcard $(TESTDIR)/$(TESTBENCH)_test*.vhd)
TESTS:=$(foreach f,$(TESTSRC),$(subst $(TESTDIR)/$(TESTBENCH)_,,$(subst .vhd,,$f)))

SIM_LIB:=$(SIM_LIB) work
SIM_SRC.work:=\
    $(SRC)/common/tyto_types_pkg.vhd \
    $(SRC)/common/axi/axi4s_pkg.vhd \
	$(SRC)/designs/tmds_cap/$(DUT).vhd \
	$(TESTDIR)/OsvvmTestCommonPkg.vhd \
	$(TESTDIR)/TestCtrl_e.vhd \
	$(TESTDIR)/$(TESTBENCH).vhd \
	$(TESTSRC)
SIM_TOP:=$(TESTBENCH)
SIM_RUN:=$(foreach t,$(TESTS),$t,cfg_$(TESTBENCH)_$t)

NVC_EOPTS:=--no-collapse
NVC_GOPTS:=-H 32m

include $(MAKE_FPGA)

sim::
	@grep -q ERROR $(wildcard $(SIM_DIR)/*test*.txt) && echo "errors found!" && exit 1 || echo "all tests passed!"
