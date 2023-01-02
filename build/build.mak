################################################################################
# build.mak - makefile include for FPGA builds and simulations
################################################################################
# global definitions

ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif

################################################################################
# default target

ifeq ($(FPGA_VENDOR),xilinx)
ifdef FPGA_DEVICE
all: bit
endif
else ifeq ($(FPGA_VENDOR),intel)
ifdef FPGA_DEVICE
all: sof
endif
endif
fail:
	@echo "No target specified. Supported simulators: $(SIMULATORS)"

################################################################################
# simulation targets

SIM:=$(word 1,$(filter $(SIMULATORS),$(MAKECMDGOALS)))
ifneq ($(SIM),)
ifeq ($(filter $(SIM),ghdl nvc vsim xsim),)
$(error Simulator is unsupported ($(SIM)))
endif

SIM_DIR:=.$(SIM)
# simulation compile tracking
SIM_SCT:=$(SIM_DIR)/.sct

ifeq ($(SIM_RUNS),)
ifneq ($(SIM_RUN),)
SIM_RUNS:=sim,$(SIM_RUN)
else
$(error Neither SIM_RUN not SIM_RUNS specified)
endif
endif

SIM_WORK:=work

# definitions for ghdl (GHDL)
ifeq (ghdl,$(SIM))
GHDL?=ghdl
ifndef GHDL_PREFIX
GHDL_PREFIX:=$(dir $(shell which $(GHDL)))/..
ifeq ($(OS),Windows_NT)
GHDL_PREFIX:=$(shell cygpath -m $(GHDL_PREFIX))
endif
endif
GHDL_AOPTS+=--std=08 -fsynopsys -frelaxed -Wno-hide -Wno-shared $(addprefix -P$(GHDL_PREFIX)/lib/ghdl/vendors/,$(GHDL_LIBS))
GHDL_EOPTS+=--std=08 -fsynopsys -frelaxed $(addprefix -P$(GHDL_PREFIX)/lib/ghdl/vendors/,$(GHDL_LIBS))
GHDL_ROPTS+=--unbuffered --max-stack-alloc=0 --ieee-asserts=disable
define CMD_COM
	cd $$(SIM_DIR) && \
	$$(GHDL) -a --work=$$(SIM_WORK) $$(GHDL_AOPTS) $1
endef
define CMD_SIM
	cd $$(SIM_DIR) && \
	$$(GHDL) --elab-run --work=$$(SIM_WORK) $$(GHDL_EOPTS) $$(word 2,$1) $$(GHDL_ROPTS) $$(if $$(filter vcd gtkwave,$$(MAKECMDGOALS)),--vcd=$$(word 1,$1).vcd) $$(addprefix -g,$$(subst ;, ,$$(word 3,$1)))
endef
endif

# definitions for nvc (NVC)
ifeq (nvc,$(SIM))
NVC?=nvc
NVC_GOPTS+=--std=2008
NVC_AOPTS+=--relaxed
NVC_EOPTS+=
NVC_ROPTS+=--ieee-warnings=off
define CMD_COM
	cd $$(SIM_DIR) && \
	$$(NVC) $$(NVC_GOPTS) --work=$$(SIM_WORK) -a $$(NVC_AOPTS) $1
endef
define CMD_SIM
	cd $$(SIM_DIR) && \
	$$(NVC) $$(NVC_GOPTS) --work=$$(SIM_WORK) -e $$(word 2,$1) $$(NVC_EOPTS) $$(addprefix -g,$$(subst ;, ,$$(word 3,$1))) && \
	$$(NVC) $$(NVC_GOPTS) --work=$$(SIM_WORK) -r $$(word 2,$1) $$(NVC_ROPTS) $$(if $$(filter vcd gtkwave,$$(MAKECMDGOALS)),--format=vcd --wave=$$(word 1,$1).vcd)
endef
endif

