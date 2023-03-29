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

create_clock -add -name sysclk -period 8.00 -waveform {0 4} [get_ports sysclk]

set pins {
    { sysclk               K17  LVCMOS33              }
    { sw_i[0]              G15  LVCMOS33              }
    { sw_i[1]              P15  LVCMOS33              }
    { sw_i[2]              W13  LVCMOS33              }
    { sw_i[3]              T16  LVCMOS33              }
    { btn_i[0]             K18  LVCMOS33              }
    { btn_i[1]             P16  LVCMOS33              }
    { btn_i[2]             K19  LVCMOS33              }
    { btn_i[3]             Y16  LVCMOS33              }
    { led_o[0]             M14  LVCMOS33              }
    { led_o[1]             M15  LVCMOS33              }
    { led_o[2]             G14  LVCMOS33              }
    { led_o[3]             D18  LVCMOS33              }
    { led5_r_o             Y11  LVCMOS33              }
    { led5_g_o             T5   LVCMOS33              }
    { led5_b_o             Y12  LVCMOS33              }
    { led6_r_o             V16  LVCMOS33              }
    { led6_g_o             F17  LVCMOS33              }
    { led6_b_o             M17  LVCMOS33              }
    { ac_bclk_io           R19  LVCMOS33              }
    { ac_mclk_i            R17  LVCMOS33              }
    { ac_muten_o           P18  LVCMOS33              }
    { ac_pbdat_o           R18  LVCMOS33              }
    { ac_pblrc_io          T19  LVCMOS33              }
    { ac_recdat_i          R16  LVCMOS33              }
    { ac_reclrc_io         Y18  LVCMOS33              }
    { ac_scl_o             N18  LVCMOS33              }
    { ac_sda_io            N17  LVCMOS33              }
    { eth_int_pu_b_i       F16  LVCMOS33  PULLUP true }
    { eth_rst_b_o          E17  LVCMOS33              }
    { fan_fb_pu_i          Y13  LVCMOS33  PULLUP true }
    { hdmi_rx_hpd_o        W19  LVCMOS33              }
    { hdmi_rx_scl_io       W18  LVCMOS33              }
    { hdmi_rx_sda_io       Y19  LVCMOS33              }
    { hdmi_rx_clk_n_i      U19  TMDS_33               }
    { hdmi_rx_clk_p_i      U18  TMDS_33               }
    { hdmi_rx_n_i[0]       W20  TMDS_33               }
    { hdmi_rx_p_i[0]       V20  TMDS_33               }
    { hdmi_rx_n_i[1]       U20  TMDS_33               }
    { hdmi_rx_p_i[1]       T20  TMDS_33               }
    { hdmi_rx_n_i[2]       P20  TMDS_33               }
    { hdmi_rx_p_i[2]       N20  TMDS_33               }
    { hdmi_rx_cec_i        Y8   LVCMOS33              }
    { hdmi_tx_hpd_i        E18  LVCMOS33              }
    { hdmi_tx_scl_io       G17  LVCMOS33              }
    { hdmi_tx_sda_io       G18  LVCMOS33              }
    { hdmi_tx_clk_n_o      H17  TMDS_33               }
    { hdmi_tx_clk_p_o      H16  TMDS_33               }
    { hdmi_tx_n_o[0]       D20  TMDS_33               }
    { hdmi_tx_p_o[0]       D19  TMDS_33               }
    { hdmi_tx_n_o[1]       B20  TMDS_33               }
    { hdmi_tx_p_o[1]       C20  TMDS_33               }
    { hdmi_tx_n_o[2]       A20  TMDS_33               }
    { hdmi_tx_p_o[2]       B19  TMDS_33               }
    { hdmi_tx_cec_o        E19  LVCMOS33              }
    { ja_io[0]             N15  LVCMOS33              }
    { ja_io[1]             L14  LVCMOS33              }
    { ja_io[2]             K16  LVCMOS33              }
    { ja_io[3]             K14  LVCMOS33              }
    { ja_io[4]             N16  LVCMOS33              }
    { ja_io[5]             L15  LVCMOS33              }
    { ja_io[6]             J16  LVCMOS33              }
    { ja_io[7]             J14  LVCMOS33              }
    { jb_io[0]             V8   LVCMOS33              }
    { jb_io[1]             W8   LVCMOS33              }
    { jb_io[2]             U7   LVCMOS33              }
    { jb_io[3]             V7   LVCMOS33              }
    { jb_io[4]             Y7   LVCMOS33              }
    { jb_io[5]             Y6   LVCMOS33              }
    { jb_io[6]             V6   LVCMOS33              }
    { jb_io[7]             W6   LVCMOS33              }
    { jc_io[0]             V15  LVCMOS33              }
    { jc_io[1]             W15  LVCMOS33              }
    { jc_io[2]             T11  LVCMOS33              }
    { jc_io[3]             T10  LVCMOS33              }
    { jc_io[4]             W14  LVCMOS33              }
    { jc_io[5]             Y14  LVCMOS33              }
    { jc_io[6]             T12  LVCMOS33              }
    { jc_io[7]             U12  LVCMOS33              }
    { jd_io[0]             T14  LVCMOS33              }
    { jd_io[1]             T15  LVCMOS33              }
    { jd_io[2]             P14  LVCMOS33              }
    { jd_io[3]             R14  LVCMOS33              }
    { jd_io[4]             U14  LVCMOS33              }
    { jd_io[5]             U15  LVCMOS33              }
    { jd_io[6]             V17  LVCMOS33              }
    { jd_io[7]             V18  LVCMOS33              }
    { je_io[0]             V12  LVCMOS33              }
    { je_io[1]             W16  LVCMOS33              }
    { je_io[2]             J15  LVCMOS33              }
    { je_io[3]             H15  LVCMOS33              }
    { je_io[4]             V13  LVCMOS33              }
    { je_io[5]             U17  LVCMOS33              }
    { je_io[6]             T17  LVCMOS33              }
    { je_io[7]             Y17  LVCMOS33              }
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
    { cam_clk_i            G19  LVCMOS33              }
    { cam_gpio_i           G20  LVCMOS33  PULLUP true }
    { cam_scl_io           F20  LVCMOS33              }
    { cam_sda_io           F19  LVCMOS33              }
    { crypto_sda_io        P19  LVCMOS33              }
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
