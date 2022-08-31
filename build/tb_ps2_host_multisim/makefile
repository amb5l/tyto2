################################################################################
# makefile for tb_ps2_host_multisim                                            #
# See https://github.com/amb5l/multisim-mk                                     #
################################################################################

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SUBMODULES=$(REPO_ROOT)/submodules
MULTISIM_MK=$(SUBMODULES)/multisim-mk

################################################################################
# preferences

# VHDL language standard: 1993 or 2008
VHDL_STANDARD=2008

# VHDL relaxed rules e.g. allow impure behaviour in pure functions
# comment out if not required
VHDL_RELAXED=TRUE

# suppress warnings from IEEE library units e.g. to_integer metavalues
# comment out if not required
VHDL_SUPPRESS_IEEE_ASSERTS=TRUE

################################################################################

# place before design unit declarations
include $(MULTISIM_MK)/multisim_pre.mk

################################################################################
# design units and their dependancies are declared here as follows:
# $(eval $(call UNIT, unit_name, source_file, dependencies ))
#
# where
#   unit_name = design unit (entity or package name)
#   source_file = VHDL source file
#   dependancies = whitespace separated list of design units (or empty)
#
# ensure units appear in the correct compilation order

# example:

SRC=$(REPO_ROOT)/src

$(eval $(call UNIT, tyto_types_pkg , $(SRC)/common/tyto_types_pkg.vhd  ,                       ))
$(eval $(call UNIT, tyto_sim_pkg   , $(SRC)/common/tyto_sim_pkg.vhd    , tyto_types_pkg        ))
$(eval $(call UNIT, ps2_host       , $(SRC)/common/ps2/ps2_host.vhd    ,                       ))
$(eval $(call UNIT, tb_ps2_host    , $(SRC)/common/ps2/tb_ps2_host.vhd , ps2_host tyto_sim_pkg ))

################################################################################

# place after design unit declarations
include $(MULTISIM_MK)/multisim_post.mk

################################################################################
# end of file