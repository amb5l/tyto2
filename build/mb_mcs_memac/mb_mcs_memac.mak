#################################################################################
# mb_mcs_memac.mak
#################################################################################

all: bit

toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

CPU=mb$(CPU_VARIANT)

#################################################################################
# Vitis

VITIS_FLOW=classic
VITIS_SRC=\
	$(toplevel)/src/common/basic/microblaze/printf.c \
	$(toplevel)/src/common/ethernet/mdio.h \
	$(toplevel)/src/designs/$(DESIGN)/software/memac_mcs.c \
	$(toplevel)/src/designs/$(DESIGN)/software/bsp.c \
	$(toplevel)/src/designs/$(DESIGN)/software/main.c
VITIS_INC=\
	$(toplevel)/src/common/basic/microblaze \
	$(toplevel)/src/common/ethernet \
	$(toplevel)/src/designs/$(DESIGN)/software
VITIS_SYM=APP_NAME=$(CPU)_mcs_test
VITIS_SYM_RLS=BUILD_CONFIG_RLS
VITIS_SYM_DBG=BUILD_CONFIG_DBG

include $(make_fpga)/vitis.mak

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL-2008
VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)
VIVADO_DSN_GEN=\
	RGMII_TX_ALIGN=$(MEMAC_RGMII_TX_ALIGN) \
	RGMII_RX_ALIGN=$(MEMAC_RGMII_RX_ALIGN) \
	TX_BUF_SIZE=$(MEMAC_TX_BUF_SIZE) \
	RX_BUF_SIZE=$(MEMAC_RX_BUF_SIZE)
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/basic/sync_reg_u.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/oddr.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/iddr.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/mmcm_v2.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/ram_tdp.vhd=VHDL-1993 \
	$(toplevel)/src/common/crc/crc32_eth_8_pkg.vhd \
	$(toplevel)/src/common/ethernet/memac_pkg.vhd \
	$(toplevel)/src/common/ethernet/memac_util_pkg.vhd \
	$(toplevel)/src/common/ethernet/memac_pdq.vhd \
	$(toplevel)/src/common/ethernet/memac_buf.vhd \
	$(toplevel)/src/common/ethernet/memac_tx_fe.vhd \
	$(toplevel)/src/common/ethernet/memac_rx_fe.vhd \
	$(toplevel)/src/common/ethernet/memac_tx.vhd \
	$(toplevel)/src/common/ethernet/memac_rx.vhd \
	$(toplevel)/src/common/ethernet/memac_spd.vhd \
	$(toplevel)/src/common/ethernet/memac_tx_$(PHY).vhd \
	$(toplevel)/src/common/ethernet/memac_rx_$(PHY).vhd \
	$(toplevel)/src/common/ethernet/$(FPGA_VENDOR)_$(FPGA_FAMILY)/memac_rx_$(PHY)_io.vhd \
	$(toplevel)/src/common/ethernet/memac_mdio.vhd \
	$(toplevel)/src/common/ethernet/memac_raw_rgmii.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(DESIGN)_bridge.vhd \
	$(toplevel)/src/common/mb/mcs/mb_mcs_wrapper.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
VIVADO_BD_TCL=$(toplevel)/src/common/mb/mcs/mb_mcs.tcl=$(CPU);100000000
VIVADO_PROC_REF=mb_mcs
VIVADO_PROC_CELL=cpu/U0/microblaze_I
VIVADO_DSN_ELF=$(VITIS_DIR)/$(VITIS_ELF_RLS)
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/ethernet/test/model_mdio.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/tb_$(VIVADO_DSN_TOP).vhd
VIVADO_SIM_ELF=$(VITIS_DIR)/$(VITIS_ELF_DBG)
VIVADO_SIM_RUN=tb_$(DESIGN)
VIVADO_XDC=\
	$(toplevel)/src/boards/$(BOARD)/$(BOARD).tcl=IMPL \
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).tcl=SYNTH,IMPL \
	$(toplevel)/src/common/ethernet/memac_tx_rgmii.tcl=IMPL \
	$(toplevel)/src/common/ethernet/memac_rx_rgmii.tcl=IMPL
VIVADO_DSN_XLIB=unisim
VIVADO_DSN_XSRC.unisim=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd

include $(make_fpga)/vivado.mak

################################################################################
