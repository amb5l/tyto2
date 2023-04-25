################################################################################
## digilent_zybo_z7_20.tcl                                                    ##
## Physical constraints for the Digilent Zybo Z7-20 board.                    ##
################################################################################
## (C) Copyright 2023 Michael Jørgensen <michael.finn.jorgensen@gmail.com>    ##
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

create_clock -add -name clki_125m -period 8.00 -waveform {0 4} [get_ports clki_125m]

set pins {
    { clki_125m            K17  LVCMOS33              }
    { sw[0]                G15  LVCMOS33              }
    { sw[1]                P15  LVCMOS33              }
    { sw[2]                W13  LVCMOS33              }
    { sw[3]                T16  LVCMOS33              }
    { btn[0]               K18  LVCMOS33              }
    { btn[1]               P16  LVCMOS33              }
    { btn[2]               K19  LVCMOS33              }
    { btn[3]               Y16  LVCMOS33              }
    { led[0]               M14  LVCMOS33              }
    { led[1]               M15  LVCMOS33              }
    { led[2]               G14  LVCMOS33              }
    { led[3]               D18  LVCMOS33              }
    { led_r[5]             Y11  LVCMOS33              }
    { led_g[5]             T5   LVCMOS33              }
    { led_b[5]             Y12  LVCMOS33              }
    { led_r[6]             V16  LVCMOS33              }
    { led_g[6]             F17  LVCMOS33              }
    { led_b[6]             M17  LVCMOS33              }
    { ac_bclk              R19  LVCMOS33              }
    { ac_mclk              R17  LVCMOS33              }
    { ac_muten             P18  LVCMOS33              }
    { ac_pbdat             R18  LVCMOS33              }
    { ac_pblrc             T19  LVCMOS33              }
    { ac_recdat            R16  LVCMOS33              }
    { ac_reclrc            Y18  LVCMOS33              }
    { ac_scl               N18  LVCMOS33              }
    { ac_sda               N17  LVCMOS33              }
    { eth_int_pu_b         F16  LVCMOS33  PULLUP true }
    { eth_rst_b            E17  LVCMOS33              }
    { fan_fb_pu            Y13  LVCMOS33  PULLUP true }
    { hdmi_rx_hpd          W19  LVCMOS33              }
    { hdmi_rx_scl          W18  LVCMOS33              }
    { hdmi_rx_sda          Y19  LVCMOS33              }
    { hdmi_rx_clk_p        U18  TMDS_33               }
    { hdmi_rx_clk_n        U19  TMDS_33               }
    { hdmi_rx_d_p[0]       V20  TMDS_33               }
    { hdmi_rx_d_n[0]       W20  TMDS_33               }
    { hdmi_rx_d_p[1]       T20  TMDS_33               }
    { hdmi_rx_d_n[1]       U20  TMDS_33               }
    { hdmi_rx_d_p[2]       N20  TMDS_33               }
    { hdmi_rx_d_n[2]       P20  TMDS_33               }
    { hdmi_rx_cec          Y8   LVCMOS33              }
    { hdmi_tx_hpd          E18  LVCMOS33              }
    { hdmi_tx_scl          G17  LVCMOS33              }
    { hdmi_tx_sda          G18  LVCMOS33              }
    { hdmi_tx_clk_p        H16  TMDS_33               }
    { hdmi_tx_clk_n        H17  TMDS_33               }
    { hdmi_tx_d_p[0]       D19  TMDS_33               }
    { hdmi_tx_d_n[0]       D20  TMDS_33               }
    { hdmi_tx_d_p[1]       C20  TMDS_33               }
    { hdmi_tx_d_n[1]       B20  TMDS_33               }
    { hdmi_tx_d_p[2]       B19  TMDS_33               }
    { hdmi_tx_d_n[2]       A20  TMDS_33               }
    { hdmi_tx_cec          E19  LVCMOS33              }
    { ja[0]                N15  LVCMOS33              }
    { ja[1]                L14  LVCMOS33              }
    { ja[2]                K16  LVCMOS33              }
    { ja[3]                K14  LVCMOS33              }
    { ja[4]                N16  LVCMOS33              }
    { ja[5]                L15  LVCMOS33              }
    { ja[6]                J16  LVCMOS33              }
    { ja[7]                J14  LVCMOS33              }
    { jb[0]                V8   LVCMOS33              }
    { jb[1]                W8   LVCMOS33              }
    { jb[2]                U7   LVCMOS33              }
    { jb[3]                V7   LVCMOS33              }
    { jb[4]                Y7   LVCMOS33              }
    { jb[5]                Y6   LVCMOS33              }
    { jb[6]                V6   LVCMOS33              }
    { jb[7]                W6   LVCMOS33              }
    { jc[0]                V15  LVCMOS33              }
    { jc[1]                W15  LVCMOS33              }
    { jc[2]                T11  LVCMOS33              }
    { jc[3]                T10  LVCMOS33              }
    { jc[4]                W14  LVCMOS33              }
    { jc[5]                Y14  LVCMOS33              }
    { jc[6]                T12  LVCMOS33              }
    { jc[7]                U12  LVCMOS33              }
    { jd[0]                T14  LVCMOS33              }
    { jd[1]                T15  LVCMOS33              }
    { jd[2]                P14  LVCMOS33              }
    { jd[3]                R14  LVCMOS33              }
    { jd[4]                U14  LVCMOS33              }
    { jd[5]                U15  LVCMOS33              }
    { jd[6]                V17  LVCMOS33              }
    { jd[7]                V18  LVCMOS33              }
    { je[0]                V12  LVCMOS33              }
    { je[1]                W16  LVCMOS33              }
    { je[2]                J15  LVCMOS33              }
    { je[3]                H15  LVCMOS33              }
    { je[4]                V13  LVCMOS33              }
    { je[5]                U17  LVCMOS33              }
    { je[6]                T17  LVCMOS33              }
    { je[7]                Y17  LVCMOS33              }
    { dphy_clk_lp_n        J19  HSUL_12               }
    { dphy_clk_lp_p        H20  HSUL_12               }
    { dphy_data_lp_n[0]    M18  HSUL_12               }
    { dphy_data_lp_p[0]    L19  HSUL_12               }
    { dphy_data_lp_n[1]    L20  HSUL_12               }
    { dphy_data_lp_p[1]    J20  HSUL_12               }
    { dphy_hs_clock_clk_n  H18  LVDS_25               }
    { dphy_hs_clock_clk_p  J18  LVDS_25               }
    { dphy_data_hs_n[0]    M20  LVDS_25               }
    { dphy_data_hs_p[0]    M19  LVDS_25               }
    { dphy_data_hs_n[1]    L17  LVDS_25               }
    { dphy_data_hs_p[1]    L16  LVDS_25               }
    { cam_clk              G19  LVCMOS33              }
    { cam_gpio             G20  LVCMOS33  PULLUP true }
    { cam_scl              F20  LVCMOS33              }
    { cam_sda              F19  LVCMOS33              }
    { crypto_sda           P19  LVCMOS33              }
}

foreach pin $pins {
    set name [lindex $pin 0]
    if  {[llength [get_ports -quiet $name]]} {
        set number [lindex $pin 1]
        set iostandard [lindex $pin 2]
        set misc [lrange $pin 3 end]
        set_property -dict "PACKAGE_PIN $number IOSTANDARD $iostandard $misc" [get_ports $name]
    }
}
