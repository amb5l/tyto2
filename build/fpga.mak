# fpga.mak

TARGET:=$(word 1,$(MAKECMDGOALS))
ifneq ($(words $(MAKECMDGOALS)),1)
ifneq ($(words $(MAKECMDGOALS)),0)
$(error More than one target specified.)
else
TARGET:=all
endif
endif
REPO_ROOT:=$(shell cygpath -m $(shell git rev-parse --show-toplevel))
MAKE_DIR:=$(REPO_ROOT)/$(shell git rev-parse --show-prefix)
SUBMODULES:=$(REPO_ROOT)/submodules

ifeq ($(BOARD),)
$(error BOARD not specified.)
endif
ifeq ($(DEVICE),)
$(error DEVICE not specified.)
endif

VENDOR:=$(word 1,$(DEVICE))
FAMILY:=$(word 2,$(DEVICE))
PART:=$(word 3,$(DEVICE))

# vendor specific checks and default target

ifeq ($(VENDOR),xilinx)
ifeq ($(XILINX_VIVADO),)
$(error XILINX_VIVADO not defined)
endif
XILINX_VIVADO:=$(shell cygpath -m $(XILINX_VIVADO))
all: bit
else ifeq ($(VENDOR),intel)
ifeq ($(QUARTUS_ROOTDIR),)
$(error QUARTUS_ROOTDIR not defined)
endif
QUARTUS_ROOTDIR:=$(shell cygpath -m $(QUARTUS_ROOTDIR))
all: sof
else
$(error VENDOR not supported: $(VENDOR))
endif

# design specific makefile(s)

include $(REPO_ROOT)/build/$(DESIGN)/$(DESIGN).mak

# targets

ifeq ($(TARGET),clean)

# cleanup

clean::
	find . -not \( -name 'makefile' -or -name '.gitignore' -or -name '*.bit' -or -name '*.sof' \) -type f -exec rm -f {} +
	find . -not \( -name '.' -or -name '..' \) -type d -exec rm -rf {} +

else ifneq ($(filter $(SIMULATORS),$(TARGET)),)

# simulator targets

include $(SUBMODULES)/multisim-mk

else ifneq ($(filter vscode,$(TARGET)),)

# Visual Studio Code (including support for V4P extension)
# NOTE: requires Windows 10/11 developer mode for mklink to work

VSCODE=code
VSCODE_DIR=.vscode
$(VSCODE_DIR):
	mkdir $(VSCODE_DIR)
V4P_SRC:=$(foreach X,$(V4P_XSRC),$(word 2,$(subst ;, ,$X)))
VSCODE_SRC=$(DSN_SRC) $(SIM_SRC) $(V4P_SRC)
VSCODE_SYMLINKS=$(addprefix $(VSCODE_DIR)/,$(notdir $(VSCODE_SRC)))
define RR_VSCODE_SYMLINK
ifeq ($(OS),Windows_NT)
$(VSCODE_DIR)/$(notdir $1): $1 | $(VSCODE_DIR)
	cmd.exe /C "mklink $$(shell cygpath -w $$@) $$(shell cygpath -w $$<)"
else
$(VSCODE_DIR)/$(notdir $1): $1
	ln $$< $$@
endif
endef
$(foreach S,$(VSCODE_SRC),$(eval $(call RR_VSCODE_SYMLINK,$S)))
CONFIG_V4P_FILE=$(VSCODE_DIR)/config.v4p
CONFIG_V4P_LINES= \
	[libraries] \
	$(foreach X,$(V4P_XSRC),$(notdir $(word 2,$(subst ;, ,$X)))=$(word 1,$(subst ;, ,$X))) *.vhd=work \
	[settings] \
	V4p.Settings.Basics.TopLevelEntities=$(DSN_TOP),$(SIM_TOP)
FORCE:
$(CONFIG_V4P_FILE): FORCE
	l=( $(CONFIG_V4P_LINES) ); printf "%s\n" "$${l[@]}" > $(CONFIG_V4P_FILE)
.PHONY: vscode
vscode: $(VSCODE_SYMLINKS) $(CONFIG_V4P_FILE) | $(VSCODE_DIR)
	$(VSCODE) $(VSCODE_DIR)

# vendor specific FPGA tool

else ifeq ($(VENDOR),xilinx)
XILINX_MK:=$(SUBMODULES)/xilinx-mk
include $(XILINX_MK)/xilinx.mk
else ifeq ($(VENDOR),intel)
QUARTUS_MK:=$(SUBMODULES)/quartus-mk
include $(QUARTUS_MK)/quartus.mk

endif
