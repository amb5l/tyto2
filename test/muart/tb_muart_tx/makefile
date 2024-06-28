toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

TEST_COUNT=1000
DUT=muart_tx
TB=tb_$(DUT)

VIVADO_LANGUAGE=VHDL-2008
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_sim_pkg.vhd \
	$(toplevel)/src/common/tyto_queue_pkg.vhd \
	$(toplevel)/src/common/uart/$(DUT).vhd \
	$(toplevel)/src/common/uart/test/model_uart_rx.vhd \
	$(toplevel)/src/common/uart/test/$(TB).vhd
VIVADO_SIM_RUN=$(TB);TEST_COUNT=$(TEST_COUNT)

all: sim

include $(make_fpga)/vivado.mak
