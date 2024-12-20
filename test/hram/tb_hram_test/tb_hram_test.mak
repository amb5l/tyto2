#################################################################################
# tb_hram_ctrl.mak
#################################################################################

default: sim_gui

toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

DUT=hram_test
TB=tb_$(DUT)
ROWS_LOG2=13
COLS_LOG2=9

################################################################################
# autogenerated VHDL package

random_1to1_py=$(toplevel)/src/designs/MEGAtest/random_1to1.py
random_1to1_vhd=$(abspath ./random_1to1.vhd)

$(random_1to1_vhd): $(random_1to1_py)
	@python $(random_1to1_py) $(ROWS_LOG2) > $@

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_utils_pkg.vhd \
	$(toplevel)/src/common/basic/xilinx/sync.vhd \
	$(toplevel)/src/common/hram/test/model_hram.vhd \
	$(toplevel)/src/common/basic/csr.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm_drp.vhd \
	$(toplevel)/src/designs/MEGAtest/overclock.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/ram_sdp_32x6.vhd \
	$(toplevel)/src/common/basic/xilinx/mux2.vhd \
	$(toplevel)/src/common/hram/$(FPGA_VENDOR)/$(FPGA_FAMILY)/hram_ctrl.vhd \
	$(random_1to1_vhd) \
	$(toplevel)/src/designs/MEGAtest/$(DUT).vhd \
	$(toplevel)/submodules/vhdl_prng/rtl/rng_xoshiro128plusplus.vhdl \
	$(toplevel)/src/designs/MEGAtest/test/$(TB).vhd
VIVADO_SIM_RUN=\
	min=$(TB);OUTPUT_DELAY="MIN",ROWS_LOG2=$(ROWS_LOG2),COLS_LOG2=$(COLS_LOG2) \
	max=$(TB);OUTPUT_DELAY="MAX",ROWS_LOG2=$(ROWS_LOG2),COLS_LOG2=$(COLS_LOG2) \
	max_min=$(TB);OUTPUT_DELAY="MAX_MIN",ROWS_LOG2=$(ROWS_LOG2),COLS_LOG2=$(COLS_LOG2) \
	uniform=$(TB);OUTPUT_DELAY="UNIFORM",ROWS_LOG2=$(ROWS_LOG2),COLS_LOG2=$(COLS_LOG2)
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_VPKG.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDELAYE2.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IDDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/ODDR.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IOBUF.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/RAM32M.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
# XSim

XSIM_VHDL_LRM=$(VIVADO_VHDL_LRM)
XSIM_SRC=$(VIVADO_SIM_SRC)
XSIM_RUN=$(VIVADO_SIM_RUN)

include $(toplevel)/submodules/make-fpga/xsim.mak

################################################################################
# GHDL

GHDL_LRM=$(VIVADO_VHDL_LRM)
GHDL_SRC=$(VIVADO_SIM_SRC)
GHDL_RUN=$(VIVADO_SIM_RUN)
GHDL_VENDOR_LIB=xilinx-vivado

include $(toplevel)/submodules/make-fpga/ghdl.mak

################################################################################
# NVC

NVC_VHDL_LRM=$(VIVADO_VHDL_LRM)
NVC_SRC=$(VIVADO_SIM_SRC)
NVC_RUN=$(VIVADO_SIM_RUN)

include $(toplevel)/submodules/make-fpga/nvc.mak

################################################################################
# ModelSim/Questa/etc

VSIM_VHDL_LRM=$(VIVADO_VHDL_LRM)
VSIM_SRC=$(VIVADO_SIM_SRC)
VSIM_RUN=$(VIVADO_SIM_RUN)

include $(toplevel)/submodules/make-fpga/vsim.mak

################################################################################
