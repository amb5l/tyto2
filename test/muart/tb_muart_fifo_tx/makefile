toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

TEST_COUNT=3000
TB=tb_muart_fifo_tx

VIVADO_LANGUAGE=VHDL-2008
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/tyto_types_pkg.vhd \
	$(toplevel)/src/common/tyto_sim_pkg.vhd \
	$(toplevel)/src/common/tyto_queue_pkg.vhd \
	$(toplevel)/src/common/uart/xilinx/7series/muart_fifo.vhd \
	$(toplevel)/src/common/uart/muart_tx.vhd \
	$(toplevel)/src/common/uart/test/model_uart_rx.vhd \
	$(toplevel)/src/common/uart/test/$(TB).vhd
VIVADO_XLIB=unisim
VIVADO_XSRC.unisim:=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/FIFO18E1.vhd \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/FIFO36E1.vhd
VIVADO_SIM_RUN=$(TB);TEST_COUNT=$(TEST_COUNT)

all: sim

include $(make_fpga)/vivado.mak