# definitions for vsim (ModelSim/Questa/etc)
ifeq (vsim,$(SIM))
VCOM?=vcom
VSIM?=vsim
ifndef VSIM_LIB_PATH
VSIM_LIB_PATH:=~/.simlib
ifeq ($(OS),Windows_NT)
VSIM_LIB_PATH:=$(shell cygpath -m $(VSIM_LIB_PATH))
endif
endif
VCOMOPTS+=-2008 -explicit -vopt -stats=none
VSIMTCL+=set NumericStdNoWarnings 1; onfinish exit; run -all; exit
VSIMOPTS+=-t ps -c -onfinish stop -do "$(VSIMTCL)"
define CMD_COM
	cd $$(SIM_DIR) && \
	$$(VCOM) -work $$(SIM_WORK) $$(VCOMOPTS) $1
endef
define CMD_SIM
	cd $$(SIM_DIR) && \
	$$(VSIM) -work $$(SIM_WORK) $$(if $$(filter vcd gtkwave,$$(MAKECMDGOALS)),-do "vcd file $$(word 1,$1).vcd; vcd add -r *") $$(VSIMOPTS) $$(word 2,$1) $$(addprefix -g,$$(subst ;, ,$$(word 3,$1)))
endef
endif

# definitions for xsim (Vivado simulator - non project mode)
ifeq (xsim,$(SIM))
XVHDL?=xvhdl
XELAB?=xelab
XSIM?=xsim
XVHDL_OPTS+=-2008 -relax
XELAB_OPTS+=-debug typical -O2 -relax
XSIM_OPTS+=-onerror quit -onfinish quit
ifeq ($(OS),Windows_NT)
define CMD_COM
	cmd.exe /C " \
	cd $$(SIM_DIR) & \
	call $$(XVHDL).bat $$(XVHDL_OPTS) -work $$(SIM_WORK) $1 \
	"
endef
define CMD_SIM
	cd $$(SIM_DIR) && echo "open_vcd $$(word 1,$1).vcd; log_vcd /*; run all; close_vcd; quit" > $$(word 1,$1).tcl
	cmd.exe /C " \
	cd $$(SIM_DIR) & \
	call $$(XELAB).bat $$(XELAB_OPTS) -L $$(SIM_WORK) -top $$(word 2,$1) -snapshot $$(word 2,$1)_$$(word 1,$1) $$(addprefix -generic_top \",$$(addsuffix \",$$(subst ;, ,$$(word 3,$1)))) & \
	call $$(XSIM).bat $$(XSIM_OPTS) -tclbatch $$(word 1,$1).tcl $$(word 2,$1)_$$(word 1,$1) \
	"
endef
else
define CMD_COM
	cd $$(SIM_DIR) && \
	$$(XVHDL) $$(XVHDL_OPTS) -work $$(SIM_WORK) $1
