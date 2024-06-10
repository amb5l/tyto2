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

# input reference clock
create_clock -add -name clki_100m -period 10.00 [get_ports clki_100m]

# clock renaming

create_generated_clock -name clk_200m    [get_pins U_MMCM/MMCM/CLKOUT0]
create_generated_clock -name clk_125m_0  [get_pins U_MMCM/MMCM/CLKOUT1]
create_generated_clock -name clk_125m_90 [get_pins U_MMCM/MMCM/CLKOUT2]
create_generated_clock -name clk_100m    [get_pins U_MMCM/MMCM/CLKOUT3]

#################################################################################
# RGMII

set RGMII_SKEW 0.5
set rgmii_tx_pins [get_ports {eth_txctl eth_txd[*]}]
set rgmii_rx_pins [get_ports {eth_rxctl eth_rxd[*]}]

create_clock -add -name phy_rx_clk -period 8.00
create_clock -add -name rgmii_rx_clk -period 8.00 [get_ports eth_rxck]

set dsn_gen [get_property generic [get_filesets sources_1]]
if {"RGMII_ALIGN=\"EDGE\"" in $dsn_gen} {

    # edge aligned

    set_output_delay -max -$RGMII_SKEW -clock [get_clocks umi_tx_clk] [get_ports data_out]
    set_output_delay -max -$RGMII_SKEW -clock [get_clocks umi_tx_clk] -clock_fall [get_ports data_out] -add_delay
    set_output_delay -min  $RGMII_SKEW -clock [get_clocks umi_tx_clk] [get_ports data_out*]
    set_output_delay -min  $RGMII_SKEW -clock [get_clocks umi_tx_clk] -clock_fall [get_ports data_out*] -add_delay

    set_multicycle_path 0 -rise_from [get_clocks phy_rx_clk] -rise_to [get_clocks rgmii_rx_clk]
    set_multicycle_path 0 -fall_from [get_clocks phy_rx_clk] -fall_to [get_clocks rgmii_rx_clk]

    set_false_path -setup -rise_from [get_clocks phy_rx_clk] -fall_to [get_clocks rgmii_rx_clk]
    set_false_path -hold  -rise_from [get_clocks phy_rx_clk] -rise_to [get_clocks rgmii_rx_clk]
    set_false_path -setup -fall_from [get_clocks phy_rx_clk] -rise_to [get_clocks rgmii_rx_clk]
    set_false_path -hold  -fall_from [get_clocks phy_rx_clk] -fall_to [get_clocks rgmii_rx_clk]

    set_input_delay            -clock phy_rx_clk             -min -$RGMII_SKEW $rgmii_rx_pins
    set_input_delay -add_delay -clock phy_rx_clk -clock_fall -min -$RGMII_SKEW $rgmii_rx_pins
    set_input_delay -add_delay -clock phy_rx_clk             -max  $RGMII_SKEW $rgmii_rx_pins
    set_input_delay -add_delay -clock phy_rx_clk -clock_fall -max  $RGMII_SKEW $rgmii_rx_pins

} else {

    # center aligned

}
