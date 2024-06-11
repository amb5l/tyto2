################################################################################
## mbv_mcs_memac_digilent_nexys_video.tcl                                     ##
## Board specific constraints for the mbv_mcs_memac design.                   ##
################################################################################
## (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        ##
## This file is part of The Tyto Project. The Tyto Project is free software:  ##
## you can redistribute it and/or modify it under the terms of the GNU Lesser ##
## General Public License as published by the Free Software Foundation,       ##
## either version 3 of the License, or (at your option) any later version.    ##
## The Tyto Project is distributed in the hope that it will be useful, but    ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     ##
## License for more details. You should have received a copy of the GNU       ##
## Lesser General Public License along with The Tyto Project. If not, see     ##
## https://www.gnu.org/licenses/.                                             ##
################################################################################

set_msg_config -id {Common 17-1548} -new_severity {ERROR}

set script_file_tail [file tail [file normalize [info script]]]
set script_file_root [file rootname $script_file_tail]

set rgmii_ports_tx_clk [get_ports eth_txck]
set rgmii_ports_tx_out [get_port {eth_txctl eth_txd[*]}]
set rgmii_ports_rx_clk [get_port {eth_rxck}]
set rgmii_ports_rx_in  [get_port {eth_rxctl eth_rxd[*]}]

set dsn_gen [get_property -quiet generic [get_filesets sources_1]]
if {[llength $dsn_gen]} {

    #################################################################################
    # synthesis specific

    # get required design generics
    foreach c {RGMII_TX_ALIGN RGMII_RX_ALIGN} {
        set found 0
        foreach g $dsn_gen {
            if {[string match "$c=*" $g]} {
                set $c [lindex [split $g "="] 1]
                set found 1
            }
        }
        if {!$found} {
            error "$c not found in design generics ($dsn_gen)"
        }
    }

    # set associated properties
    create_property -quiet USER_ALIGN port
    set_property USER_ALIGN $RGMII_TX_ALIGN $rgmii_ports_tx_clk
    set_property USER_ALIGN $RGMII_RX_ALIGN $rgmii_ports_rx_clk

    #################################################################################

} else {

    #################################################################################
    # implememtation specific

    # clocks

    create_clock -add -name clki_100m -period 10.00 [get_ports clki_100m]
    set clk_100m [get_clocks clki_100m]
    create_generated_clock -name clk_200m    [get_pins U_MMCM/MMCM/CLKOUT0]
    set clk_200m [get_clocks clk_200m]
    create_generated_clock -name clk_125m_0  [get_pins U_MMCM/MMCM/CLKOUT1]
    set clk_125m_0 [get_clocks clk_125m_0]
    create_generated_clock -name clk_125m_90 [get_pins U_MMCM/MMCM/CLKOUT2]
    set clk_125m_90 [get_clocks clk_125m_90]
    create_generated_clock -name clk_100m    [get_pins U_MMCM/MMCM/CLKOUT3]
    set clk_100m [get_clocks clk_100m]

    # RGMII

    set rgmii_tx_clk_src   [get_pins U_RGMII_TX/GEN_ALIGN.U_ODDR_CLK/GEN[0].U_ODDR/C]
    set rgmii_gtx_clk      [get_clocks clk_125m_0]
    set RGMII_TX_ALIGN     [get_property USER_ALIGN $rgmii_ports_tx_clk]
    set RGMII_RX_ALIGN     [get_property USER_ALIGN $rgmii_ports_rx_clk]
    source [get_files "memac_tx_rgmii.tcl"]
    source [get_files "memac_rx_rgmii.tcl"]

    # false paths

    set_false_path      -from $clk_100m           -to $clk_125m_0
    set_false_path      -from $clk_125m_0         -to $clk_100m
    set_false_path      -from $clk_100m           -to $rgmii_rx_rclk
    set_false_path      -from $rgmii_rx_rclk      -to $clk_100m
    set_false_path      -from $rgmii_rx_rclk      -to $clk_125m_0
    set_false_path -rise_from $rgmii_rx_rclk -fall_to $rgmii_rx_rclk
    set_false_path -fall_from $rgmii_rx_rclk -rise_to $rgmii_rx_rclk

    #################################################################################

}
