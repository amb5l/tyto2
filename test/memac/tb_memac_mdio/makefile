toplevel=$(if $(filter Windows_NT,$(OS)),$(shell cygpath -m $(shell git rev-parse --show-toplevel)),$(shell git rev-parse --show-toplevel))
make_fpga=$(toplevel)/submodules/make-fpga

include $(make_fpga)/head.mak

DUT=memac_mdio
TB=tb_$(DUT)
COUNT=1000

VIVADO_LANGUAGE=VHDL-2008
VIVADO_SIM_SRC=\
	$(toplevel)/src/common/ethernet/memac_util_pkg.vhd \
	$(toplevel)/src/common/ethernet/$(DUT).vhd \
	$(toplevel)/src/common/ethernet/test/$(TB).vhd
VIVADO_SIM_RUN=$(TB);COUNT=$(COUNT)

all: sim

include $(make_fpga)/vivado.mak

VSCODE_TOP=$(TB)
VSCODE_SRC=$(call VIVADO_SRC_FILE,$(VIVADO_SIM_SRC))

include $(make_fpga)/vscode.mak
