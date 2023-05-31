# makefile for tb_tmds_cap_csr

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
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/axi/axi_pkg.vhd \
	$(SRC)/common/video/xilinx_7series/hdmi_rx_selectio_fm.vhd \
	$(SRC)/common/video/xilinx_7series/hdmi_rx_selectio_clk.vhd \
	$(SRC)/common/video/xilinx_7series/hdmi_rx_selectio_align.vhd \
	$(SRC)/common/video/xilinx_7series/hdmi_rx_selectio.vhd \
	$(SRC)/designs/tmds_cap/tmds_cap_csr.vhd \
	$(SRC)/designs/tmds_cap/test/tmds_cap_csr/OsvvmTestCommonPkg.vhd \
	$(SRC)/designs/tmds_cap/test/tmds_cap_csr/TestCtrl_e.vhd \
	$(SRC)/designs/tmds_cap/test/tmds_cap_csr/tb_tmds_cap_csr.vhd \
	$(SRC)/designs/tmds_cap/test/tmds_cap_csr/tb_tmds_cap_csr_test1.vhd
SIM_TOP:=tb_tmds_cap_csr_test1
SIM_RUN:=tb_tmds_cap_csr_test1

include $(MAKE_FPGA)
