# tmds_cap.mak

include $(shell realpath --relative-to . $(shell git rev-parse --show-toplevel))/submodules/make-fpga/make-fpga-h.mak

SRC:=$(REPO_ROOT)/src
GEN_DIR:=gen
GEN:=$(MAKE_DIR)/$(GEN_DIR)

CSR_RA_PY:=$(SRC)/designs/$(DESIGN)/$(DESIGN)_csr_ra.py
CSR_RA_CSV:=$(SRC)/designs/$(DESIGN)/$(DESIGN)_csr_ra.csv
CSR_RA_VHD:=$(GEN)/$(DESIGN)_csr_ra_pkg.vhd
CSR_RA_H:=$(GEN)/$(DESIGN)_csr_ra.h

BOARD_VARIANT:=$(BOARD)$(addprefix _,$(BOARD_VARIANT))
FPGA_VENDOR?=$(word 1,$(FPGA))
FPGA_FAMILY?=$(word 2,$(FPGA))
FPGA_DEVICE?=$(word 3,$(FPGA))

FPGA_TOOL:=vivado

ifneq (,$(findstring xc7z,$(FPGA_DEVICE)))
CORE_VHD:=$(SRC)/designs/$(DESIGN)/$(FPGA_VENDOR)/$(FPGA_FAMILY)/$(DESIGN)_z7ps.vhd
else
CORE_VHD:=$(SRC)/designs/$(DESIGN)/$(FPGA_VENDOR)/$(FPGA_FAMILY)/$(DESIGN)_mb.vhd
endif

VIVADO_DSN_TOP:=$(DESIGN)_$(BOARD_VARIANT)
VIVADO_DSN_VHDL_2008:=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)/$(FPGA_FAMILY)/hdmi_rx_selectio_fm.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)/$(FPGA_FAMILY)/hdmi_rx_selectio_clk.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)/$(FPGA_FAMILY)/hdmi_rx_selectio_align.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)/$(FPGA_FAMILY)/hdmi_rx_selectio.vhd \
    $(SRC)/common/video/$(FPGA_VENDOR)/$(FPGA_FAMILY)/hdmi_tx_selectio.vhd \
	$(SRC)/common/axi/axi4_pkg.vhd \
	$(SRC)/common/axi/axi4s_pkg.vhd \
	$(SRC)/common/basic/fifo_pkg.vhd \
	$(SRC)/common/axi/axi4_a32d32_srw32.vhd \
	$(CSR_RA_VHD) \
	$(SRC)/designs/$(DESIGN)/$(DESIGN)_csr.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN)_stream.vhd \
	$(SRC)/designs/$(DESIGN)/$(FPGA_VENDOR)/$(FPGA_FAMILY)/$(DESIGN)_io.vhd \
	$(SRC)/common/i2c/i2c_rep_uni.vhd \
    $(if $(findstring xc7z,$(FPGA_DEVICE)),,$(SRC)/common/ethernet/memac_axi4_rgmii.vhd) \
	$(CORE_VHD) \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD_VARIANT).vhd
ifneq (,$(findstring xc7z,$(FPGA_DEVICE)))
VIVADO_DSN_BD_TCL:=$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_z7ps_sys.tcl
else
VIVADO_DSN_BD_TCL:=\
	$(SRC)/common/ddr3/$(BOARD)/axi_ddr3.tcl \
	$(SRC)/designs/$(DESIGN)/$(FPGA_VENDOR)/$(FPGA_FAMILY)/$(DESIGN)_mb_cpu.tcl \
	$(SRC)/designs/$(DESIGN)/$(FPGA_VENDOR)/$(FPGA_FAMILY)/$(DESIGN)_mb_sys.tcl
endif
ifeq (,$(findstring xc7z,$(FPGA_DEVICE)))
VIVADO_DSN_PROC_INST:=cpu
VIVADO_DSN_PROC_REF:=microblaze
endif
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD_VARIANT).tcl \
	$(SRC)/designs/$(DESIGN)/$(FPGA_VENDOR)/$(FPGA_FAMILY)/$(DESIGN)_x7.xdc \
	$(if $(findstring xc7z,$(FPGA_DEVICE)),$(SRC)/designs/$(DESIGN)/$(FPGA_VENDOR)/$(FPGA_FAMILY)/$(DESIGN)_z7.xdc) \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).xdc

# workaround for synthesis crashes
VIVADO_BD_SCP_MODE:=Singular

VITIS_SRC_DIR:=$(SRC)/designs/$(DESIGN)/software/server
VITIS_DIR=.vitis
ifeq (,$(findstring xc7z,$(FPGA_DEVICE)))
VITIS_ARCH:=microblaze
else
VITIS_ARCH:=arm
VITIS_PROC?=ps7_cortexa9_0
VITIS_OS?=standalone
VITIS_DOMAIN?=$(VITIS_OS)_domain
VITIS_SRC=\
	$(VITIS_SRC_DIR)/z7ps/hal.h \
	$(VITIS_SRC_DIR)/z7ps/hal.c
VITIS_INCLUDE=$(VITIS_SRC_DIR)/z7ps
endif
VITIS_APP:=$(DESIGN)
VITIS_SRC+=\
	$(CSR_RA_H) \
	$(VITIS_SRC_DIR)/global.c \
	$(VITIS_SRC_DIR)/global.h \
	$(VITIS_SRC_DIR)/csr.h \
	$(VITIS_SRC_DIR)/dma.c \
	$(VITIS_SRC_DIR)/dma.h \
	$(VITIS_SRC_DIR)/sdram.c \
	$(VITIS_SRC_DIR)/sdram.h \
	$(VITIS_SRC_DIR)/cap.c \
	$(VITIS_SRC_DIR)/cap.h \
	$(VITIS_SRC_DIR)/server.c \
	$(VITIS_SRC_DIR)/server.h \
	$(VITIS_SRC_DIR)/main.c
VITIS_INCLUDE+=$(VITIS_SRC_DIR) $(GEN)
VITIS_BSP_LIB:=lwip213
VITIS_BSP_CFG:=\
	no_sys_no_timers:false \
	lwip_dhcp:true

VSCODE_TOP:=$(VIVADO_DSN_TOP),$(VIVADO_SIM_TOP)
VSCODE_SRC:=$(VIVADO_DSN_VHDL_2008)
ifeq (,$(findstring xc7z,$(FPGA_DEVICE)))
VSCODE_SRC+=
    $(MAKE_DIR)/.vivado/fpga.gen/sources_1/bd/axi_ddr3/synth/axi_ddr3.vhd \
    $(MAKE_DIR)/.vivado/fpga.gen/sources_1/bd/$(DESIGN)_mb_cpu/synth/$(DESIGN)_mb_cpu.vhd \
    $(MAKE_DIR)/.vivado/fpga.gen/sources_1/bd/$(DESIGN)_mb_sys/synth/$(DESIGN)_mb_sys.vhd
endif
VSCODE_XLIB:=unisim
VSCODE_XSRC.unisim:=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/IBUFDS.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd \
    $(SRC)/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/model_secureip.vhd

include $(MAKE_FPGA)

run::
	python $(SRC)/designs/$(DESIGN)/software/client/tmds_cap.py

$(GEN_DIR):
	bash -c "mkdir -p $@"

$(CSR_RA_VHD) $(CSR_RA_H): $(CSR_RA_CSV) | $(GEN_DIR)
	python $(CSR_RA_PY) 8 $(CSR_RA_CSV) $(CSR_RA_VHD) $(CSR_RA_H)
