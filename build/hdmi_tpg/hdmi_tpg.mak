# hdmi_tpg.mak

ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

FPGA_VENDOR:=$(word 1,$(FPGA))
FPGA_FAMILY:=$(word 2,$(FPGA))
FPGA_DEVICE:=$(word 3,$(FPGA))

SRC:=$(REPO_ROOT)/src

ifeq ($(FPGA_VENDOR),xilinx)

VIVADO_PART:=$(FPGA_DEVICE)
VIVADO_PROJ:=fpga
VIVADO_LANG:=VHDL
VIVADO_DSN_TOP:=$(DESIGN)_$(BOARD)
VIVADO_DSN_VHDL:=\
	$(SRC)/common/tyto_types_pkg.vhd \
	$(SRC)/common/tyto_utils_pkg.vhd \
	$(SRC)/common/basic/sync_reg.vhd \
	$(SRC)/common/video_out/video_mode.vhd \
	$(SRC)/common/video_out/xilinx_7series/video_out_clock.vhd \
	$(SRC)/common/video_out/video_out_timing.vhd \
	$(SRC)/common/video_out/video_out_test_pattern.vhd \
	$(SRC)/common/video_out/hdmi_tx_encoder.vhd \
	$(SRC)/common/video_out/vga_to_hdmi.vhd \
	$(SRC)/common/basic/clkengen.vhd \
	$(SRC)/common/audio_io/audio_out_test_tone.vhd \
	$(SRC)/common/basic/xilinx_7series/serialiser_10to1_selectio.vhd \
	$(SRC)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(if $(filter qmtech_wukong,$(BOARD)),$(SRC)/common/basic/$(FPGA_VENDOR)_$(FPGA_FAMILY)/mmcm.vhd) \
	$(if $(filter mega65r3,$(BOARD)),$(SRC)/contrib/mega65/keyboard.vhd) \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
VIVADO_DSN_XDC_IMPL:=\
	$(SRC)/boards/$(BOARD)/$(BOARD).tcl \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).xdc
VIVADO_SIM_TOP:=tb_$(VIVADO_DSN_TOP)
VIVADO_SIM_VHDL_2008:=\
	$(SRC)/common/tyto_sim_pkg.vhd \
	$(SRC)/common/video_out/model_video_out_clock.vhd \
	$(SRC)/common/video_out/model_tmds_cdr_des.vhd \
	$(SRC)/common/video_out/model_hdmi_decoder.vhd \
	$(SRC)/common/video_out/model_vga_sink.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_SIM_TOP).vhd

SIMULATORS:=ghdl nvc vsim xsim
SIM_TOP:=$(VIVADO_SIM_TOP)
SIM_SRC:=$(VIVADO_DSN_VHDL) $(VIVADO_SIM_VHDL_2008)
NO_SECURE_IP:=ghdl nvc vsim
ifneq ($(filter $(NO_SECURE_IP),$(MAKECMDGOALS)),)
SIM_SRC+=\
	$(SRC)/common/basic/xilinx_7series/model_secureip.vhd \
	$(SRC)/designs/$(DESIGN)/$(BOARD)/cfg_$(VIVADO_SIM_TOP)_n.vhd
SIM_TOP:=cfg_$(VIVADO_SIM_TOP)
endif
GHDL_LIBS:=xilinx-vivado
NVC_GOPTS:=-H 32m

VSCODE_SRC:=$(VIVADO_DSN_VHDL) $(VIVADO_SIM_VHDL_2008)
V4P_TOP:=$(VIVADO_DSN_TOP),$(VIVADO_SIM_TOP)
V4P_LIB_SRC:=\
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd \
	unisim;$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd

endif

SIM_RUN:=$(SIM_TOP)
#SIM_RUN:=$(SIM_TOP),path_basename=$(shell cygpath -m -a $(SIM_DIR))/$(SIM_TOP)

include $(REPO_ROOT)/build/build.mak

sim:: $(wildcard $(SRC)/designs/$(DESIGN)/test/*.sha256)
	cd $(SIM_DIR) && sha256sum --check $^
