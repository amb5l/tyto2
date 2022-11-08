# mb_cb_ps2.mak

SRC:=$(REPO_ROOT)/src

DSN_TOP:=$(DESIGN)_$(BOARD)
DSN_SRC:=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/common/basic/$(VENDOR)_$(FAMILY)/ram_tdp_ar_2kx32_4kx16.vhd \
	$(SRC)/common/ps2/ps2_host.vhd \
	$(SRC)/common/ps2/ps2_to_usbhid.vhd \
	$(SRC)/common/ps2/ps2set2_to_usbhid_pkg.vhd \
	$(SRC)/common/usb/usb_hid_codes_pkg.vhd \
	$(SRC)/common/video_out/char_rom_437_8x16.vhd \
	$(SRC)/common/video_out/video_out_timing.vhd \
	$(SRC)/common/video_out/vga_to_hdmi.vhd \
	$(SRC)/common/video_out/hdmi_tx_encoder.vhd \
	$(SRC)/common/basic/$(VENDOR)_$(FAMILY)/mmcm.vhd \
	$(SRC)/common/basic/$(VENDOR)_$(FAMILY)/serialiser_10to1_selectio.vhd \
	$(SRC)/designs/mb_cb/cb.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).vhd

SIMULATORS=vivado xsim
SIM_TOP:=tb_$(DSN_TOP)
SIM_SRC:=\
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/video_out/model_dvi_decoder.vhd \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd \
	$(SRC)/designs/$(DESIGN)/tb_$(DESIGN).vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/tb_$(DSN_TOP).vhd

VIVADO_PART:=$(PART)
VIVADO_PROJ=fpga
VIVADO_LANG=VHDL
VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)
VIVADO_SIM_TOP=tb_$(DESIGN)_$(BOARD)
VIVADO_DSN_VHDL=$(DSN_SRC)
VIVADO_DSN_BD_TCL=$(SRC)/designs/mb_cb/microblaze.tcl
VIVADO_DSN_XDC_IMPL=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).tcl
VIVADO_DSN_PROC_INST=cpu
VIVADO_DSN_PROC_REF=microblaze
VIVADO_DSN_ELF_CFG=Release
VIVADO_SIM_VHDL=$(SIM_SRC)
VIVADO_SIM_ELF_CFG=Debug

VITIS_APP=microblaze
VITIS_SRC=\
	$(SRC)/designs/$(DESIGN)/microblaze/main.c \
	$(SRC)/common/basic/microblaze/peekpoke.h \
	$(SRC)/common/basic/microblaze/axi_gpio_p.h \
	$(SRC)/common/basic/microblaze/axi_gpio.h \
	$(SRC)/common/basic/microblaze/axi_gpio.c \
	$(SRC)/common/video_out/microblaze/cb.h \
	$(SRC)/common/video_out/microblaze/cb.c \
	$(SRC)/common/basic/microblaze/printf.h \
	$(SRC)/common/basic/microblaze/printf.c
VITIS_INCLUDE=\
	$(SRC)/designs/$(DESIGN)/microblaze \
	$(SRC)/common/basic/microblaze \
	$(SRC)/common/video_out/microblaze

V4P_XSRC=\
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/RAMB36E1.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/OBUFDS.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/secureip/OSERDESE2.vhd
