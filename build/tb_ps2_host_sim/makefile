all: run

REPO_ROOT=$(shell git rev-parse --show-toplevel)
SRC=$(REPO_ROOT)/src

# Questa/Modelsim executables and options
SIM_WORK=work
VCOM=vcom
VCOMOPTS=-work $(SIM_WORK) -2008 -explicit -vopt -stats=none
VCOM_LOG_EXT=vcom.log
VSIM=vsim
VSIMOPTS=-t ps -c -onfinish stop -do "set NumericStdNoWarnings 1; onfinish exit; run -all"

# runtime rule/recipe for analysis dependancies
define RR_DEP
SIM_TOP=$(strip $(1))
VCOM_LOG=$(VCOM_LOG) $(strip $(1)).$(VCOM_LOG_EXT)
$(strip $(1)).$(VCOM_LOG_EXT): $(2)
	$(VCOM) $(VCOMOPTS) $$< >$(strip $(1)).$(VCOM_LOG_EXT)
endef

# design unit dependancies are declared here
$(eval $(call RR_DEP, tyto_types_pkg , $(SRC)/common/tyto_types_pkg.vhd ))
$(eval $(call RR_DEP, tyto_sim_pkg	 , $(SRC)/common/tyto_sim_pkg.vhd tyto_types_pkg.$(VCOM_LOG_EXT) ))
$(eval $(call RR_DEP, ps2_host		 , $(SRC)/common/ps2/ps2_host.vhd ))
$(eval $(call RR_DEP, tb_ps2_host	 , $(SRC)/common/ps2/tb_ps2_host.vhd ps2_host.$(VCOM_LOG_EXT) tyto_sim_pkg.$(VCOM_LOG_EXT) ))

# fixed rules and recipes follow

run: $(VCOM_LOG)
	$(VSIM) $(VSIMOPTS) $(SIM_TOP)

clean:
	rm -f $(GHDL_EXE) *.cf *.o *.lst
