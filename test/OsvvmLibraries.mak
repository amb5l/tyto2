ifndef REPO_ROOT
REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
endif
TEST:=$(REPO_ROOT)/TEST

include $(TEST)/osvvm.mak
include $(TEST)/osvvm_common.mak
include $(TEST)/osvvm_uart.mak
include $(TEST)/osvvm_axi4.mak
include $(TEST)/osvvm_axi4lite.mak
include $(TEST)/osvvm_axi4steam.mak
include $(TEST)/osvvm_dpram_pt.mak
include $(TEST)/osvvm_dpram.mak
include $(TEST)/osvvm_ethernet.mak
