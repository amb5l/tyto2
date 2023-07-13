################################################################################
## digilent_nexys_video.tcl                                                   ##
## Physical constraints for the Digilent Nexys Video board.                   ##
################################################################################
## (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        ##
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

if  {[llength [get_ports -quiet clki_100m]]} {
    create_clock -add -name clki_100m -period 10.00 -waveform {0 5} [get_ports clki_100m]
}

set pins {
	{ clki_100m       R4    LVCMOS33              }
	{ gtp_clk_n       E6                          }
	{ gtp_clk_p       F6                          }
	{ fmc_mgt_clk_n   E10                         }
	{ fmc_mgt_clk_p   F10                         }
	{ led[0]          T14   LVCMOS25              }
	{ led[1]          T15   LVCMOS25              }
	{ led[2]          T16   LVCMOS25              }
	{ led[3]          U16   LVCMOS25              }
	{ led[4]          V15   LVCMOS25              }
	{ led[5]          W16   LVCMOS25              }
	{ led[6]          W15   LVCMOS25              }
	{ led[7]          Y13   LVCMOS25              }
	{ btn_c           B22   LVCMOS12              }
	{ btn_d           D22   LVCMOS12              }
	{ btn_l           C22   LVCMOS12              }
	{ btn_r           D14   LVCMOS12              }
	{ btn_u           F15   LVCMOS12              }
	{ btn_rst_n       G4    LVCMOS15              }
	{ sw[0]           E22   LVCMOS12              }
	{ sw[1]           F21   LVCMOS12              }
	{ sw[2]           G21   LVCMOS12              }
	{ sw[3]           G22   LVCMOS12              }
	{ sw[4]           H17   LVCMOS12              }
	{ sw[5]           J16   LVCMOS12              }
	{ sw[6]           K13   LVCMOS12              }
	{ sw[7]           M17   LVCMOS12              }
	{ oled_res_n      U21   LVCMOS33              }
	{ oled_d_c        W22   LVCMOS33              }
	{ oled_sclk       W21   LVCMOS33              }
	{ oled_sdin       Y22   LVCMOS33              }
	{ oled_vbat_dis   P20   LVCMOS33              }
	{ oled_vdd_dis    V22   LVCMOS33              }
	{ hdmi_rx_clk_p   V4    TMDS_33               }
	{ hdmi_rx_clk_n   W4    TMDS_33               }
	{ hdmi_rx_d_p[0]  Y3    TMDS_33               }
	{ hdmi_rx_d_n[0]  AA3   TMDS_33               }
	{ hdmi_rx_d_p[1]  W2    TMDS_33               }
	{ hdmi_rx_d_n[1]  Y2    TMDS_33               }
	{ hdmi_rx_d_p[2]  U2    TMDS_33               }
	{ hdmi_rx_d_n[2]  V2    TMDS_33               }
	{ hdmi_rx_scl     Y4    LVCMOS33              }
	{ hdmi_rx_sda     AB5   LVCMOS33              }
	{ hdmi_rx_cec     AA5   LVCMOS33              }
	{ hdmi_rx_hpd     AB12  LVCMOS25              }
	{ hdmi_rx_txen    R3    LVCMOS33              }
	{ hdmi_tx_clk_p   T1    TMDS_33               }
	{ hdmi_tx_clk_n   U1    TMDS_33               }
	{ hdmi_tx_d_p[0]  W1    TMDS_33               }
	{ hdmi_tx_d_n[0]  Y1    TMDS_33               }
	{ hdmi_tx_d_p[1]  AA1   TMDS_33               }
	{ hdmi_tx_d_n[1]  AB1   TMDS_33               }
	{ hdmi_tx_d_p[2]  AB3   TMDS_33               }
	{ hdmi_tx_d_n[2]  AB2   TMDS_33               }
	{ hdmi_tx_scl     U3    LVCMOS33              }
	{ hdmi_tx_sda     V3    LVCMOS33              }
	{ hdmi_tx_cec     AA4   LVCMOS33              }
	{ hdmi_tx_hpd     AB13  LVCMOS25              }
	{ dp_tx_p[0]      B4                          }
	{ dp_tx_n[0]      A4                          }
	{ dp_tx_p[1]      D5                          }
	{ dp_tx_n[1]      C5                          }
	{ dp_tx_aux_p     AA9   TMDS_33               }
	{ dp_tx_aux_n     AB10  TMDS_33               }
	{ dp_tx_aux_p     AA10  TMDS_33               }
	{ dp_tx_aux_n     AA11  TMDS_33               }
	{ dp_tx_hpd       N15   LVCMOS33              }
	{ ac_mclk         U6    LVCMOS33              }
	{ ac_lrclk        U5    LVCMOS33              }
	{ ac_bclk         T5    LVCMOS33              }
	{ ac_dac_sdata    W6    LVCMOS33              }
	{ ac_adc_sdata    T4    LVCMOS33              }
	{ ja[0]           AB22  LVCMOS33              }
	{ ja[1]           AB21  LVCMOS33              }
	{ ja[2]           AB20  LVCMOS33              }
	{ ja[3]           AB18  LVCMOS33              }
	{ ja[4]           Y21   LVCMOS33              }
	{ ja[5]           AA21  LVCMOS33              }
	{ ja[6]           AA20  LVCMOS33              }
	{ ja[7]           AA18  LVCMOS33              }
	{ jb[0]           V9    LVCMOS33              }
	{ jb[1]           V8    LVCMOS33              }
	{ jb[2]           V7    LVCMOS33              }
	{ jb[3]           W7    LVCMOS33              }
	{ jb[4]           W9    LVCMOS33              }
	{ jb[5]           Y9    LVCMOS33              }
	{ jb[6]           Y8    LVCMOS33              }
	{ jb[7]           Y7    LVCMOS33              }
	{ jc[0]           Y6    LVCMOS33              }
	{ jc[1]           AA6   LVCMOS33              }
	{ jc[2]           AA8   LVCMOS33              }
	{ jc[3]           AB8   LVCMOS33              }
	{ jc[4]           R6    LVCMOS33              }
	{ jc[5]           T6    LVCMOS33              }
	{ jc[6]           AB7   LVCMOS33              }
	{ jc[7]           AB6   LVCMOS33              }
	{ xa_p[0]         J14   LVCMOS12              }
	{ xa_n[0]         H14   LVCMOS12              }
	{ xa_p[1]         H13   LVCMOS12              }
	{ xa_n[1]         G13   LVCMOS12              }
	{ xa_p[2]         G15   LVCMOS12              }
	{ xa_n[2]         G16   LVCMOS12              }
	{ xa_p[3]         J15   LVCMOS12              }
	{ xa_n[3]         H15   LVCMOS12              }
	{ uart_rx_out     AA19  LVCMOS33              }
	{ uart_tx_in      V18   LVCMOS33              }
	{ eth_rst_n       U7    LVCMOS33              }
	{ eth_txck        AA14  LVCMOS25              }
	{ eth_txctl       V10   LVCMOS25              }
	{ eth_txd[0]      Y12   LVCMOS25              }
	{ eth_txd[1]      W12   LVCMOS25              }
	{ eth_txd[2]      W11   LVCMOS25              }
	{ eth_txd[3]      Y11   LVCMOS25              }
	{ eth_rxck        V13   LVCMOS25              }
	{ eth_rxctl       W10   LVCMOS25              }
	{ eth_rxd[0]      AB16  LVCMOS25              }
	{ eth_rxd[1]      AA15  LVCMOS25              }
	{ eth_rxd[2]      AB15  LVCMOS25              }
	{ eth_rxd[3]      AB11  LVCMOS25              }
	{ eth_mdc         AA16  LVCMOS25              }
	{ eth_mdio        Y16   LVCMOS25              }
	{ eth_int_n       Y14   LVCMOS25              }
	{ eth_pme_n       W14   LVCMOS25              }
	{ fan_pwm         U15   LVCMOS25              }
	{ ftdi_clko       Y18   LVCMOS33              }
	{ ftdi_rxf_n      N17   LVCMOS33              }
	{ ftdi_txe_n      Y19   LVCMOS33              }
	{ ftdi_rd_n       P19   LVCMOS33              }
	{ ftdi_wr_n       R19   LVCMOS33              }
	{ ftdi_siwu_n     P17   LVCMOS33              }
	{ ftdi_oe_n       V17   LVCMOS33              }
	{ ftdi_d[0]       U20   LVCMOS33              }
	{ ftdi_d[1]       P14   LVCMOS33              }
	{ ftdi_d[2]       P15   LVCMOS33              }
	{ ftdi_d[3]       U17   LVCMOS33              }
	{ ftdi_d[4]       R17   LVCMOS33              }
	{ ftdi_d[5]       P16   LVCMOS33              }
	{ ftdi_d[6]       R18   LVCMOS33              }
	{ ftdi_d[7]       N14   LVCMOS33              }
	{ ftdi_spien      R14   LVCMOS33              }
	{ ps2_clk         W17   LVCMOS33  PULLUP TRUE }
	{ ps2_data        N13   LVCMOS33  PULLUP TRUE }
	{ qspi_cs_n       T19   LVCMOS33              }
	{ qspi_dq[0]      P22   LVCMOS33              }
	{ qspi_dq[1]      R22   LVCMOS33              }
	{ qspi_dq[2]      P21   LVCMOS33              }
	{ qspi_dq[3]      R21   LVCMOS33              }
	{ sd_cclk         W19   LVCMOS33              }
	{ sd_cd           T18   LVCMOS33              }
	{ sd_cmd          W20   LVCMOS33              }
	{ sd_d[0]         V19   LVCMOS33              }
	{ sd_d[1]         T21   LVCMOS33              }
	{ sd_d[2]         T20   LVCMOS33              }
	{ sd_d[3]         U18   LVCMOS33              }
	{ sd_reset        V20   LVCMOS33              }
	{ i2c_scl         W5    LVCMOS33              }
	{ i2c_sda         V5    LVCMOS33              }
	{ set_vadj[0]     AA13  LVCMOS25              }
	{ set_vadj[1]     AB17  LVCMOS25              }
	{ vadj_en         V14   LVCMOS25              }
	{ fmc_clk0_m2c_n  H19   LVCMOS12              }
	{ fmc_clk0_m2c_p  J19   LVCMOS12              }
	{ fmc_clk1_m2c_n  C19   LVCMOS12              }
	{ fmc_clk1_m2c_p  C18   LVCMOS12              }
	{ fmc_la_n[0]     K19   LVCMOS12              }
	{ fmc_la_p[0]     K18   LVCMOS12              }
	{ fmc_la_n[1]     J21   LVCMOS12              }
	{ fmc_la_p[1]     J20   LVCMOS12              }
	{ fmc_la_n[2]     L18   LVCMOS12              }
	{ fmc_la_p[2]     M18   LVCMOS12              }
	{ fmc_la_n[3]     N19   LVCMOS12              }
	{ fmc_la_p[3]     N18   LVCMOS12              }
	{ fmc_la_n[4]     M20   LVCMOS12              }
	{ fmc_la_p[4]     N20   LVCMOS12              }
	{ fmc_la_n[5]     L21   LVCMOS12              }
	{ fmc_la_p[5]     M21   LVCMOS12              }
	{ fmc_la_n[6]     M22   LVCMOS12              }
	{ fmc_la_p[6]     N22   LVCMOS12              }
	{ fmc_la_n[7]     L13   LVCMOS12              }
	{ fmc_la_p[7]     M13   LVCMOS12              }
	{ fmc_la_n[8]     M16   LVCMOS12              }
	{ fmc_la_p[8]     M15   LVCMOS12              }
	{ fmc_la_n[9]     G20   LVCMOS12              }
	{ fmc_la_p[9]     H20   LVCMOS12              }
	{ fmc_la_n[10]    K22   LVCMOS12              }
	{ fmc_la_p[10]    K21   LVCMOS12              }
	{ fmc_la_n[11]    L15   LVCMOS12              }
	{ fmc_la_p[11]    L14   LVCMOS12              }
	{ fmc_la_n[12]    L20   LVCMOS12              }
	{ fmc_la_p[12]    L19   LVCMOS12              }
	{ fmc_la_n[13]    J17   LVCMOS12              }
	{ fmc_la_p[13]    K17   LVCMOS12              }
	{ fmc_la_n[14]    H22   LVCMOS12              }
	{ fmc_la_p[14]    J22   LVCMOS12              }
	{ fmc_la_n[15]    K16   LVCMOS12              }
	{ fmc_la_p[15]    L16   LVCMOS12              }
	{ fmc_la_n[16]    G18   LVCMOS12              }
	{ fmc_la_p[16]    G17   LVCMOS12              }
	{ fmc_la_n[17]    B18   LVCMOS12              }
	{ fmc_la_p[17]    B17   LVCMOS12              }
	{ fmc_la_n[18]    C17   LVCMOS12              }
	{ fmc_la_p[18]    D17   LVCMOS12              }
	{ fmc_la_n[19]    A19   LVCMOS12              }
	{ fmc_la_p[19]    A18   LVCMOS12              }
	{ fmc_la_n[20]    F20   LVCMOS12              }
	{ fmc_la_p[20]    F19   LVCMOS12              }
	{ fmc_la_n[21]    D19   LVCMOS12              }
	{ fmc_la_p[21]    E19   LVCMOS12              }
	{ fmc_la_n[22]    D21   LVCMOS12              }
	{ fmc_la_p[22]    E21   LVCMOS12              }
	{ fmc_la_n[23]    A21   LVCMOS12              }
	{ fmc_la_p[23]    B21   LVCMOS12              }
	{ fmc_la_n[24]    B16   LVCMOS12              }
	{ fmc_la_p[24]    B15   LVCMOS12              }
	{ fmc_la_n[25]    E17   LVCMOS12              }
	{ fmc_la_p[25]    F16   LVCMOS12              }
	{ fmc_la_n[26]    E18   LVCMOS12              }
	{ fmc_la_p[26]    F18   LVCMOS12              }
	{ fmc_la_n[27]    A20   LVCMOS12              }
	{ fmc_la_p[27]    B20   LVCMOS12              }
	{ fmc_la_n[28]    B13   LVCMOS12              }
	{ fmc_la_p[28]    C13   LVCMOS12              }
	{ fmc_la_n[29]    C15   LVCMOS12              }
	{ fmc_la_p[29]    C14   LVCMOS12              }
	{ fmc_la_n[30]    A14   LVCMOS12              }
	{ fmc_la_p[30]    A13   LVCMOS12              }
	{ fmc_la_n[31]    E14   LVCMOS12              }
	{ fmc_la_p[31]    E13   LVCMOS12              }
	{ fmc_la_n[32]    A16   LVCMOS12              }
	{ fmc_la_p[32]    A15   LVCMOS12              }
	{ fmc_la_n[33]    F14   LVCMOS12              }
	{ fmc_la_p[33]    F13   LVCMOS12              }
	{ ddr3_reset_n    G1    LVCMOS15              }
	{ ddr3_ck_n       P4                          }
	{ ddr3_ck_p       P5                          }
	{ ddr3_cke        J6                          }
	{ ddr3_ras_n      J4                          }
	{ ddr3_cas_n      K3                          }
	{ ddr3_we_n       L1                          }
	{ ddr3_odt        K4                          }
	{ ddr3_addr[0]    M2                          }
	{ ddr3_addr[1]    M5                          }
	{ ddr3_addr[2]    M3                          }
	{ ddr3_addr[3]    M1                          }
	{ ddr3_addr[4]    L6                          }
	{ ddr3_addr[5]    P1                          }
	{ ddr3_addr[6]    N3                          }
	{ ddr3_addr[7]    N2                          }
	{ ddr3_addr[8]    M6                          }
	{ ddr3_addr[9]    R1                          }
	{ ddr3_addr[10]   L5                          }
	{ ddr3_addr[11]   N5                          }
	{ ddr3_addr[12]   N4                          }
	{ ddr3_addr[13]   P2                          }
	{ ddr3_addr[14]   P6                          }
	{ ddr3_ba[0]      L3                          }
	{ ddr3_ba[1]      K6                          }
	{ ddr3_ba[2]      L4                          }
	{ ddr3_dm[0]      G3                          }
	{ ddr3_dm[1]      F1                          }
	{ ddr3_dq[0]      G2                          }
	{ ddr3_dq[1]      H4                          }
	{ ddr3_dq[2]      H5                          }
	{ ddr3_dq[3]      J1                          }
	{ ddr3_dq[4]      K1                          }
	{ ddr3_dq[5]      H3                          }
	{ ddr3_dq[6]      H2                          }
	{ ddr3_dq[7]      J5                          }
	{ ddr3_dq[8]      E3                          }
	{ ddr3_dq[9]      B2                          }
	{ ddr3_dq[10]     F3                          }
	{ ddr3_dq[11]     D2                          }
	{ ddr3_dq[12]     C2                          }
	{ ddr3_dq[13]     A1                          }
	{ ddr3_dq[14]     E2                          }
	{ ddr3_dq[15]     B1                          }
	{ ddr3_dqs_n[0]   J2                          }
	{ ddr3_dqs_p[0]   K2                          }
	{ ddr3_dqs_n[1]   D1                          }
	{ ddr3_dqs_p[1]   E1                          }
}

foreach pin $pins {
    set name [lindex $pin 0]
    if  {[llength [get_ports -quiet $name]]} {
        set number [lindex $pin 1]
		if {[llength $pin] == 2} {
			set_property -dict "PACKAGE_PIN $number" [get_ports $name]
		} else {
			set iostandard [lindex $pin 2]
			set misc [lrange $pin 3 end]
			set_property -dict "PACKAGE_PIN $number IOSTANDARD $iostandard $misc" [get_ports $name]
		}
    }
}

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
