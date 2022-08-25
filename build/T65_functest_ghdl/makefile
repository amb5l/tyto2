REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules

CA65=ca65
LD65=ld65
BUILD_6502_DIR=6502
FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg
REF_DIR=ref
REF_FILE=$(REF_DIR)/$(FUNCTEST).txt
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace.exe

GHDL=ghdl
GHDLFLAGS=--std=08 -fsynopsys -fexplicit
GHDLRUNFLAGS=--unbuffered -gbin_file=$(FUNCTEST_BIN) -gref_file=$(REF_FILE) -gstart_address=1024

all: run
	$(info $(shell date))

run: t65_functest $(REF_FILE) $(FUNCTEST_BIN)
	$(info $(shell date))
	$(GHDL) -r t65_functest $(GHDLRUNFLAGS)

build: t65_functest

t65_functest: T65_Pack.o T65_MCode.o T65_ALU.o T65.o T65_functest.o
	$(GHDL) -e $(GHDLFLAGS) $@

bin: $(FUNCTEST_BIN)
$(FUNCTEST_BIN): $(BUILD_6502_DIR)/$(FUNCTEST).o $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(FUNCTEST).map -C $(FUNCTEST_CFG)

$(BUILD_6502_DIR)/$(FUNCTEST).o: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(FUNCTEST).lst

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

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
	rm -f *.exe *.o *.cf
	rm -rf $(BUILD_6502_DIR)
	rm -rf $(REF_DIR)    
