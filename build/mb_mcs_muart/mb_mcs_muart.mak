#################################################################################
# mb_mcs_muart.mak
#################################################################################

default: bit

toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

CPU=mb$(CPU_VARIANT)
CPU_DEBUG=1
LOG_FILE=$(call xpath,./log.txt)

#################################################################################
# Vitis

VITIS_FLOW=classic
VITIS_SRC=\
	$(toplevel)/src/common/basic/microblaze/printf.c \
	$(toplevel)/src/common/basic/microblaze/printf.h \
	$(toplevel)/src/common/basic/microblaze/peekpoke.h \
	$(toplevel)/src/designs/$(DESIGN)/software/bsp.c \
	$(toplevel)/src/designs/$(DESIGN)/software/bsp.h \
	$(toplevel)/src/designs/$(DESIGN)/software/main.c
VITIS_INC=\
	$(toplevel)/src/common/basic/microblaze \
	$(toplevel)/src/designs/$(DESIGN)/software
VITIS_SYM=APP_NAME=$(DESIGN)_$(BOARD)
VITIS_SYM_RLS=BUILD_CONFIG_RLS
VITIS_SYM_DBG=BUILD_CONFIG_DBG

include $(make_fpga)/vitis.mak

################################################################################
# Vivado

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)
VIVADO_DSN_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/basic/sync_reg_u.vhd \
	$(toplevel)/src/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm_v2.vhd \
	$(toplevel)/src/common/uart/$(FPGA_VENDOR)/$(FPGA_FAMILY)/muart_fifo.vhd \
	$(toplevel)/src/common/uart/muart_tx.vhd \
	$(toplevel)/src/common/mb/mcs/mb_mcs_wrapper.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
VIVADO_BD_TCL=\
	$(toplevel)/src/common/mb/mcs/mb_mcs.tcl=$(CPU);100000000;$(CPU_DEBUG)
VIVADO_PROC_REF=mb_mcs
VIVADO_PROC_CELL=cpu/U0/microblaze_I
VIVADO_DSN_ELF=$(VITIS_DIR)/$(VITIS_ELF_RLS)
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/uart/test/model_uart_rx.vhd \
	$(toplevel)/src/common/uart/test/model_console.vhd \
	$(toplevel)/src/designs/$(DESIGN)/$(BOARD)/tb_$(VIVADO_DSN_TOP).vhd
VIVADO_SIM_ELF=$(VITIS_DIR)/$(VITIS_ELF_DBG)
VIVADO_SIM_RUN=\
	tb_$(DESIGN)_$(BOARD);FILENAME=$(LOG_FILE)
VIVADO_XDC=$(toplevel)/src/boards/$(BOARD)/$(BOARD).tcl=IMPL
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/FIFO18E1.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/FIFO36E1.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################

clean::
	@rm -f $(LOG_FILE)
