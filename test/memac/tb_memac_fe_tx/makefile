toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

PACKET_COUNT=10

TB=tb_memac_tx_fe

VIVADO_LANGUAGE=VHDL
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/ethernet/memac_pkg.vhd \
	$(toplevel)/src/common/ethernet/memac_util_pkg.vhd \
	$(toplevel)/src/common/crc/crc32_eth_8_pkg.vhd \
	$(toplevel)/src/common/crc/crc_eth.vhd \
	$(toplevel)/src/common/ethernet/memac_tx_fe.vhd \
	$(toplevel)/src/common/tyto_queue_pkg.vhd \
	$(toplevel)/src/common/ethernet/test/$(TB).vhd
VIVADO_SIM_RUN=$(TB);PACKET_COUNT=$(PACKET_COUNT)

all: sim

include $(make_fpga)/vivado.mak
