REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules

all: $(SUBMODULES)/mos6502-trace/6502_functional_test.txt $(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_Pack.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_MCode.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_ALU.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65.vhd
	vcom -work work -2008 -explicit -vopt -stats=none $(SRC)/designs/T65_functest/T65_functest.vhd
	vsim -c -gbin_file=$(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin -gref_file=$(SUBMODULES)/mos6502-trace/6502_functional_test.txt -gstart_address=1024 -onfinish stop T65_functest -do "onfinish exit; run -all"

ref: $(SUBMODULES)/mos6502-trace/6502_functional_test.txt
$(SUBMODULES)/mos6502-trace/6502_functional_test.txt: $(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin
	$(SUBMODULES)/mos6502-trace/trace.exe $< 0400 FD 34 > $@

clean:
	rm -rf work
	rm -f modelsim.ini
	rm -f transcript
