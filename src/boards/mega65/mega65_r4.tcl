################################################################################
## mega65_r4.tcl                                                              ##
## Physical constraints for the MEGA65 rev 4.                                 ##
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

set pins {
    { clk_in          V13   LVCMOS33                                         }
    { rst             J19   LVCMOS33                                         }
    { uled            U22   LVCMOS33                                         }
    { led_g_n         V19   LVCMOS33                                         }
    { led_r_n         V20   LVCMOS33                                         }
    { uart_tx         L13   LVCMOS33                                         }
    { uart_rx         L14   LVCMOS33                                         }
    { qspi_cs_n       T19   LVCMOS33                                         }
    { qspi_d[0]       P22   LVCMOS33  PULLTYPE PULLUP                        }
    { qspi_d[1]       R22   LVCMOS33  PULLTYPE PULLUP                        }
    { qspi_d[2]       P21   LVCMOS33  PULLTYPE PULLUP                        }
    { qspi_d[3]       R21   LVCMOS33  PULLTYPE PULLUP                        }
    { sdi_cd_n        D17   LVCMOS33                                         }
    { sdi_wp_n        C17   LVCMOS33                                         }
    { sdi_ss_n        B15   LVCMOS33                                         }
    { sdi_clk         B17   LVCMOS33                                         }
    { sdi_mosi        B16   LVCMOS33                                         }
    { sdi_miso        B18   LVCMOS33                                         }
    { sdi_d1          C18   LVCMOS33                                         }
    { sdi_d2          C19   LVCMOS33                                         }
    { sdx_cd_n        K1    LVCMOS33                                         }
    { sdx_ss_n        K2    LVCMOS33                                         }
    { sdx_clk         G2    LVCMOS33                                         }
    { sdx_mosi        J2    LVCMOS33                                         }
    { sdx_miso        H2    LVCMOS33                                         }
    { sdx_d1          H3    LVCMOS33                                         }
    { sdx_d2          J1    LVCMOS33                                         }
    { i2c_scl         A15   LVCMOS33                                         }
    { i2c_sda         A16   LVCMOS33                                         }
    { grove_scl       G21   LVCMOS33                                         }
    { grove_sda       G22   LVCMOS33                                         }
    { dipsw[0]        N18   LVCMOS33                                         }
    { dipsw[1]        P19   LVCMOS33                                         }
    { dipsw[2]        T16   LVCMOS33                                         }
    { dipsw[3]        U16   LVCMOS33                                         }
    { rev[0]          L15   LVCMOS33                                         }
    { rev[1]          M16   LVCMOS33                                         }
    { rev[2]          F20   LVCMOS33                                         }
    { rev[3]          T21   LVCMOS33                                         }
    { kb_io0          A14   LVCMOS33                                         }
    { kb_io1          A13   LVCMOS33                                         }
    { kb_io2          C13   LVCMOS33                                         }
    { kb_jtagen       B13   LVCMOS33                                         }
    { kb_tck          E13   LVCMOS33                                         }
    { kb_tms          D14   LVCMOS33                                         }
    { kb_tdi          D15   LVCMOS33                                         }
    { kb_tdo          E14   LVCMOS33                                         }
    { js_pd           D19   LVCMOS33                                         }
    { js_pg           D20   LVCMOS33                                         }
    { jsai_up_n       C14   LVCMOS33                                         }
    { jsai_down_n     F16   LVCMOS33                                         }
    { jsai_left_n     F14   LVCMOS33                                         }
    { jsai_right_n    F13   LVCMOS33                                         }
    { jsai_fire_n     E17   LVCMOS33                                         }
    { jsbi_up_n       W19   LVCMOS33                                         }
    { jsbi_down_n     P17   LVCMOS33                                         }
    { jsbi_left_n     F21   LVCMOS33                                         }
    { jsbi_right_n    C15   LVCMOS33                                         }
    { jsbi_fire_n     F15   LVCMOS33                                         }
    { jsao_up_n       G16   LVCMOS33                                         }
    { jsao_down_n     K14   LVCMOS33                                         }
    { jsao_left_n     K13   LVCMOS33                                         }
    { jsao_right_n    L16   LVCMOS33                                         }
    { jsao_fire_n     J17   LVCMOS33                                         }
    { jsbo_up_n       N20   LVCMOS33                                         }
    { jsbo_down_n     M18   LVCMOS33                                         }
    { jsbo_left_n     M17   LVCMOS33                                         }
    { jsbo_right_n    E18   LVCMOS33                                         }
    { jsbo_fire_n     N19   LVCMOS33                                         }
    { paddle[0]       H13   LVCMOS33                                         }
    { paddle[1]       G15   LVCMOS33                                         }
    { paddle[2]       J14   LVCMOS33                                         }
    { paddle[3]       J22   LVCMOS33                                         }
    { paddle_drain    H22   LVCMOS33                                         }
    { audio_pd_n      F18   LVCMOS33                                         }
    { audio_mclk      D16   LVCMOS33                                         }
    { audio_bclk      E19   LVCMOS33                                         }
    { audio_lrclk     F19   LVCMOS33                                         }
    { audio_sdata     E16   LVCMOS33                                         }
    { audio_smute     F4    LVCMOS33                                         }
    { audio_i2c_scl   L6    LVCMOS33                                         }
    { audio_i2c_sda   W9    LVCMOS33                                         }
    { hdmi_clk_p      W1    TMDS_33                                          }
    { hdmi_clk_n      Y1    TMDS_33                                          }
    { hdmi_data_p[0]  AA1   TMDS_33                                          }
    { hdmi_data_n[0]  AB1   TMDS_33                                          }
    { hdmi_data_p[1]  AB3   TMDS_33                                          }
    { hdmi_data_n[1]  AB2   TMDS_33                                          }
    { hdmi_data_p[2]  AA5   TMDS_33                                          }
    { hdmi_data_n[2]  AB5   TMDS_33                                          }
    { hdmi_hiz_en     M15   LVCMOS33                                         }
    { hdmi_hpd        Y8    LVCMOS33                                         }
    { hdmi_ls_oe_n    AB8   LVCMOS33                                         }
    { hdmi_scl        AB7   LVCMOS33                                         }
    { hdmi_sda        V9    LVCMOS33                                         }
    { vga_psave_n     W16   LVCMOS33                                         }
    { vga_clk         AA9   LVCMOS33                                         }
    { vga_vsync       V14   LVCMOS33                                         }
    { vga_hsync       W12   LVCMOS33                                         }
    { vga_sync_n      V10   LVCMOS33                                         }
    { vga_blank_n     W11   LVCMOS33                                         }
    { vga_r[0]        U15   LVCMOS33                                         }
    { vga_r[1]        V15   LVCMOS33                                         }
    { vga_r[2]        T14   LVCMOS33                                         }
    { vga_r[3]        Y17   LVCMOS33                                         }
    { vga_r[4]        Y16   LVCMOS33                                         }
    { vga_r[5]        AB17  LVCMOS33                                         }
    { vga_r[6]        AA16  LVCMOS33                                         }
    { vga_r[7]        AB16  LVCMOS33                                         }
    { vga_g[0]        Y14   LVCMOS33                                         }
    { vga_g[1]        W14   LVCMOS33                                         }
    { vga_g[2]        AA15  LVCMOS33                                         }
    { vga_g[3]        AB15  LVCMOS33                                         }
    { vga_g[4]        Y13   LVCMOS33                                         }
    { vga_g[5]        AA14  LVCMOS33                                         }
    { vga_g[6]        AA13  LVCMOS33                                         }
    { vga_g[7]        AB13  LVCMOS33                                         }
    { vga_b[0]        W10   LVCMOS33                                         }
    { vga_b[1]        Y12   LVCMOS33                                         }
    { vga_b[2]        AB12  LVCMOS33                                         }
    { vga_b[3]        AA11  LVCMOS33                                         }
    { vga_b[4]        AB11  LVCMOS33                                         }
    { vga_b[5]        Y11   LVCMOS33                                         }
    { vga_b[6]        AB10  LVCMOS33                                         }
    { vga_b[7]        AA10  LVCMOS33                                         }
    { vga_scl         W15   LVCMOS33                                         }
    { vga_sda         T15   LVCMOS33                                         }
    { fdd_chg_n       R1    LVCMOS33                                         }
    { fdd_wp_n        P2    LVCMOS33                                         }
    { fdd_den         P6    LVCMOS33                                         }
    { fdd_sela        N5    LVCMOS33                                         }
    { fdd_selb        G17   LVCMOS33                                         }
    { fdd_mota_n      M5    LVCMOS33                                         }
    { fdd_motb_n      H15   LVCMOS33                                         }
    { fdd_side_n      M1    LVCMOS33                                         }
    { fdd_dir_n       P5    LVCMOS33                                         }
    { fdd_step_n      M3    LVCMOS33                                         }
    { fdd_trk0_n      N2    LVCMOS33                                         }
    { fdd_idx_n       M2    LVCMOS33                                         }
    { fdd_wgate_n     N3    LVCMOS33                                         }
    { fdd_wdata       N4    LVCMOS33                                         }
    { fdd_rdata       P1    LVCMOS33                                         }
    { iec_rst_n       AB21  LVCMOS33                                         }
    { iec_atn_n       N17   LVCMOS33                                         }
    { iec_srq_n_en_n  AB20  LVCMOS33                                         }
    { iec_srq_n_o     U20   LVCMOS33                                         }
    { iec_srq_n_i     AA18  LVCMOS33                                         }
    { iec_clk_en_n    AA21  LVCMOS33                                         }
    { iec_clk_o       Y19   LVCMOS33                                         }
    { iec_clk_i       Y18   LVCMOS33                                         }
    { iec_data_en_n   Y21   LVCMOS33                                         }
    { iec_data_o      Y22   LVCMOS33                                         }
    { iec_data_i      AB22  LVCMOS33                                         }
    { eth_rst_n       K6    LVCMOS33                                         }
    { eth_clk         L4    LVCMOS33                     SLEW FAST           }
    { eth_txen        J4    LVCMOS33                                DRIVE  4 }
    { eth_txd[0]      L3    LVCMOS33                                DRIVE  4 }
    { eth_txd[1]      K3    LVCMOS33                                DRIVE  4 }
    { eth_rxdv        K4    LVCMOS33                                         }
    { eth_rxer        M6    LVCMOS33                                         }
    { eth_rxd[0]      P4    LVCMOS33                                         }
    { eth_rxd[1]      L1    LVCMOS33                                         }
    { eth_mdc         J6    LVCMOS33                                         }
    { eth_mdio        L5    LVCMOS33                                         }
    { eth_led_n       R14   LVCMOS33                                         }
    { cart_dotclk     AA19  LVCMOS33                                         }
    { cart_phi2       V17   LVCMOS33                                         }
    { cart_rst_n      N14   LVCMOS33                                         }
    { cart_dma_n      P15   LVCMOS33                                         }
    { cart_nmi_n      W17   LVCMOS33                                         }
    { cart_irq_n      P14   LVCMOS33                                         }
    { cart_ba         N13   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_r_w        R18   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_exrom_n    R19   LVCMOS33                                         }
    { cart_game_n     W22   LVCMOS33                                         }
    { cart_io1_n      N15   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_io2_n      AA20  LVCMOS33  PULLTYPE PULLUP                        }
    { cart_roml_n     AB18  LVCMOS33  PULLTYPE PULLUP                        }
    { cart_romh_n     T18   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[0]       K19   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[1]       K18   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[2]       K21   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[3]       M22   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[4]       L20   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[5]       J20   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[6]       J21   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[7]       K22   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[8]       H17   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[9]       H20   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[10]      G20   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[11]      J15   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[12]      H19   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[13]      M20   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[14]      N22   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_a[15]      H18   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_d[0]       P16   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_d[1]       R17   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_d[2]       P20   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_d[3]       R16   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_d[4]       U18   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_d[5]       V18   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_d[6]       W20   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_d[7]       W21   LVCMOS33  PULLTYPE PULLUP                        }
    { cart_ctrl_oe_n  G18   LVCMOS33                                         }
    { cart_ctrl_dir   U17   LVCMOS33                                         }
    { cart_addr_oe_n  L19   LVCMOS33                                         }
    { cart_laddr_dir  L21   LVCMOS33                                         }
    { cart_haddr_dir  L18   LVCMOS33                                         }
    { cart_data_oe_n  U21   LVCMOS33                                         }
    { cart_data_dir   V22   LVCMOS33                                         }
    { hr_rst_n        B22   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_clk_p        D22   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_cs_n         C22   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_rwds         B21   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_d[0]         A21   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_d[1]         D21   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_d[2]         C20   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_d[3]         A20   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_d[4]         B20   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_d[5]         A19   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_d[6]         E21   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { hr_d[7]         E22   LVCMOS33                     SLEW FAST  DRIVE 8  }
    { sdram_clk       V8    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_cke       U5    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_cs_n      G3    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_ras_n     T5    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_cas_n     V3    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_we_n      G1    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dqml      W2    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dqmh      Y6    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_ba[0]     U3    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_ba[1]     R4    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[0]      T4    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[1]      R2    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[2]      R3    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[3]      T3    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[4]      Y4    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[5]      W6    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[6]      W4    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[7]      U7    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[8]      AA8   LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[9]      Y2    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[10]     R6    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[11]     Y7    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_a[12]     Y9    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[0]     V5    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[1]     T1    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[2]     V4    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[3]     U2    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[4]     V2    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[5]     U1    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[6]     U6    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[7]     T6    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[8]     W7    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[9]     AA3   LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[10]    AA4   LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[11]    V7    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[12]    AA6   LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[13]    W5    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[14]    AB6   LVCMOS33                     SLEW FAST  DRIVE 16 }
    { sdram_dq[15]    Y3    LVCMOS33                     SLEW FAST  DRIVE 16 }
    { pmod1en         J16   LVCMOS33                                         }
    { pmod1flg        K16   LVCMOS33                                         }
    { pmod1lo[0]      F1    LVCMOS33                                         }
    { pmod1lo[1]      D1    LVCMOS33                                         }
    { pmod1lo[2]      B2    LVCMOS33                                         }
    { pmod1lo[3]      A1    LVCMOS33                                         }
    { pmod1hi[0]      A18   LVCMOS33                                         }
    { pmod1hi[1]      E1    LVCMOS33                                         }
    { pmod1hi[2]      C2    LVCMOS33                                         }
    { pmod1hi[3]      B1    LVCMOS33                                         }
    { pmod2en         M13   LVCMOS33                                         }
    { pmod2flg        K17   LVCMOS33                                         }
    { pmod2lo[0]      F3    LVCMOS33                                         }
    { pmod2lo[1]      E3    LVCMOS33                                         }
    { pmod2lo[2]      H4    LVCMOS33                                         }
    { pmod2lo[3]      H5    LVCMOS33                                         }
    { pmod2hi[0]      E2    LVCMOS33                                         }
    { pmod2hi[1]      D2    LVCMOS33                                         }
    { pmod2hi[2]      G4    LVCMOS33                                         }
    { pmod2hi[3]      J5    LVCMOS33                                         }
    { dbg[10]         H14   LVCMOS33                                         }
    { dbg[11]         G13   LVCMOS33                                         }
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
    } else {
        puts "$argv0: port $name not in design"
    }
}

if {[llength [get_ports clk_in]]} {
    create_clock -period 10.000 -name clk_in [get_ports clk_in]
}

set_property CONFIG_VOLTAGE                  3.3   [current_design]
set_property CFGBVS                          VCCO  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS      TRUE  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE     66    [current_design]
set_property CONFIG_MODE                     SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH   4     [current_design]
