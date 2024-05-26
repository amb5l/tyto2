toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

VIVADO_PART=xc7s50fgga484-1
VIVADO_LANGUAGE=VHDL-2008
VIVADO_SIM_TOP=tb_memac_fe
VIVADO_SIM_LIB=work
VIVADO_SIM_SRC.work=\
	$(toplevel)/src/common/ethernet/memac_util_pkg.vhd \
	$(toplevel)/src/common/crc/crc32_eth_8_pkg.vhd \
	$(toplevel)/src/common/ethernet/memac_tx_fe.vhd \
	$(toplevel)/src/common/ethernet/memac_rx_fe.vhd \
	$(toplevel)/src/common/tyto_queue_pkg.vhd \
	$(toplevel)/src/common/ethernet/test/$(VIVADO_SIM_TOP).vhd

all: sim

include $(make_fpga)/vivado.mak

VSCODE_TOP=$(VIVADO_SIM_TOP)
VSCODE_LIB=work
VSCODE_SRC.work=$(VIVADO_SIM_SRC_FILES.work)

include $(make_fpga)/vscode.mak
