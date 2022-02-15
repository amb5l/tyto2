REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules

FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(SUBMODULES)/6502_65C02_functional_tests/bin_files/$(FUNCTEST).bin
REF_DIR=ref
REF_FILE=$(abspath $(REF_DIR)/$(FUNCTEST).txt)
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace.exe

all: $(REF_FILE) $(FUNCTEST_BIN)
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_Pack.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_MCode.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_ALU.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65.vhd
	vcom -work work -2008 -explicit -vopt -stats=none $(SRC)/designs/T65_functest/T65_functest.vhd
	vsim -c -gbin_file=$(FUNCTEST_BIN) -gref_file=$(REF_FILE) -gstart_address=1024 -onfinish stop T65_functest -do "onfinish exit; run -all"

ref: $(REF_FILE)
$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

$(REF_DIR):
	mkdir $(REF_DIR)

clean:
	rm -rf work
	rm -rf ref
	rm -f modelsim.ini
	rm -f transcript
