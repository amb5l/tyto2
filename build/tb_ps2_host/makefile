# makefile for tb_ps2_host

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SUBMODULES=$(REPO_ROOT)/submodules
MULTISIM_MK=$(SUBMODULES)/multisim-mk

VHDL_STANDARD=2008
VHDL_RELAXED=TRUE
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

include $(MULTISIM_MK)/multisim_pre.mk

SRC=$(REPO_ROOT)/src
$(eval $(call UNIT, tyto_types_pkg , $(SRC)/common/tyto_types_pkg.vhd  ,                       ))
$(eval $(call UNIT, tyto_sim_pkg   , $(SRC)/common/tyto_sim_pkg.vhd    , tyto_types_pkg        ))
$(eval $(call UNIT, ps2_host       , $(SRC)/common/ps2/ps2_host.vhd    ,                       ))
$(eval $(call UNIT, tb_ps2_host    , $(SRC)/common/ps2/tb_ps2_host.vhd , ps2_host tyto_sim_pkg ))

include $(MULTISIM_MK)/multisim_post.mk

$(eval $(call RUN))
