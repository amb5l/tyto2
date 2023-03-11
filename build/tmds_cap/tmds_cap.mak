# tmds_cap.mak

REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
MAKE_FPGA:=$(REPO_ROOT)/submodules/make-fpga/make-fpga.mak
SRC:=$(REPO_ROOT)/src

FPGA_VENDOR?=$(word 1,$(FPGA))
FPGA_FAMILY?=$(word 2,$(FPGA))
FPGA_DEVICE?=$(word 3,$(FPGA))

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
	$(if $(findstring xc7z,$(FPGA_DEVICE)),$(SRC)/designs/$(DESIGN)/$(DESIGN)_z7ps.vhd,$(SRC)/designs/$(DESIGN)/$(DESIGN)_mb.vhd) \
	$(SRC)/designs/$(DESIGN)/tmds_cap_regs_axi.vhd \
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

include $(MAKE_FPGA)
