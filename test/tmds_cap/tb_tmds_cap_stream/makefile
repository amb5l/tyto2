# makefile for tb_tmds_cap_stream

include $(shell realpath --relative-to . $(shell git rev-parse --show-toplevel))/submodules/make-fpga/make-fpga-h.mak

SRC:=$(REPO_ROOT)/src
TEST:=$(REPO_ROOT)/test

include $(TEST)/osvvm.mak
include $(TEST)/osvvm_common.mak
include $(TEST)/osvvm_axi4common.mak
include $(TEST)/osvvm_axistream.mak

DUT:=tmds_cap_stream
TB:=tb_$(DUT)
TBSRC:=$(SRC)/designs/tmds_cap/test/$(DUT)
TESTS_VHD:=$(wildcard $(TBSRC)/$(TB)_*.vhd)
TESTS:=$(foreach f,$(TESTS_VHD),$(subst $(TBSRC)/$(TB)_,,$(subst .vhd,,$f)))

SIM_LIB+=work
SIM_SRC.work:=\
    $(SRC)/common/tyto_types_pkg.vhd \
    $(SRC)/common/axi/axi4s_pkg.vhd \
	$(SRC)/designs/tmds_cap/$(DUT).vhd \
	$(TBSRC)/OsvvmTestCommonPkg.vhd \
	$(TBSRC)/TestCtrl_e.vhd \
	$(TBSRC)/$(TB).vhd \
	$(TESTS_VHD)
SIM_TOP:=$(TB)
SIM_RUN:=$(foreach t,$(TESTS),$t,cfg_$(TB)_$t)

VSCODE_XLIB:=unisim
VSCODE_XSRC.unisim:=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd

NVC_EOPTS:=--no-collapse
NVC_GOPTS:=-H 32m
GHDL_VENDOR_LIBS:=xilinx-vivado

include $(MAKE_FPGA)

sim::
	@grep -q ERROR $(wildcard $(SIM_DIR)/$(TB)_*.txt) && echo errors found! && exit 1 || echo all tests passed!