endef
define CMD_SIM
	cd $$(SIM_DIR) && \
	echo "open_vcd $$(word 1,$1).vcd; log_vcd /*; run all; close_vcd; quit" > $$(word 1,$1).tcl && \
	$$(XELAB) $$(XELAB_OPTS) -L $$(SIM_WORK) -top $$(word 2,$1) -snapshot $$(word 2,$1)_$$(word 1,$1) $$(word 2,$1) $(addprefix -generic_top \",$(addsuffix \",$(subst ;, ,$$(word 3,$1)))) && \
	$$(XSIM) $$(XSIM_OPTS) -tclbatch $$(word 1,$1).tcl $$(word 2,$1)_$$(word 1,$1)
endef
endif
endif

# rules and recipes
.PHONY: sim $(SIM)
$(SIM): sim
$(SIM_DIR):
	mkdir -p $(SIM_DIR)
define RR_COM
$(SIM_SCT):: $1 | $(SIM_DIR)
	$(call CMD_COM,$$<)
	touch $(SIM_SCT)
endef
$(foreach s,$(SIM_SRC),$(eval $(call RR_COM,$s)))
define RR_SIM
sim :: $(SIM_SCT) | $(SIM_DIR)
	@bash -c "echo --------------------------------------------------------------------------------"
	@bash -c "echo SIMULATION RUN: $(word 1,$1)   START: $$$$(date)"
	@bash -c "echo --------------------------------------------------------------------------------"
	$(call CMD_SIM,$1)
	@bash -c "echo --------------------------------------------------------------------------------"
	@bash -c "echo SIMULATION RUN: $(word 1,$1)   END: $$$$(date)"
	@bash -c "echo --------------------------------------------------------------------------------"
$(SIM_DIR)/$(word 1,$1).vcd: sim
vcd:: $(SIM_DIR)/$(word 1,$1).vcd
$(SIM_DIR)/$(word 1,$1).gtkw: $(SIM_DIR)/$(word 1,$1).vcd
	sh $(REPO_ROOT)/submodules/vcd2gtkw/vcd2gtkw.sh $(SIM_DIR)/$(word 1,$1).vcd $(SIM_DIR)/$(word 1,$1).gtkw
gtkwave:: $(SIM_DIR)/$(word 1,$1).vcd $(SIM_DIR)/$(word 1,$1).gtkw
ifeq ($(OS),Windows_NT)
	cmd.exe /C "start cmd.exe /C \"gtkwave $(SIM_DIR)/$(word 1,$1).vcd $(SIM_DIR)/$(word 1,$1).gtkw\""
else
	gtkwave $(SIM_DIR)/$(word 1,$1).vcd $(SIM_DIR)/$(word 1,$1).gtkw &
endif
endef
comma:=,
$(foreach r,$(SIM_RUNS),$(eval $(call RR_SIM,$(subst $(comma), ,$r))))

################################################################################
# Visual Studio Code (including support for V4P extension)
# NOTE: requires Windows 10/11 developer mode for mklink to work

else ifneq ($(filter vscode,$(MAKECMDGOALS)),)

VSCODE:=code
VSCODE_DIR:=.vscode
$(VSCODE_DIR):
	mkdir $(VSCODE_DIR)
VSCODE_SRC+=$(foreach x,$(V4P_LIB_SRC),$(word 2,$(subst ;, ,$x)))
VSCODE_SYMLINKS:=$(addprefix $(VSCODE_DIR)/,$(notdir $(VSCODE_SRC)))
define RR_VSCODE_SYMLINK
ifeq ($(OS),Windows_NT)
$(VSCODE_DIR)/$(notdir $1): $1 | $(VSCODE_DIR)
	cmd.exe /C "rm -f  $$(shell cygpath -w $$@) & mklink $$(shell cygpath -w $$@) $$(shell cygpath -w -a $$<)"
else
$(VSCODE_DIR)/$(notdir $1): $1
	ln $$< $$@
endif
endef
$(foreach s,$(VSCODE_SRC),$(eval $(call RR_VSCODE_SYMLINK,$s)))
CONFIG_V4P_FILE:=$(VSCODE_DIR)/config.v4p
CONFIG_V4P_LINES:= \
	[libraries] \
	$(foreach x,$(V4P_LIB_SRC),$(notdir $(word 2,$(subst ;, ,$x)))=$(word 1,$(subst ;, ,$x))) \
	*.vhd=work \
	*.vhdl=work \
	*.vho=work \
	[settings] \
	V4p.Settings.Basics.TopLevelEntities=$(V4P_TOP)
FORCE:
$(CONFIG_V4P_FILE): FORCE
	l=( $(CONFIG_V4P_LINES) ); printf "%s\n" "$${l[@]}" > $(CONFIG_V4P_FILE)
.PHONY: vscode
vscode: $(VSCODE_SYMLINKS) $(CONFIG_V4P_FILE) | $(VSCODE_DIR)
	$(VSCODE) $(VSCODE_DIR)

################################################################################
# cleanup

else ifneq ($(filter clean,$(MAKECMDGOALS)),)

.PHONY: clean
clean:
	@find . -not \( -name 'makefile' -or -name '.gitignore' -or -name '*.bit' -or -name '*.sof' \) -type f -exec rm -f {} +
	@find . -not \( -name '.' -or -name '..' \) -type d -exec rm -rf {} +

################################################################################
# FPGA build tools

else ifeq ($(FPGA_VENDOR),xilinx)

ifdef FPGA_DEVICE
XILINX_MK?=$(REPO_ROOT)/submodules/xilinx-mk
include $(XILINX_MK)/xilinx.mk
endif
else ifeq ($(FPGA_VENDOR),intel)

ifdef FPGA_DEVICE
QUARTUS_MK?=$(REPO_ROOT)/submodules/quartus-mk
include $(QUARTUS_MK)/quartus.mk
endif

endif
