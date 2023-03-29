# tmds_cap.mak

REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src
BUILD:=$(REPO_ROOT)/build

FPGA_VENDOR?=$(word 1,$(FPGA))
FPGA_FAMILY?=$(word 2,$(FPGA))
FPGA_DEVICE?=$(word 3,$(FPGA))

FPGA_TOOL:=vivado

ifneq (,$(findstring xc7z,$(FPGA_DEVICE)))
CORE_VHD:=$(SRC)/designs/$(DESIGN)/$(DESIGN)_z7ps.vhd
else
CORE_VHD:=$(SRC)/designs/$(DESIGN)/$(DESIGN)_mb.vhd
endif

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
	$(CORE_VHD) \
	$(SRC)/designs/$(DESIGN)/tmds_cap_csr.vhd \
	$(SRC)/designs/$(DESIGN)/tmds_cap_stream.vhd \
    $(if $(filter digilent_nexys_video,$(BOARD)),$(SRC)/common/ethernet/memac_axi4_rgmii.vhd) \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).vhd
ifneq (,$(findstring xc7z,$(FPGA_DEVICE)))
VIVADO_DSN_BD_TCL:=$(SRC)/designs/$(DESIGN)/$(DESIGN)_z7ps_sys.tcl
else
VIVADO_DSN_BD_TCL:=\
	$(SRC)/common/ddr3/$(BOARD)/axi_ddr3.tcl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN)_mb_cpu.tcl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN)_mb_sys.tcl
endif
ifeq (,$(findstring xc7z,$(FPGA_DEVICE)))
VIVADO_DSN_PROC_INST:=cpu
VIVADO_DSN_PROC_REF:=microblaze
endif
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).xdc

ifeq (,$(findstring xc7z,$(FPGA_DEVICE)))
VITIS_APP:=microblaze
VITIS_SRC:=\
	$(SRC)/designs/$(DESIGN)/microblaze/main.c
VITIS_INCLUDE:=\
	$(SRC)/designs/$(DESIGN)/microblaze \
	$(SRC)/common/basic/microblaze
endif

VSCODE_TOP:=$(VIVADO_DSN_TOP),$(VIVADO_SIM_TOP)
VSCODE_SRC:=$(VIVADO_DSN_VHDL)
ifeq (,$(findstring xc7z,$(FPGA_DEVICE)))
VSCODE_SRC+=
    $(BUILD)/$(DESIGN)/$(DESIGN)_$(BOARD)/.vivado/fpga.gen/sources_1/bd/axi_ddr3/synth/axi_ddr3.vhd \
    $(BUILD)/$(DESIGN)/$(DESIGN)_$(BOARD)/.vivado/fpga.gen/sources_1/bd/tmds_cap_mb_cpu/synth/tmds_cap_mb_cpu.vhd \
    $(BUILD)/$(DESIGN)/$(DESIGN)_$(BOARD)/.vivado/fpga.gen/sources_1/bd/tmds_cap_mb_sys/synth/tmds_cap_mb_sys.vhd
endif
VSCODE_XLIB:=unisim
VSCODE_XSRC.unisim:=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IBUFDS.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd \
    $(SRC)/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/model_secureip.vhd

include $(MAKE_FPGA)
