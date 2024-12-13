#################################################################################
# hdmi_tpg.mak
#################################################################################

default: bit

toplevel:=$(shell git rev-parse --show-toplevel)
make_fpga=$(toplevel)/submodules/make-fpga

FPGA_VENDOR=$(word 1,$(FPGA))
FPGA_FAMILY=$(word 2,$(FPGA))
FPGA_DEVICE=$(word 3,$(FPGA))

################################################################################
# Vivado

src=$(toplevel)/src

VIVADO_PART=$(FPGA_DEVICE)
VIVADO_LANGUAGE=VHDL
VIVADO_VHDL_LRM=2008
VIVADO_DSN_TOP=$(DESIGN)_$(BOARD)$(addprefix _,$(BOARD_VARIANT))
VIVADO_DSN_SRC=\
	$(src)/common/tyto_types_pkg.vhd \
	$(src)/common/tyto_utils_pkg.vhd \
	$(src)/common/basic/sync_reg.vhd \
	$(src)/common/video/video_mode.vhd \
	$(src)/common/video/xilinx_7series/video_out_clock.vhd \
	$(src)/common/video/video_out_timing.vhd \
	$(src)/common/video/video_out_test_pattern.vhd \
	$(src)/common/video/hdmi_tx_encoder.vhd \
	$(src)/common/video/vga_to_hdmi.vhd \
	$(src)/common/audio_io/xilinx_7series/audio_clock.vhd \
	$(src)/common/audio_io/audio_out_test_tone.vhd \
	$(src)/common/video/xilinx_7series/hdmi_tx_selectio.vhd \
	$(src)/designs/$(DESIGN)/$(DESIGN).vhd \
	$(if $(filter qmtech_wukong digilent_zybo_z7,$(BOARD)),$(src)/common/basic/$(FPGA_VENDOR)/$(FPGA_FAMILY)/mmcm.vhd) \
	$(if $(filter mega65,$(BOARD)),$(src)/contrib/mega65/keyboard.vhd) \
	$(src)/designs/$(DESIGN)/$(BOARD)/$(VIVADO_DSN_TOP).vhd
VIVADO_SIM_SRC=\
	$(src)/common/tyto_sim_pkg.vhd \
	$(src)/common/video/test/model_video_out_clock.vhd \
	$(src)/common/video/test/model_tmds_cdr_des.vhd \
	$(src)/common/video/test/model_hdmi_decoder.vhd \
	$(src)/common/video/test/model_vga_sink.vhd \
	$(src)/designs/$(DESIGN)/$(BOARD)/tb_$(VIVADO_DSN_TOP).vhd
VIVADO_SIM_RUN=sim=tb_$(VIVADO_DSN_TOP)
VIVADO_XDC=\
	$(src)/boards/$(BOARD)/$(BOARD)_$(BOARD_VARIANT).tcl=IMPL \
	$(src)/designs/$(DESIGN)/$(BOARD)/$(DESIGN)_$(BOARD).xdc=IMPL
VIVADO_LIB_SRC=\
	$(XILINX_VIVADO)/data/vhdl/src/unisims/unisim_retarget_VCOMP.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd=unisim \
	$(XILINX_VIVADO)/data/vhdl/src/unisims/primitive/BUFG.vhd=unisim

include $(make_fpga)/vivado.mak

################################################################################
# NVC

NVC_LRM=2008
NVC_SRC=\
	$(VIVADO_DSN_SRC) \
	$(VIVADO_SIM_SRC) \
	$(src)/common/basic/xilinx_7series/model_secureip.vhd \
	$(src)/designs/$(DESIGN)/$(BOARD)/cfg_$(VIVADO_SIM_TOP)_n.vhd
NVC_RUN=sim=cfg_$(VIVADO_SIM_TOP)

include $(make_fpga)/nvc.mak

################################################################################
# GHDL

GHDL_LRM=$(NVC_LRM)
GHDL_SRC=$(NVC_SRC)
GHDL_RUN=$(NVC_RUN)
GHDL_LIB=xilinx-vivado

include $(make_fpga)/ghdl.mak

################################################################################
# ModelSim, Questa etc

VSIM_VHDL_LRM=$(NVC_LRM)
VSIM_SRC=$(NVC_SRC)
VSIM_RUN=$(NVC_RUN)
VSIM_LIB=xilinx-vivado

include $(make_fpga)/vsim.mak

################################################################################
# post simulation check

sim:: $(wildcard $(src)/designs/$(DESIGN)/test/*.sha256)
	cd $(SIM_DIR) && sha256sum --check $^

################################################################################
