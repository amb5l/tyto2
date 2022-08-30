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

all: sim
	$(info $(shell date))

sim: $(REF_FILE) $(FUNCTEST_BIN)
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_Pack.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_MCode.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65_ALU.vhd
	vcom -work work -2002 -explicit -vopt -stats=none $(SUBMODULES)/T65/T65.vhd
	vcom -work work -2008 -explicit -vopt -stats=none $(SRC)/designs/T65_functest/T65_functest.vhd
	vsim -c -gbin_file=$(FUNCTEST_BIN) -gref_file=$(REF_FILE) -gstart_address=1024 -onfinish stop T65_functest -do "onfinish exit; run -all"

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

clean:
	rm -rf $(BUILD_6502_DIR) $(REF_DIR)
	rm -f *.log modelsim.ini transcript
	rm -rf work
