REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules

FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(SUBMODULES)/6502_65C02_functional_tests/bin_files/$(FUNCTEST).bin
REF_DIR=ref
REF_FILE=$(abspath $(REF_DIR)/$(FUNCTEST).txt)
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace.exe

GHDL=ghdl
GHDLFLAGS=--std=08 -fsynopsys -fexplicit
GHDLRUNFLAGS=--unbuffered -gbin_file=$(FUNCTEST_BIN) -gref_file=$(REF_FILE) -gstart_address=1024

all: run

run: t65_functest $(REF_FILE) $(FUNCTEST_BIN)
		$(GHDL) -r t65_functest $(GHDLRUNFLAGS)

build: t65_functest

t65_functest: T65_Pack.o T65_MCode.o T65_ALU.o T65.o T65_functest.o
	$(GHDL) -e $(GHDLFLAGS) $@

ref: $(REF_FILE)
$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

$(REF_DIR):
	mkdir $(REF_DIR)

%.o: $(SUBMODULES)/T65/%.vhd
	$(GHDL) -a $(GHDLFLAGS) $<
T65_functest.o: $(SRC)/designs/T65_functest/T65_functest.vhd
	$(GHDL) -a $(GHDLFLAGS) $<

clean:
	rm -rf ref
	rm -f *.exe *.o *.cf
