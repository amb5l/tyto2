# tmds_cap.mak

REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src

FPGA_VENDOR?=$(word 1,$(FPGA))
FPGA_FAMILY?=$(word 2,$(FPGA))

FPGA_TOOL:=vivado

VIVADO_DSN_TOP:=$(DESIGN)_$(BOARD)
VIVADO_DSN_VHDL:=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/mmcm.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/hdmi_rx_selectio_fm.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/hdmi_rx_selectio_clk.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/hdmi_rx_selectio_align.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/hdmi_rx_selectio.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)_$(FPGA_FAMILY)/hdmi_tx_selectio.vhd \
	$(SRC)/common/axi/axi_pkg.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN)_mb.vhd \
	$(SRC)/designs/$(DESIGN)/tmds_cap_regs_axi.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).vhd
VIVADO_DSN_BD_TCL:=\
	$(SRC)/boards/$(BOARD)/axi_ddr3.tcl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN)_mb_cpu.tcl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN)_mb_sys.tcl
VIVADO_DSN_PROC_INST:=cpu
VIVADO_DSN_PROC_REF:=microblaze
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).xdc

VIVADO_SIM_TOP:=tb_$(VIVADO_DSN_TOP)
VIVADO_SIM_VHDL_2008:=\
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/common/video/video_mode.vhd \
	$(SRC)/common/video/model_video_out_clock.vhd \
	$(SRC)/common/video/video_out_timing.vhd \
	$(SRC)/common/video/video_out_test_pattern.vhd \
	$(SRC)/common/video/model_tmds_cdr_des.vhd \
	$(SRC)/common/video/model_hdmi_decoder.vhd \
	$(SRC)/common/video/model_vga_sink.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_SIM_TOP).vhd

VITIS_APP:=microblaze
VITIS_SRC:=\
	$(SRC)/designs/$(DESIGN)/microblaze/main.c
VITIS_INCLUDE:=\
	$(SRC)/designs/$(DESIGN)/microblaze \
	$(SRC)/common/basic/microblaze

SIMULATOR:=xsim_cmd xsim_ide

SIM_TOP:=$(VIVADO_SIM_TOP)
SIM_SRC:=$(VIVADO_DSN_VHDL) $(VIVADO_SIM_VHDL_2008)
SIM_RUN:=$(SIM_TOP)

VSCODE_TOP:=$(VIVADO_DSN_TOP),$(VIVADO_SIM_TOP)
VSCODE_SRC:=$(VIVADO_DSN_VHDL) $(VIVADO_SIM_VHDL_2008)
VSCODE_XLIB:=unisim
VSCODE_XSRC:=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd

include $(MAKE_FPGA)
