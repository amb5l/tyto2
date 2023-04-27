set REPO_ROOT [exec git rev-parse --show-toplevel]
set OsvvmLibraries $REPO_ROOT/submodules/OsvvmLibraries
if {$argc < 1} {
	throw {UNSPECIFIED {simulator is unspecified}} {simulator not specified (ghdl,nvc,vsim,xsim)}
}
set simulator [lindex $argv 0]
if {$simulator == "ghdl"} {
	source $OsvvmLibraries/Scripts/StartGHDL.tcl
} elseif {$simulator == "nvc"} {
	source $OsvvmLibraries/Scripts/StartNVC.tcl
} elseif {$simulator == "vsim"} {
	source $OsvvmLibraries/Scripts/StartUp.tcl
} elseif {$simulator == "xsim"} {
	source $OsvvmLibraries/Scripts/StartXSIM.tcl
} else {
	throw {UNSUPPORTED {simulator is unsupported}} {simulator not supported - must be one of ghdl,nvc,vsim,xsim}
}
