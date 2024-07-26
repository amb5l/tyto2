DESIGN=bpp
RAM_SIZE=256
BOARD=qmtech_wukong
VIVADO_PART=xc7a100tfgg676-1
VENDOR=xilinx
FAMILY=7series

REPO_ROOT=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
MAKE_DIR=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SRC=$(REPO_ROOT)/src
SUBMODULES=$(REPO_ROOT)/submodules
XILINX_MK=$(SUBMODULES)/xilinx-mk

RAM_SIZE_LOG2=$(shell awk 'BEGIN{print 10+log($(RAM_SIZE))/log(2)}')
BUILD_VHDL_DIR=vhdl
PYTHON=python
DECODER_PY=$(SRC)/common/retro/np65/$(VENDOR)/np65_decoder.py
DECODER_CSV=$(SRC)/common/retro/np65/6502.csv
DECODER_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np65_decoder.vhd
RAM_INIT_PY=$(SRC)/common/retro/np65/np6532_ram_init.py
RAM_INIT_VHD=$(MAKE_DIR)/$(BUILD_VHDL_DIR)/np6532_ram_init_$(RAM_SIZE)k_pkg.vhd
BUILD_6502_DIR=6502
CA65=ca65
LD65=ld65
VIDEO_BIN=$(SRC)/common/retro/saa5050/test/engtest.bin
INIT=init_test
INIT_BIN=$(BUILD_6502_DIR)/$(INIT).bin
INIT_SRC=$(SRC)/designs/$(DESIGN)/6502/$(INIT).a65
INIT_CFG=$(SRC)/designs/$(DESIGN)/6502/$(INIT).cfg
TEST=test_mode7
TEST_BIN=$(BUILD_6502_DIR)/$(TEST).bin
TEST_SRC=$(SRC)/designs/$(DESIGN)/6502/$(TEST).a65
TEST_CFG=$(SRC)/designs/$(DESIGN)/6502/$(TEST).cfg

all: bit

VIVADO_PROJ=fpga
VIVADO_LANG=VHDL

VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)
VIVADO_SIM_TOP=tb_$(DESIGN)_$(BOARD)

VIVADO_DSN_VHDL=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd \
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/common/basic/$(VENDOR)/$(FAMILY)/mmcm.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/bpp_conductor.vhd \
	$(SRC)/common/retro/np65/np6532.vhd \
	$(DECODER_VHD) \
	$(SRC)/common/retro/np65/np6532_core.vhd \
	$(SRC)/common/retro/np65/np6532_ram.vhd \
	$(RAM_INIT_VHD) \
	$(SRC)/common/retro/np65/np6532_cache.vhd \
	$(SRC)/common/basic/ram_tdp_s.vhd \
	$(SRC)/common/basic/$(VENDOR)/ram_sdp_a_32.vhd \
	$(SRC)/common/basic/$(VENDOR)/ldce_bus.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_dmac.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_map.vhd \
	$(SRC)/common/retro/hd6845/hd6845.vhd \
	$(SRC)/common/retro/saa5050/saa5050d.vhd \
	$(SRC)/common/retro/saa5050/saa5050_rom_data.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_vidproc.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_sysvia.vhd \
	$(SRC)/common/retro/r6522/r6522.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_kbd_ps2.vhd \
	$(SRC)/common/ps2/ps2_host.vhd \
	$(SRC)/common/ps2/ps2_to_usbhid.vhd \
	$(SRC)/common/ps2/ps2set2_to_usbhid_pkg.vhd \
	$(SRC)/common/usb/usb_hid_codes_pkg.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_kbd_bbc_usbhid.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_kbd_bbc_pkg.vhd \
	$(SRC)/common/video/$(VENDOR)/$(FAMILY)/video_out_clock.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_hdtv_pkg.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_hdtv.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_overscan.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_genlock.vhd \
	$(SRC)/common/video/video_mode.vhd \
	$(SRC)/common/video/video_out_timing.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_upscale.vhd \
	$(SRC)/common/basic/$(VENDOR)/ram_tdp_ar.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_resample.vhd \
	$(SRC)/designs/$(DESIGN)/bpp_hdtv_pcm_to_hdmi.vhd \
	$(SRC)/common/video/vga_to_hdmi.vhd \
	$(SRC)/common/video/hdmi_tx_encoder.vhd \
	$(SRC)/common/basic/$(VENDOR)/$(FAMILY)/serialiser_10to1_selectio.vhd

VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).tcl

VIVADO_SIM_OUT=simulate.log
VIVADO_SIM_VHDL=\
	$(SRC)/designs/$(DESIGN)/$(BOARD)/tb_$(VIVADO_DSN_TOP).vhd \
	$(SRC)/designs/$(DESIGN)/test/tb_$(DESIGN).vhd \
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/basic/model_clk_src.vhd \
	$(SRC)/common/video/test/model_hdmi_decoder.vhd \
	$(SRC)/common/video/test/model_tmds_cdr_des.vhd \
	$(SRC)/common/video/test/model_vga_sink.vhd

include $(XILINX_MK)/xilinx.mk

decoder: $(DECODER_VHD)
$(DECODER_VHD): $(DECODER_CSV) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(DECODER_PY) $< $(@D)/

raminit: $(RAM_INIT_VHD)
$(RAM_INIT_VHD): $(VIDEO_BIN) $(TEST_BIN) $(INIT_BIN) | $(BUILD_VHDL_DIR)
	$(PYTHON) $(RAM_INIT_PY) $(RAM_SIZE) 7C00 $(VIDEO_BIN) C000 $(TEST_BIN) FC00 $(INIT_BIN) > $@

$(BUILD_VHDL_DIR):
	mkdir $(BUILD_VHDL_DIR)

init: $(INIT_BIN)
$(INIT_BIN): $(BUILD_6502_DIR)/$(INIT).o $(INIT_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(INIT).map -C $(INIT_CFG)

$(BUILD_6502_DIR)/$(INIT).o: $(INIT_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(INIT).lst

test: $(TEST_BIN)
$(TEST_BIN): $(BUILD_6502_DIR)/$(TEST).o $(TEST_CFG)
	$(LD65) $< -o $@ -m $(BUILD_6502_DIR)/$(TEST).map -C $(TEST_CFG)

$(BUILD_6502_DIR)/$(TEST).o: $(TEST_SRC) | $(BUILD_6502_DIR)
	$(CA65) $< -o $@ -l $(BUILD_6502_DIR)/$(TEST).lst

$(BUILD_6502_DIR):
	mkdir $(BUILD_6502_DIR)

clean::
	rm -rf $(BUILD_VHDL_DIR)
	rm -rf $(BUILD_6502_DIR)
	rm -rf .Xil
