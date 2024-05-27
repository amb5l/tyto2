toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

PACKET_COUNT=10

TB=tb_memac_fe

VIVADO_PART=xc7s50fgga484-1
VIVADO_LANGUAGE=VHDL-2008
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/ethernet/memac_util_pkg.vhd \
	$(toplevel)/src/common/crc/crc32_eth_8_pkg.vhd \
	$(toplevel)/src/common/ethernet/memac_tx_fe.vhd \
	$(toplevel)/src/common/ethernet/memac_rx_fe.vhd \
	$(toplevel)/src/common/tyto_queue_pkg.vhd \
	$(toplevel)/src/common/ethernet/test/$(TB).vhd
VIVADO_SIM_RUN=tb_memac_fe;PACKET_COUNT=$(PACKET_COUNT)

all: sim

include $(make_fpga)/vivado.mak

VSCODE_TOP=$(TB)
VSCODE_SRC=$(call VIVADO_SRC_FILE,$(VIVADO_SIM_SRC))

include $(make_fpga)/vscode.mak
