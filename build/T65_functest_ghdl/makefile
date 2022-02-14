REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules

GHDL=ghdl
GHDLFLAGS=--std=08 -fsynopsys -fexplicit
GHDLRUNFLAGS=--unbuffered -gbin_file=$(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin -gref_file=$(SUBMODULES)/mos6502-trace/6502_functional_test.txt -gstart_address=1024

all: run

run: t65_functest $(SUBMODULES)/mos6502-trace/6502_functional_test.txt $(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin
		$(GHDL) -r t65_functest $(GHDLRUNFLAGS)

build: t65_functest

t65_functest: T65_Pack.o T65_MCode.o T65_ALU.o T65.o T65_functest.o
	$(GHDL) -e $(GHDLFLAGS) $@

$(SUBMODULES)/mos6502-trace/6502_functional_test.txt: $(SUBMODULES)/6502_65C02_functional_tests/bin_files/6502_functional_test.bin
	$(SUBMODULES)/mos6502-trace/trace.exe $< 0400 FD 34 > $@

%.o: $(SUBMODULES)/T65/%.vhd
	$(GHDL) -a $(GHDLFLAGS) $<
T65_functest.o: $(SRC)/designs/T65_functest/T65_functest.vhd
	$(GHDL) -a $(GHDLFLAGS) $<

clean:
	rm -f *.exe *.o *.cf
