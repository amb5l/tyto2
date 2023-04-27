set REPO_ROOT [exec git rev-parse --show-toplevel]
source $REPO_ROOT/test/OsvvmStart.tcl

include $OsvvmLibraries/osvvm/osvvm.pro
include $OsvvmLibraries/Common/Common.pro
include $OsvvmLibraries/AXI4/AXI4.pro
