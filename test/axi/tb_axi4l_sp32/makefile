#################################################################################
# makefile for tb_axi4l_sp32
#################################################################################

DUT=axi4l_sp32

default: sim_gui

#################################################################################

toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

test_src_dir:=$(toplevel)/src/common/axi/test/$(DUT)
test_src:=$(shell ls $(test_src_dir)/tb*test*.vhd)
tests:=$(foreach f,$(test_src),$(subst $(test_src_dir)/tb_$(DUT)_,,$(subst .vhd,,$f)))

################################################################################

SIM_LRM=2008
SIM_SRC+=\
    $(toplevel)/src/common/axi/axi_pkg.vhd=work \
	$(toplevel)/src/common/axi/$(DUT).vhd=work \
	$(test_src_dir)/OsvvmTestCommonPkg.vhd=work \
	$(test_src_dir)/TestCtrl_e.vhd=work \
	$(test_src_dir)/tb_$(DUT).vhd=work \
	$(addsuffix =work,$(test_src))

SIM_RUN=$(foreach t,$(tests),$t=cfg_tb_$(DUT)_$t)

#################################################################################
## Vivado
#
#include $(toplevel)/test/osvvm/vivado/osvvm.mak
#include $(toplevel)/test/osvvm/vivado/osvvm_common.mak
#include $(toplevel)/test/osvvm/vivado/osvvm_axi4common.mak
#include $(toplevel)/test/osvvm/vivado/osvvm_axi4.mak
#
#VIVADO_LANGUAGE=VHDL
#VIVADO_VHDL_LRM=$(SIM_LRM)
#VIVADO_SIM_SRC+=$(SIM_SRC)
#VIVADO_SIM_RUN=$(SIM_RUN)
#
#include $(make_fpga)/vivado.mak
#
#################################################################################
## XSim
#
#include $(toplevel)/test/osvvm/xsim/osvvm.mak
#include $(toplevel)/test/osvvm/xsim/osvvm_common.mak
#include $(toplevel)/test/osvvm/xsim/osvvm_axi4common.mak
#include $(toplevel)/test/osvvm/xsim/osvvm_axi4.mak
#
#XSIM_VHDL_LRM=$(SIM_LRM)
#XSIM_SRC+=$(SIM_SRC)
#XSIM_RUN=$(SIM_RUN)
#
#include $(make_fpga)/xsim.mak
#
#xsim:: post
#
#################################################################################
## GHDL
#
#include $(toplevel)/test/osvvm/ghdl/osvvm.mak
#include $(toplevel)/test/osvvm/ghdl/osvvm_common.mak
#include $(toplevel)/test/osvvm/ghdl/osvvm_axi4common.mak
#include $(toplevel)/test/osvvm/ghdl/osvvm_axi4.mak
#
#GHDL_LRM=$(SIM_LRM)
#GHDL_SRC+=$(SIM_SRC)
#GHDL_RUN=$(SIM_RUN)
#
#include $(make_fpga)/ghdl.mak
#
#ghdl::
#	@grep -q ERROR $(wildcard $(GHDL_DIR)/*test*.txt) && echo errors seen! && exit 1 || echo all tests passed!
#
#################################################################################
## NVC
#
#include $(toplevel)/test/osvvm/nvc/osvvm.mak
#include $(toplevel)/test/osvvm/nvc/osvvm_common.mak
#include $(toplevel)/test/osvvm/nvc/osvvm_axi4common.mak
#include $(toplevel)/test/osvvm/nvc/osvvm_axi4.mak
#
#NVC_VHDL_LRM=$(SIM_LRM)
#NVC_SRC+=$(SIM_SRC)
#NVC_RUN=$(SIM_RUN)
#
#include $(make_fpga)/nvc.mak
#
#nvc::
#	@grep -q ERROR $(wildcard $(NVC_DIR)/*test*.txt) && echo errors seen! && exit 1 || echo all tests passed!
#
################################################################################
# ModelSim etc

include $(toplevel)/test/osvvm/vsim/osvvm.mak
include $(toplevel)/test/osvvm/vsim/osvvm_common.mak
include $(toplevel)/test/osvvm/vsim/osvvm_axi4common.mak
include $(toplevel)/test/osvvm/vsim/osvvm_axi4lite.mak

VSIM_VHDL_LRM=$(SIM_LRM)
VSIM_SRC+=$(SIM_SRC)
VSIM_RUN=$(SIM_RUN)

include $(make_fpga)/vsim.mak

vsim::
	@grep -q ERROR $(wildcard $(VSIM_DIR)/*test*.txt) && echo errors seen! && exit 1 || echo all tests passed!

################################################################################
