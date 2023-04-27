set REPO_ROOT [exec cygpath -m [exec git rev-parse --show-toplevel]]
set SRC $REPO_ROOT/src
set HERE [exec cygpath -m [file dirname [info script]]]

source $REPO_ROOT/test/OsvvmStart.tcl

#TestSuite tb_tmds_cap_csr
library tb_tmds_cap_csr
analyze $HERE/OsvvmTestCommonPkg.vhd
analyze $HERE/TestCtrl_e.vhd
analyze $SRC/common/tyto_types_pkg.vhd
analyze $SRC/common/axi/axi_pkg.vhd
analyze $SRC/common/video/xilinx_7series/hdmi_rx_selectio_fm.vhd
analyze $SRC/common/video/xilinx_7series/hdmi_rx_selectio_clk.vhd
analyze $SRC/common/video/xilinx_7series/hdmi_rx_selectio_align.vhd
analyze $SRC/common/video/xilinx_7series/hdmi_rx_selectio.vhd
analyze $SRC/designs/tmds_cap/tmds_cap_csr.vhd
analyze $HERE/tb_tmds_cap_csr.vhd
RunTest $HERE/tb_tmds_cap_csr_test1.vhd
