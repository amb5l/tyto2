################################################################################
## qmtech_wukong.xdc                                                          ##
## Physical constraints for the QMTECH Wukong board.                          ##
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

if  {[llength [get_ports -quiet clki_50m]]} {
	create_clock -add -name clki_50m -period 20.00 [get_ports clki_50m]
	set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {clki_50m_IBUF}]
}

set pins {
	{ clki_50m       M22   LVCMOS33              } # net SYS_CLK
	{ led_n[0]       J6    LVCMOS33              } # D5, net LED0
	{ led_n[1]       H6    LVCMOS33              } # D6, net LED1
	{ key_n[0]       H7    LVCMOS33              } # SW2, net KEY0
	{ key_n[1]       J8    LVCMOS33              } # SW3, net KEY1
	{ ser_tx         E3    LVCMOS33              } # net BANK35_E3
	{ ser_rx         F3    LVCMOS33              } # net BANK35_F3
	{ hdmi_clk_p     D4    TMDS_33               } # net BANK35_D4
	{ hdmi_clk_n     C4    TMDS_33               } # net BANK35_C4
	{ hdmi_d_p[0]    E1    TMDS_33               } # net BANK35_E1
	{ hdmi_d_n[0]    D1    TMDS_33               } # net BANK35_D1
	{ hdmi_d_p[1]    F2    TMDS_33               } # net BANK35_F2
	{ hdmi_d_n[1]    E2    TMDS_33               } # net BANK35_E2
	{ hdmi_d_p[2]    G2    TMDS_33               } # net BANK35_G2
	{ hdmi_d_n[2]    G1    TMDS_33               } # net BANK35_G1
	{ hdmi_scl       B2    LVCMOS33  PULLUP TRUE } # net BANK35_B2
	{ hdmi_sda       A2    LVCMOS33  PULLUP TRUE } # net BANK35_A2
	{ hdmi_cec       B1    LVCMOS33              } # net BANK35_B1
	{ hdmi_hpd       A3    LVCMOS33              } # net BANK35_A3
	{ eth_rst_n      R1    LVCMOS33              } # net BANK34_R1
	{ eth_gtx_clk    U1    LVCMOS33              } # net BANK34_U1
	{ eth_txclk      M2    LVCMOS33              } # net BANK34_M2
	{ eth_txen       T2    LVCMOS33              } # net BANK34_T2
	{ eth_txer       J1    LVCMOS33              } # net BANK34_J1
	{ eth_txd[0]     R2    LVCMOS33              } # net BANK34_R2
	{ eth_txd[1]     P1    LVCMOS33              } # net BANK34_P1
	{ eth_txd[2]     N2    LVCMOS33              } # net BANK34_N2
	{ eth_txd[3]     N1    LVCMOS33              } # net BANK34_N1
	{ eth_txd[4]     M1    LVCMOS33              } # net BANK34_M1
	{ eth_txd[5]     L2    LVCMOS33              } # net BANK34_L2
	{ eth_txd[6]     K2    LVCMOS33              } # net BANK34_K2
	{ eth_txd[7]     K1    LVCMOS33              } # net BANK34_K1
	{ eth_rxclk      P4    LVCMOS33              } # net BANK34_P4
	{ eth_rxdv       L3    LVCMOS33              } # net BANK34_L3
	{ eth_rxer       U5    LVCMOS33              } # net BANK34_U5
	{ eth_rxd[0]     M4    LVCMOS33              } # net BANK34_M4
	{ eth_rxd[1]     N3    LVCMOS33              } # net BANK34_N3
	{ eth_rxd[2]     N4    LVCMOS33              } # net BANK34_N4
	{ eth_rxd[3]     P3    LVCMOS33              } # net BANK34_P3
	{ eth_rxd[4]     R3    LVCMOS33              } # net BANK34_R3
	{ eth_rxd[5]     T3    LVCMOS33              } # net BANK34_T3
	{ eth_rxd[6]     T4    LVCMOS33              } # net BANK34_T4
	{ eth_rxd[7]     T5    LVCMOS33              } # net BANK34_T5
	{ eth_crs        U2    LVCMOS33              } # net BANK34_U2
	{ eth_col        U4    LVCMOS33              } # net BANK34_U4
	{ eth_mdc        H2    LVCMOS33              } # net BANK34_H2
	{ eth_mdio       H1    LVCMOS33              } # net BANK34_H1
	{ j10[0]         D5    LVCMOS33              } # J10 pin 1, net BANK35_D5
	{ j10[1]         G5    LVCMOS33              } # J10 pin 2, net BANK35_G5
	{ j10[2]         G7    LVCMOS33              } # J10 pin 3, net BANK35_G7
	{ j10[3]         G8    LVCMOS33              } # J10 pin 4, net BANK35_G8
	{ j10[4]         E5    LVCMOS33              } # J10 pin 7, net BANK35_E5
	{ j10[5]         E6    LVCMOS33              } # J10 pin 9, net BANK35_E6
	{ j10[6]         D6    LVCMOS33              } # J10 pin 9, net BANK35_D6
	{ j10[7]         G6    LVCMOS33              } # J10 pin 10, net BANK35_G6
	{ j11[0]         H4    LVCMOS33              } # J11 pin 1, net BANK35_H4
	{ j11[1]         F4    LVCMOS33              } # J11 pin 2, net BANK35_F4
	{ j11[2]         A4    LVCMOS33              } # J11 pin 3, net BANK35_A4
	{ j11[3]         A5    LVCMOS33              } # J11 pin 4, net BANK35_A5
	{ j11[4]         J4    LVCMOS33              } # J11 pin 7, net BANK35_J4
	{ j11[5]         G4    LVCMOS33              } # J11 pin 8, net BANK35_G4
	{ j11[6]         B4    LVCMOS33              } # J11 pin 9, net BANK35_B4
	{ j11[7]         B5    LVCMOS33              } # J11 pin 10, net BANK35_B5
	{ jp2[0]         H21   LVCMOS33              } # JP2 pin 3, net BANK15_H21
	{ jp2[1]         H22   LVCMOS33              } # JP2 pin 4, net BANK15_H22
	{ jp2[2]         K21   LVCMOS33              } # JP2 pin 5, net BANK15_K21
	{ jp2[3]         J21   LVCMOS33              } # JP2 pin 6, net BANK15_J21
	{ jp2[4]         H26   LVCMOS33              } # JP2 pin 7, net BANK15_H26
	{ jp2[5]         G26   LVCMOS33              } # JP2 pin 8, net BANK15_G26
	{ jp2[6]         G25   LVCMOS33              } # JP2 pin 9, net BANK15_G25
	{ jp2[7]         F25   LVCMOS33              } # JP2 pin 10, net BANK15_F25
	{ jp2[8]         G20   LVCMOS33              } # JP2 pin 11, net BANK15_G20
	{ jp2[9]         G21   LVCMOS33              } # JP2 pin 12, net BANK15_G21
	{ jp2[10]        F23   LVCMOS33              } # JP2 pin 13, net BANK15_F23
	{ jp2[11]        E23   LVCMOS33              } # JP2 pin 14, net BANK15_E23
	{ jp2[12]        E26   LVCMOS33              } # JP2 pin 15, net BANK15_E26
	{ jp2[13]        D26   LVCMOS33              } # JP2 pin 16, net BANK15_D26
	{ jp2[14]        E25   LVCMOS33              } # JP2 pin 17, net BANK15_E25
	{ jp2[15]        D25   LVCMOS33              } # JP2 pin 18, net BANK15_D25
	{ j12[0]         AB26  LVCMOS33              } # J12 pin 3, net BANK13_AB26
	{ j12[1]         AC26  LVCMOS33              } # J12 pin 4, net BANK13_AC26
	{ j12[2]         AB24  LVCMOS33              } # J12 pin 5, net BANK13_AB24
	{ j12[3]         AC24  LVCMOS33              } # J12 pin 6, net BANK13_AC24
	{ j12[4]         AA24  LVCMOS33              } # J12 pin 7, net BANK13_AA24
	{ j12[5]         AB25  LVCMOS33              } # J12 pin 8, net BANK13_AB25
	{ j12[6]         AA22  LVCMOS33              } # J12 pin 9, net BANK13_AA22
	{ j12[7]         AA23  LVCMOS33              } # J12 pin 10, net BANK13_AA23
	{ j12[8]         Y25   LVCMOS33              } # J12 pin 11, net BANK13_Y25
	{ j12[9]         AA25  LVCMOS33              } # J12 pin 12, net BANK13_AA25
	{ j12[10]        W25   LVCMOS33              } # J12 pin 13, net BANK13_W25
	{ j12[11]        Y26   LVCMOS33              } # J12 pin 14, net BANK13_Y26
	{ j12[12]        Y22   LVCMOS33              } # J12 pin 15, net BANK13_Y22
	{ j12[13]        Y23   LVCMOS33              } # J12 pin 16, net BANK13_Y23
	{ j12[14]        W21   LVCMOS33              } # J12 pin 17, net BANK13_W21
	{ j12[15]        Y21   LVCMOS33              } # J12 pin 18, net BANK13_Y21
	{ j12[16]        V26   LVCMOS33              } # J12 pin 19, net BANK13_V26
	{ j12[17]        W26   LVCMOS33              } # J12 pin 20, net BANK13_W26
	{ j12[18]        U25   LVCMOS33              } # J12 pin 21, net BANK13_U25
	{ j12[19]        U26   LVCMOS33              } # J12 pin 22, net BANK13_U26
	{ j12[20]        V23   LVCMOS33              } # J12 pin 23, net BANK13_V23
	{ j12[21]        W24   LVCMOS33              } # J12 pin 24, net BANK13_W24
	{ j12[22]        V24   LVCMOS33              } # J12 pin 25, net BANK13_V24
	{ j12[23]        W23   LVCMOS33              } # J12 pin 26, net BANK13_W23
	{ j12[24]        V18   LVCMOS33              } # J12 pin 27, net BANK13_V18
	{ j12[25]        W18   LVCMOS33              } # J12 pin 28, net BANK13_W18
	{ j12[26]        U22   LVCMOS33              } # J12 pin 29, net BANK13_U22
	{ j12[27]        V22   LVCMOS33              } # J12 pin 30, net BANK13_V22
	{ j12[28]        U21   LVCMOS33              } # J12 pin 31, net BANK13_U21
	{ j12[29]        V21   LVCMOS33              } # J12 pin 32, net BANK13_V21
	{ j12[30]        T20   LVCMOS33              } # J12 pin 33, net BANK13_T20
	{ j12[31]        U20   LVCMOS33              } # J12 pin 34, net BANK13_U20
	{ j12[32]        T19   LVCMOS33              } # J12 pin 35, net BANK13_T19
	{ j12[33]        U19   LVCMOS33              } # J12 pin 36, net BANK13_U19
	{ mgt_clk_p[0]   AA13                        } # net MGT_CLK0_P
	{ mgt_clk_n[0]   AB13                        } # net MGT_CLK0_N
	{ mgt_clk_p[1]   AB11                        } # JP3 pin 14, net MGT_CLK1_P
	{ mgt_clk_n[1]   AA11                        } # JP3 pin 13, net MGT_CLK1_N
	{ mgt_tx_p[0]    AC10                        } # JP3 pin 10, net MGT_TXP0
	{ mgt_tx_n[0]    AD10                        } # JP3 pin 9, net MGT_TXN0
	{ mgt_tx_p[1]    AE9                         } # JP3 pin 8, net MGT_TXP1
	{ mgt_tx_n[1]    AF9                         } # JP3 pin 7, net MGT_TXN1
	{ mgt_tx_p[2]    AC8                         } # JP3 pin 6, net MGT_TXP2
	{ mgt_tx_n[2]    AD8                         } # JP3 pin 5, net MGT_TXN2
	{ mgt_tx_p[3]    AE7                         } # JP3 pin 4, net MGT_TXP3
	{ mgt_tx_n[3]    AF7                         } # JP3 pin 3, net MGT_TXN3
	{ mgt_rx_p[0]    AC12                        } # JP3 pin 24, net MGT_RXP0
	{ mgt_rx_n[0]    AD12                        } # JP3 pin 23, net MGT_RXN0
	{ mgt_rx_p[1]    AE13                        } # JP3 pin 22, net MGT_RXP1
	{ mgt_rx_n[1]    AF13                        } # JP3 pin 21, net MGT_RXN1
	{ mgt_rx_p[2]    AC14                        } # JP3 pin 20, net MGT_RXP2
	{ mgt_rx_n[2]    AD14                        } # JP3 pin 19, net MGT_RXN2
	{ mgt_rx_p[3]    AE11                        } # JP3 pin 18, net MGT_RXP3
	{ mgt_rx_n[3]    AF11                        } # JP3 pin 17, net MGT_RXN3
	{ ddr3_rst_n     H17   LVCMOS15              } # net DDR_RESETN
	{ ddr3_clk_p     F18                         } # net DDR_CLK+
	{ ddr3_clk_n     F19                         } # net DDR_CLK-
	{ ddr3_cke       E18                         } # net DDR_CKE
	{ ddr3_ras_n     A19                         } # net DDR_RAS
	{ ddr3_cas_n     B19                         } # net DDR_CAS
	{ ddr3_we_n      A18                         } # net DDR_WE
	{ ddr3_odt       G19                         } # net DDR_ODT
	{ ddr3_a[0]      E17                         } # net DDR_A0
	{ ddr3_a[1]      G17                         } # net DDR_A1
	{ ddr3_a[2]      F17                         } # net DDR_A2
	{ ddr3_a[3]      C17                         } # net DDR_A3
	{ ddr3_a[4]      G16                         } # net DDR_A4
	{ ddr3_a[5]      D16                         } # net DDR_A5
	{ ddr3_a[6]      H16                         } # net DDR_A6
	{ ddr3_a[7]      E16                         } # net DDR_A7
	{ ddr3_a[8]      H14                         } # net DDR_A8
	{ ddr3_a[9]      F15                         } # net DDR_A9
	{ ddr3_a[10]     F20                         } # net DDR_A10
	{ ddr3_a[11]     H15                         } # net DDR_A11
	{ ddr3_a[12]     C18                         } # net DDR_A12
	{ ddr3_a[13]     G15                         } # net DDR_A13
	{ ddr3_ba[0]     B17                         } # net DDR_BA0
	{ ddr3_ba[1]     D18                         } # net DDR_BA1
	{ ddr3_ba[2]     A17                         } # net DDR_BA2
	{ ddr3_dqm[0]    A22                         } # net DDR_DQM0
	{ ddr3_dqm[1]    C22                         } # net DDR_DQM1
	{ ddr3_d[0]      D21                         } # net DDR_D0
	{ ddr3_d[1]      C21                         } # net DDR_D1
	{ ddr3_d[2]      B22                         } # net DDR_D2
	{ ddr3_d[3]      B21                         } # net DDR_D3
	{ ddr3_d[4]      D19                         } # net DDR_D4
	{ ddr3_d[5]      E20                         } # net DDR_D5
	{ ddr3_d[6]      C19                         } # net DDR_D6
	{ ddr3_d[7]      D20                         } # net DDR_D7
	{ ddr3_d[8]      C23                         } # net DDR_D8
	{ ddr3_d[9]      D23                         } # net DDR_D9
	{ ddr3_d[10]     B24                         } # net DDR_D10
	{ ddr3_d[11]     B25                         } # net DDR_D11
	{ ddr3_d[12]     C24                         } # net DDR_D12
	{ ddr3_d[13]     C26                         } # net DDR_D13
	{ ddr3_d[14]     A25                         } # net DDR_D14
	{ ddr3_d[15]     B26                         } # net DDR_D15
	{ ddr3_dqs_p[0]  B20                         } # net DDR_DQS0+
	{ ddr3_dqs_n[0]  A20                         } # net DDR_DQS0-
	{ ddr3_dqs_p[1]  A23                         } # net DDR_DQS1+
	{ ddr3_dqs_n[1]  A24                         } # net DDR_DQS1-
}

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
