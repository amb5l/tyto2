# hdmi_tpg.mak

SRC:=$(REPO_ROOT)/src

DSN_TOP:=$(DESIGN)_$(BOARD)
DSN_SRC:=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/common/video_out/video_mode.vhd \
	$(SRC)/common/video_out/xilinx_7series/video_out_clock.vhd \
	$(SRC)/common/video_out/video_out_timing.vhd \
	$(SRC)/common/video_out/video_out_test_pattern.vhd \
	$(SRC)/common/video_out/vga_to_hdmi.vhd \
	$(SRC)/common/video_out/hdmi_tx_encoder.vhd \
	$(SRC)/common/audio_io/xilinx_7series/audio_clock.vhd \
	$(SRC)/common/audio_io/audio_out_test_tone.vhd \
	$(SRC)/common/basic/xilinx_7series/serialiser_10to1_selectio.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(SRC)/common/basic/$(VENDOR)_$(FAMILY)/mmcm.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).vhd

SIMULATORS:=vivado xsim ghdl nvc vsim
NO_SECURE_IP:=ghdl nvc vsim
ifneq ($(filter $(TARGET),$(NO_SECURE_IP)),)
SIM_TOP:=cfg_tb_hdmi_tpg_no_secure_ip
SIM_SRC:=$(SRC)/common/basic/xilinx_7series/model_secureip.vhd
else
SIM_TOP:=cfg_tb_hdmi_tpg_secure_ip
SIM_SRC:=
endif
SIM_SRC:=$(SIM_SRC)\
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/video_out/model_video_out_clock.vhd \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd \
	$(SRC)/common/video_out/model_hdmi_decoder.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/tb_$(DSN_TOP).vhd

VIVADO_PART:=$(PART)
VIVADO_PROJ:=fpga
VIVADO_LANG:=VHDL
VIVADO_DSN_TOP:=$(DSN_TOP)
VIVADO_SIM_TOP:=$(SIM_TOP)
VIVADO_DSN_VHDL:=$(DSN_SRC)
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(DSN_TOP).xdc
VIVADO_SIM_VHDL:=$(SIM_SRC)
