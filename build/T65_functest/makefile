# makefile for T65_functest_multisim

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SUBMODULES=$(REPO_ROOT)/submodules
MULTISIM_MK=$(SUBMODULES)/multisim-mk

################################################################################
# 6502 binary

CA65=ca65
LD65=ld65
BUILD_6502_DIR=6502/
FUNCTEST=6502_functional_test
FUNCTEST_BIN=$(BUILD_6502_DIR)/$(FUNCTEST).bin
FUNCTEST_SRC=$(SUBMODULES)/6502_65C02_functional_tests/ca65/$(FUNCTEST).ca65
FUNCTEST_CFG=$(SUBMODULES)/6502_65C02_functional_tests/ca65/example.cfg

bin: $(FUNCTEST_BIN)

$(FUNCTEST_BIN): $(BUILD_6502_DIR)/$(FUNCTEST).o $(FUNCTEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(FUNCTEST).map -C $(FUNCTEST_CFG)

$(BUILD_6502_DIR)/$(FUNCTEST).o: $(FUNCTEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(FUNCTEST).lst

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

################################################################################
# reference execution trace

REF_DIR=ref/
REF_FILE=$(REF_DIR)/$(FUNCTEST).txt
MOS6502_TRACE=$(SUBMODULES)/mos6502-trace/trace.exe

ref: $(REF_FILE)

$(REF_FILE): $(FUNCTEST_BIN) | $(REF_DIR)
	$(MOS6502_TRACE) $< 0400 FD 34 > $@

$(REF_DIR):
	mkdir $(REF_DIR)

################################################################################
# simulation

VHDL_STANDARD=2008
VHDL_RELAXED=TRUE
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

include $(MULTISIM_MK)/multisim_pre.mk

SRC=$(REPO_ROOT)/src
$(eval $(call UNIT, T65_Pack     , $(SUBMODULES)/T65/T65_Pack.vhd               ,          ))
$(eval $(call UNIT, T65_MCode    , $(SUBMODULES)/T65/T65_MCode.vhd              , T65_Pack ))
$(eval $(call UNIT, T65_ALU      , $(SUBMODULES)/T65/T65_ALU.vhd                , T65_Pack ))
$(eval $(call UNIT, T65          , $(SUBMODULES)/T65/T65.vhd                    , T65_Pack ))
$(eval $(call UNIT, T65_functest , $(SRC)/designs/T65_functest/T65_functest.vhd , T65_Pack ))

include $(MULTISIM_MK)/multisim_post.mk

run: $(FUNCTEST_BIN) $(REF_FILE) $(RUN_DEP) 
	$(call RUN_CMD,bin_file=$(FUNCTEST_BIN);ref_file=$(REF_FILE);start_address=1024)

################################################################################
# cleanup

clean::
	rm -rf $(BUILD_6502_DIR)
	rm -rf $(REF_DIR)
