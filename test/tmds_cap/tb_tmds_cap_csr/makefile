# makefile for tb_tmds_cap_csr

REPO_ROOT:=$(shell git rev-parse --show-toplevel)
ifeq ($(OS),Windows_NT)
REPO_ROOT:=$(shell cygpath -m $(REPO_ROOT))
endif
SRC:=$(REPO_ROOT)/src

# build OSVVM libraries if required

init: .init

.init:
	tclsh $(SRC)/designs/tmds_cap/test/tmds_cap_csr/init.pro nvc
	touch $@


ghdl nvc vsim xsim:
	tclsh $(SRC)/designs/tmds_cap/test/tmds_cap_csr/run.pro $(MAKECMDGOALS)

run: .init
	tclsh $(SRC)/designs/tmds_cap/test/tmds_cap_csr/run.pro nvc
