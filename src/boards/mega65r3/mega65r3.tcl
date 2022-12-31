################################################################################
## mega65r3.tcl                                                               ##
## Physical constraints for the MEGA65 rev 3.                                 ##
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

create_clock -period 10.000 -name clk_in [get_ports clk_in]

if {[llength [get_ports { clk_in           }]]} {set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33                                    } [get_ports { clk_in           }] } ;# clock intput (100MHz)
if {[llength [get_ports { max10_clk        }]]} {set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33                                    } [get_ports { max10_clk        }] } ;#
if {[llength [get_ports { max10_tx         }]]} {set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33                                    } [get_ports { max10_tx         }] } ;# Interface to MAX10
if {[llength [get_ports { max10_rx         }]]} {set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33                                    } [get_ports { max10_rx         }] } ;#
if {[llength [get_ports { led              }]]} {set_property -dict { PACKAGE_PIN U22   IOSTANDARD LVCMOS33                                    } [get_ports { led              }] } ;# user LED
if {[llength [get_ports { uart_rx          }]]} {set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33                                    } [get_ports { uart_rx          }] } ;#
if {[llength [get_ports { uart_tx          }]]} {set_property -dict { PACKAGE_PIN L13   IOSTANDARD LVCMOS33                                    } [get_ports { uart_tx          }] } ;# USB serial
if {[llength [get_ports { kb_io0           }]]} {set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33                                    } [get_ports { kb_io0           }] } ;#
if {[llength [get_ports { kb_io1           }]]} {set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS33                                    } [get_ports { kb_io1           }] } ;#
if {[llength [get_ports { kb_io2           }]]} {set_property -dict { PACKAGE_PIN C13   IOSTANDARD LVCMOS33                                    } [get_ports { kb_io2           }] } ;#
if {[llength [get_ports { kb_jtagen        }]]} {set_property -dict { PACKAGE_PIN B13   IOSTANDARD LVCMOS33                                    } [get_ports { kb_jtagen        }] } ;#
if {[llength [get_ports { kb_tck           }]]} {set_property -dict { PACKAGE_PIN E13   IOSTANDARD LVCMOS33                                    } [get_ports { kb_tck           }] } ;# C65 keyboard
if {[llength [get_ports { kb_tms           }]]} {set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33                                    } [get_ports { kb_tms           }] } ;#
if {[llength [get_ports { kb_tdi           }]]} {set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS33                                    } [get_ports { kb_tdi           }] } ;#
if {[llength [get_ports { kb_tdo           }]]} {set_property -dict { PACKAGE_PIN E14   IOSTANDARD LVCMOS33                                    } [get_ports { kb_tdo           }] } ;#
if {[llength [get_ports { jsa_left_n       }]]} {set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33                                    } [get_ports { jsa_left_n       }] } ;# joystick A
if {[llength [get_ports { jsa_right_n      }]]} {set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS33                                    } [get_ports { jsa_right_n      }] } ;#
if {[llength [get_ports { jsa_up_n         }]]} {set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33                                    } [get_ports { jsa_up_n         }] } ;#
if {[llength [get_ports { jsa_down_n       }]]} {set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33                                    } [get_ports { jsa_down_n       }] } ;#
if {[llength [get_ports { jsa_fire_n       }]]} {set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33                                    } [get_ports { jsa_fire_n       }] } ;#
if {[llength [get_ports { jsb_left_n       }]]} {set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33                                    } [get_ports { jsb_left_n       }] } ;# joystick B
if {[llength [get_ports { jsb_right_n      }]]} {set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33                                    } [get_ports { jsb_right_n      }] } ;#
if {[llength [get_ports { jsb_up_n         }]]} {set_property -dict { PACKAGE_PIN F21   IOSTANDARD LVCMOS33                                    } [get_ports { jsb_up_n         }] } ;#
if {[llength [get_ports { jsb_down_n       }]]} {set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33                                    } [get_ports { jsb_down_n       }] } ;#
if {[llength [get_ports { jsb_fire_n       }]]} {set_property -dict { PACKAGE_PIN F15   IOSTANDARD LVCMOS33                                    } [get_ports { jsb_fire_n       }] } ;#
if {[llength [get_ports { paddle[0]        }]]} {set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33                                    } [get_ports { paddle[0]        }] } ;# paddles
if {[llength [get_ports { paddle[1]        }]]} {set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33                                    } [get_ports { paddle[1]        }] } ;#
if {[llength [get_ports { paddle[2]        }]]} {set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33                                    } [get_ports { paddle[2]        }] } ;#
if {[llength [get_ports { paddle[3]        }]]} {set_property -dict { PACKAGE_PIN J22   IOSTANDARD LVCMOS33                                    } [get_ports { paddle[3]        }] } ;#
if {[llength [get_ports { paddle_drain     }]]} {set_property -dict { PACKAGE_PIN H22   IOSTANDARD LVCMOS33                                    } [get_ports { paddle_drain     }] } ;#
if {[llength [get_ports { i2c_scl          }]]} {set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33                                    } [get_ports { i2c_scl          }] } ;# on-board I2C
if {[llength [get_ports { i2c_sda          }]]} {set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33                                    } [get_ports { i2c_sda          }] } ;#
if {[llength [get_ports { grove_scl        }]]} {set_property -dict { PACKAGE_PIN G21   IOSTANDARD LVCMOS33                                    } [get_ports { grove_scl        }] } ;# Grove I2C
if {[llength [get_ports { grove_sda        }]]} {set_property -dict { PACKAGE_PIN G22   IOSTANDARD LVCMOS33                                    } [get_ports { grove_sda        }] } ;#
if {[llength [get_ports { sd_cd_n          }]]} {set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33                                    } [get_ports { sd_cd_n          }] } ;# SD/MMC card
if {[llength [get_ports { sd_wp_n          }]]} {set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33                                    } [get_ports { sd_wp_n          }] } ;#
if {[llength [get_ports { sd_ss_n          }]]} {set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33                                    } [get_ports { sd_ss_n          }] } ;#
if {[llength [get_ports { sd_clk           }]]} {set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS33                                    } [get_ports { sd_clk           }] } ;#
if {[llength [get_ports { sd_mosi          }]]} {set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33                                    } [get_ports { sd_mosi          }] } ;#
if {[llength [get_ports { sd_miso          }]]} {set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33                                    } [get_ports { sd_miso          }] } ;#
if {[llength [get_ports { sd_dat[0]        }]]} {set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33                                    } [get_ports { sd_dat[0]        }] } ;#
if {[llength [get_ports { sd_dat[1]        }]]} {set_property -dict { PACKAGE_PIN C18   IOSTANDARD LVCMOS33                                    } [get_ports { sd_dat[1]        }] } ;#
if {[llength [get_ports { sd_dat[2]        }]]} {set_property -dict { PACKAGE_PIN C19   IOSTANDARD LVCMOS33                                    } [get_ports { sd_dat[2]        }] } ;#
if {[llength [get_ports { sd_dat[3]        }]]} {set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33                                    } [get_ports { sd_dat[3]        }] } ;#
if {[llength [get_ports { sd2_cd_n         }]]} {set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_cd_n         }] } ;# micro SD card
if {[llength [get_ports { sd2_ss_n         }]]} {set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_ss_n         }] } ;#
if {[llength [get_ports { sd2_clk          }]]} {set_property -dict { PACKAGE_PIN G2    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_clk          }] } ;#
if {[llength [get_ports { sd2_mosi         }]]} {set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_mosi         }] } ;#
if {[llength [get_ports { sd2_miso         }]]} {set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_miso         }] } ;#
if {[llength [get_ports { sd2_dat[0]       }]]} {set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_dat[0]       }] } ;#
if {[llength [get_ports { sd2_dat[1]       }]]} {set_property -dict { PACKAGE_PIN H3    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_dat[1]       }] } ;#
if {[llength [get_ports { sd2_dat[2]       }]]} {set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_dat[2]       }] } ;#
if {[llength [get_ports { sd2_dat[3]       }]]} {set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33                                    } [get_ports { sd2_dat[3]       }] } ;#
if {[llength [get_ports { vga_clk          }]]} {set_property -dict { PACKAGE_PIN AA9   IOSTANDARD LVCMOS33                                    } [get_ports { vga_clk          }] } ;# VGA out
if {[llength [get_ports { vga_sync_n       }]]} {set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33                                    } [get_ports { vga_sync_n       }] } ;#
if {[llength [get_ports { vga_blank_n      }]]} {set_property -dict { PACKAGE_PIN W11   IOSTANDARD LVCMOS33                                    } [get_ports { vga_blank_n      }] } ;#
if {[llength [get_ports { vga_vsync        }]]} {set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33                                    } [get_ports { vga_vsync        }] } ;#
if {[llength [get_ports { vga_hsync        }]]} {set_property -dict { PACKAGE_PIN W12   IOSTANDARD LVCMOS33                                    } [get_ports { vga_hsync        }] } ;#
if {[llength [get_ports { vga_r[0]         }]]} {set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33                                    } [get_ports { vga_r[0]         }] } ;#
if {[llength [get_ports { vga_r[1]         }]]} {set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33                                    } [get_ports { vga_r[1]         }] } ;#
if {[llength [get_ports { vga_r[2]         }]]} {set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33                                    } [get_ports { vga_r[2]         }] } ;#
if {[llength [get_ports { vga_r[3]         }]]} {set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33                                    } [get_ports { vga_r[3]         }] } ;#
if {[llength [get_ports { vga_r[4]         }]]} {set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33                                    } [get_ports { vga_r[4]         }] } ;#
if {[llength [get_ports { vga_r[5]         }]]} {set_property -dict { PACKAGE_PIN AB17  IOSTANDARD LVCMOS33                                    } [get_ports { vga_r[5]         }] } ;#
if {[llength [get_ports { vga_r[6]         }]]} {set_property -dict { PACKAGE_PIN AA16  IOSTANDARD LVCMOS33                                    } [get_ports { vga_r[6]         }] } ;#
if {[llength [get_ports { vga_r[7]         }]]} {set_property -dict { PACKAGE_PIN AB16  IOSTANDARD LVCMOS33                                    } [get_ports { vga_r[7]         }] } ;#
if {[llength [get_ports { vga_g[0]         }]]} {set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33                                    } [get_ports { vga_g[0]         }] } ;#
if {[llength [get_ports { vga_g[1]         }]]} {set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33                                    } [get_ports { vga_g[1]         }] } ;#
if {[llength [get_ports { vga_g[2]         }]]} {set_property -dict { PACKAGE_PIN AA15  IOSTANDARD LVCMOS33                                    } [get_ports { vga_g[2]         }] } ;#
if {[llength [get_ports { vga_g[3]         }]]} {set_property -dict { PACKAGE_PIN AB15  IOSTANDARD LVCMOS33                                    } [get_ports { vga_g[3]         }] } ;#
if {[llength [get_ports { vga_g[4]         }]]} {set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS33                                    } [get_ports { vga_g[4]         }] } ;#
if {[llength [get_ports { vga_g[5]         }]]} {set_property -dict { PACKAGE_PIN AA14  IOSTANDARD LVCMOS33                                    } [get_ports { vga_g[5]         }] } ;#
if {[llength [get_ports { vga_g[6]         }]]} {set_property -dict { PACKAGE_PIN AA13  IOSTANDARD LVCMOS33                                    } [get_ports { vga_g[6]         }] } ;#
if {[llength [get_ports { vga_g[7]         }]]} {set_property -dict { PACKAGE_PIN AB13  IOSTANDARD LVCMOS33                                    } [get_ports { vga_g[7]         }] } ;#
if {[llength [get_ports { vga_b[0]         }]]} {set_property -dict { PACKAGE_PIN W10   IOSTANDARD LVCMOS33                                    } [get_ports { vga_b[0]         }] } ;#
if {[llength [get_ports { vga_b[1]         }]]} {set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS33                                    } [get_ports { vga_b[1]         }] } ;#
if {[llength [get_ports { vga_b[2]         }]]} {set_property -dict { PACKAGE_PIN AB12  IOSTANDARD LVCMOS33                                    } [get_ports { vga_b[2]         }] } ;#
if {[llength [get_ports { vga_b[3]         }]]} {set_property -dict { PACKAGE_PIN AA11  IOSTANDARD LVCMOS33                                    } [get_ports { vga_b[3]         }] } ;#
if {[llength [get_ports { vga_b[4]         }]]} {set_property -dict { PACKAGE_PIN AB11  IOSTANDARD LVCMOS33                                    } [get_ports { vga_b[4]         }] } ;#
if {[llength [get_ports { vga_b[5]         }]]} {set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33                                    } [get_ports { vga_b[5]         }] } ;#
if {[llength [get_ports { vga_b[6]         }]]} {set_property -dict { PACKAGE_PIN AB10  IOSTANDARD LVCMOS33                                    } [get_ports { vga_b[6]         }] } ;#
if {[llength [get_ports { vga_b[7]         }]]} {set_property -dict { PACKAGE_PIN AA10  IOSTANDARD LVCMOS33                                    } [get_ports { vga_b[7]         }] } ;#
if {[llength [get_ports { hdmi_clk_n       }]]} {set_property -dict { PACKAGE_PIN Y1    IOSTANDARD TMDS_33                                     } [get_ports { hdmi_clk_n       }] } ;# HDMI out
if {[llength [get_ports { hdmi_clk_p       }]]} {set_property -dict { PACKAGE_PIN W1    IOSTANDARD TMDS_33                                     } [get_ports { hdmi_clk_p       }] } ;#
if {[llength [get_ports { hdmi_data_n[0]   }]]} {set_property -dict { PACKAGE_PIN AB1   IOSTANDARD TMDS_33                                     } [get_ports { hdmi_data_n[0]   }] } ;#
if {[llength [get_ports { hdmi_data_p[0]   }]]} {set_property -dict { PACKAGE_PIN AA1   IOSTANDARD TMDS_33                                     } [get_ports { hdmi_data_p[0]   }] } ;#
if {[llength [get_ports { hdmi_data_n[1]   }]]} {set_property -dict { PACKAGE_PIN AB2   IOSTANDARD TMDS_33                                     } [get_ports { hdmi_data_n[1]   }] } ;#
if {[llength [get_ports { hdmi_data_p[1]   }]]} {set_property -dict { PACKAGE_PIN AB3   IOSTANDARD TMDS_33                                     } [get_ports { hdmi_data_p[1]   }] } ;#
if {[llength [get_ports { hdmi_data_n[2]   }]]} {set_property -dict { PACKAGE_PIN AB5   IOSTANDARD TMDS_33                                     } [get_ports { hdmi_data_n[2]   }] } ;#
if {[llength [get_ports { hdmi_data_p[2]   }]]} {set_property -dict { PACKAGE_PIN AA5   IOSTANDARD TMDS_33                                     } [get_ports { hdmi_data_p[2]   }] } ;#
if {[llength [get_ports { hdmi_ct_hpd      }]]} {set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33                                    } [get_ports { hdmi_ct_hpd      }] } ;#
if {[llength [get_ports { hdmi_hpd         }]]} {set_property -dict { PACKAGE_PIN Y8    IOSTANDARD LVCMOS33                                    } [get_ports { hdmi_hpd         }] } ;#
if {[llength [get_ports { hdmi_ls_oe       }]]} {set_property -dict { PACKAGE_PIN AB8   IOSTANDARD LVCMOS33                                    } [get_ports { hdmi_ls_oe       }] } ;#
if {[llength [get_ports { hdmi_cec         }]]} {set_property -dict { PACKAGE_PIN W9    IOSTANDARD LVCMOS33                                    } [get_ports { hdmi_cec         }] } ;#
if {[llength [get_ports { hdmi_scl         }]]} {set_property -dict { PACKAGE_PIN AB7   IOSTANDARD LVCMOS33                                    } [get_ports { hdmi_scl         }] } ;#
if {[llength [get_ports { hdmi_sda         }]]} {set_property -dict { PACKAGE_PIN V9    IOSTANDARD LVCMOS33                                    } [get_ports { hdmi_sda         }] } ;#
if {[llength [get_ports { pwm_l            }]]} {set_property -dict { PACKAGE_PIN L6    IOSTANDARD LVCMOS33                                    } [get_ports { pwm_l            }] } ;# PWM audio
if {[llength [get_ports { pwm_r            }]]} {set_property -dict { PACKAGE_PIN F4    IOSTANDARD LVCMOS33                                    } [get_ports { pwm_r            }] } ;#
if {[llength [get_ports { i2s_sd_n         }]]} {set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33                                    } [get_ports { i2s_sd_n          }] } ;# I2S audio
if {[llength [get_ports { i2s_mclk         }]]} {set_property -dict { PACKAGE_PIN D16   IOSTANDARD LVCMOS33                                    } [get_ports { i2s_mclk         }] } ;#
if {[llength [get_ports { i2s_bclk         }]]} {set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33                                    } [get_ports { i2s_bclk         }] } ;#
if {[llength [get_ports { i2s_sync         }]]} {set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33                                    } [get_ports { i2s_sync         }] } ;#
if {[llength [get_ports { i2s_sdata        }]]} {set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33                                    } [get_ports { i2s_sdata        }] } ;#
if {[llength [get_ports { hr_rst_n         }]]} {set_property -dict { PACKAGE_PIN B22   IOSTANDARD LVCMOS33  PULLUP FALSE                      } [get_ports { hr_rst_n         }] } ;# HyperRAM
if {[llength [get_ports { hr_clk_p         }]]} {set_property -dict { PACKAGE_PIN D22   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_clk_p         }] } ;#
if {[llength [get_ports { hr_cs_n          }]]} {set_property -dict { PACKAGE_PIN C22   IOSTANDARD LVCMOS33  PULLUP FALSE                      } [get_ports { hr_cs_n          }] } ;#
if {[llength [get_ports { hr_rwds          }]]} {set_property -dict { PACKAGE_PIN B21   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_rwds          }] } ;#
if {[llength [get_ports { hr_d[0]          }]]} {set_property -dict { PACKAGE_PIN A21   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_d[0]          }] } ;#
if {[llength [get_ports { hr_d[1]          }]]} {set_property -dict { PACKAGE_PIN D21   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_d[1]          }] } ;#
if {[llength [get_ports { hr_d[2]          }]]} {set_property -dict { PACKAGE_PIN C20   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_d[2]          }] } ;#
if {[llength [get_ports { hr_d[3]          }]]} {set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_d[3]          }] } ;#
if {[llength [get_ports { hr_d[4]          }]]} {set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_d[4]          }] } ;#
if {[llength [get_ports { hr_d[5]          }]]} {set_property -dict { PACKAGE_PIN A19   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_d[5]          }] } ;#
if {[llength [get_ports { hr_d[6]          }]]} {set_property -dict { PACKAGE_PIN E21   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_d[6]          }] } ;#
if {[llength [get_ports { hr_d[7]          }]]} {set_property -dict { PACKAGE_PIN E22   IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hr_d[7]          }] } ;#
if {[llength [get_ports { hrx_rst_n        }]]} {set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33  PULLUP FALSE                      } [get_ports { hrx_rst_n        }] } ;# external HyperRAM on trap-door PMOD
if {[llength [get_ports { hrx_clk_p        }]]} {set_property -dict { PACKAGE_PIN G1    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_clk_p        }] } ;#
if {[llength [get_ports { hrx_clk_n        }]]} {set_property -dict { PACKAGE_PIN F1    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_clk_n        }] } ;#
if {[llength [get_ports { hrx_cs_n         }]]} {set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33  PULLUP FALSE                      } [get_ports { hrx_cs_n         }] } ;# see: https://github.com/blackmesalabs/hyperram
if {[llength [get_ports { hrx_rwds         }]]} {set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_rwds         }] } ;#
if {[llength [get_ports { hrx_d[0]         }]]} {set_property -dict { PACKAGE_PIN B2    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_d[0]         }] } ;#
if {[llength [get_ports { hrx_d[1]         }]]} {set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_d[1]         }] } ;#
if {[llength [get_ports { hrx_d[2]         }]]} {set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_d[2]         }] } ;#
if {[llength [get_ports { hrx_d[3]         }]]} {set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_d[3]         }] } ;#
if {[llength [get_ports { hrx_d[4]         }]]} {set_property -dict { PACKAGE_PIN D2    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_d[4]         }] } ;#
if {[llength [get_ports { hrx_d[5]         }]]} {set_property -dict { PACKAGE_PIN B1    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_d[5]         }] } ;#
if {[llength [get_ports { hrx_d[6]         }]]} {set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_d[6]         }] } ;#
if {[llength [get_ports { hrx_d[7]         }]]} {set_property -dict { PACKAGE_PIN D1    IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16 } [get_ports { hrx_d[7]         }] } ;#
if {[llength [get_ports { fdd_density      }]]} {set_property -dict { PACKAGE_PIN P6    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_density      }] } ;# FDC outputs
if {[llength [get_ports { fdd_motora       }]]} {set_property -dict { PACKAGE_PIN M5    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_motora       }] } ;#
if {[llength [get_ports { fdd_motorb       }]]} {set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33                                    } [get_ports { fdd_motorb       }] } ;#
if {[llength [get_ports { fdd_selecta      }]]} {set_property -dict { PACKAGE_PIN N5    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_selecta      }] } ;#
if {[llength [get_ports { fdd_selectb      }]]} {set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33                                    } [get_ports { fdd_selectb      }] } ;#
if {[llength [get_ports { fdd_stepdir      }]]} {set_property -dict { PACKAGE_PIN P5    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_stepdir      }] } ;#
if {[llength [get_ports { fdd_step         }]]} {set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_step         }] } ;#
if {[llength [get_ports { fdd_wdata        }]]} {set_property -dict { PACKAGE_PIN N4    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_wdata        }] } ;#
if {[llength [get_ports { fdd_wgate        }]]} {set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_wgate        }] } ;#
if {[llength [get_ports { fdd_side1        }]]} {set_property -dict { PACKAGE_PIN M1    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_side1        }] } ;#
if {[llength [get_ports { fdd_index        }]]} {set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_index        }] } ;# FDC inputs
if {[llength [get_ports { fdd_track0       }]]} {set_property -dict { PACKAGE_PIN N2    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_track0       }] } ;#
if {[llength [get_ports { fdd_writeprotect }]]} {set_property -dict { PACKAGE_PIN P2    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_writeprotect }] } ;#
if {[llength [get_ports { fdd_rdata        }]]} {set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_rdata        }] } ;#
if {[llength [get_ports { fdd_diskchanged  }]]} {set_property -dict { PACKAGE_PIN R1    IOSTANDARD LVCMOS33                                    } [get_ports { fdd_diskchanged  }] } ;#
if {[llength [get_ports { iec_rst_n        }]]} {set_property -dict { PACKAGE_PIN AB21  IOSTANDARD LVCMOS33                                    } [get_ports { iec_rst_n        }] } ;# CBM-488/IEC serial port
if {[llength [get_ports { iec_atn_n        }]]} {set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33                                    } [get_ports { iec_atn_n        }] } ;#
if {[llength [get_ports { iec_srq_n_en     }]]} {set_property -dict { PACKAGE_PIN AB20  IOSTANDARD LVCMOS33                                    } [get_ports { iec_srq_n_en     }] } ;#
if {[llength [get_ports { iec_srq_n_o      }]]} {set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33                                    } [get_ports { iec_srq_n_o      }] } ;#
if {[llength [get_ports { iec_srq_n_i      }]]} {set_property -dict { PACKAGE_PIN AA18  IOSTANDARD LVCMOS33                                    } [get_ports { iec_srq_n_i      }] } ;#
if {[llength [get_ports { iec_clk_en       }]]} {set_property -dict { PACKAGE_PIN AA21  IOSTANDARD LVCMOS33                                    } [get_ports { iec_clk_en       }] } ;#
if {[llength [get_ports { iec_clk_o        }]]} {set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33                                    } [get_ports { iec_clk_o        }] } ;#
if {[llength [get_ports { iec_clk_i        }]]} {set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33  PULLUP TRUE                       } [get_ports { iec_clk_i        }] } ;#
if {[llength [get_ports { iec_data_en      }]]} {set_property -dict { PACKAGE_PIN Y21   IOSTANDARD LVCMOS33                                    } [get_ports { iec_data_en      }] } ;#
if {[llength [get_ports { iec_data_o       }]]} {set_property -dict { PACKAGE_PIN Y22   IOSTANDARD LVCMOS33                                    } [get_ports { iec_data_o       }] } ;#
if {[llength [get_ports { iec_data_i       }]]} {set_property -dict { PACKAGE_PIN AB22  IOSTANDARD LVCMOS33  PULLUP TRUE                       } [get_ports { iec_data_i       }] } ;#
if {[llength [get_ports { eth_rst_n        }]]} {set_property -dict { PACKAGE_PIN K6    IOSTANDARD LVCMOS33                                    } [get_ports { eth_rst_n        }] } ;# SMSC ethernet PHY (RMII)
if {[llength [get_ports { eth_clk          }]]} {set_property -dict { PACKAGE_PIN L4    IOSTANDARD LVCMOS33                SLEW FAST           } [get_ports { eth_clk          }] } ;#
if {[llength [get_ports { eth_txen         }]]} {set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33                SLEW SLOW  DRIVE 4  } [get_ports { eth_txen         }] } ;#
if {[llength [get_ports { eth_txd[0]       }]]} {set_property -dict { PACKAGE_PIN L3    IOSTANDARD LVCMOS33                SLEW SLOW  DRIVE 4  } [get_ports { eth_txd[0]       }] } ;#
if {[llength [get_ports { eth_txd[1]       }]]} {set_property -dict { PACKAGE_PIN K3    IOSTANDARD LVCMOS33                SLEW SLOW  DRIVE 4  } [get_ports { eth_txd[1]       }] } ;#
if {[llength [get_ports { eth_rxdv         }]]} {set_property -dict { PACKAGE_PIN K4    IOSTANDARD LVCMOS33                                    } [get_ports { eth_rxdv         }] } ;#
if {[llength [get_ports { eth_rxd[0]       }]]} {set_property -dict { PACKAGE_PIN P4    IOSTANDARD LVCMOS33                                    } [get_ports { eth_rxd[0]       }] } ;#
if {[llength [get_ports { eth_rxd[1]       }]]} {set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33                                    } [get_ports { eth_rxd[1]       }] } ;#
if {[llength [get_ports { eth_rxer         }]]} {set_property -dict { PACKAGE_PIN M6    IOSTANDARD LVCMOS33                                    } [get_ports { eth_rxer         }] } ;#
if {[llength [get_ports { eth_mdc          }]]} {set_property -dict { PACKAGE_PIN J6    IOSTANDARD LVCMOS33                                    } [get_ports { eth_mdc          }] } ;#
if {[llength [get_ports { eth_mdio         }]]} {set_property -dict { PACKAGE_PIN L5    IOSTANDARD LVCMOS33                                    } [get_ports { eth_mdio         }] } ;#
if {[llength [get_ports { eth_led_n[1]     }]]} {set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33                                    } [get_ports { eth_led_n[1]     }] } ;#
if {[llength [get_ports { cart_ctrl_oe_n   }]]} {set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33                                    } [get_ports { cart_ctrl_oe_n   }] } ;# *_dir=1 means FPGA->Port, =0 means Port->FPGA
if {[llength [get_ports { cart_ctrl_dir    }]]} {set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33                                    } [get_ports { cart_ctrl_dir    }] } ;# C64 cartridge port control lines
if {[llength [get_ports { cart_addr_oe_n   }]]} {set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33                                    } [get_ports { cart_addr_oe_n   }] } ;#
if {[llength [get_ports { cart_laddr_dir   }]]} {set_property -dict { PACKAGE_PIN L21   IOSTANDARD LVCMOS33                                    } [get_ports { cart_laddr_dir   }] } ;#
if {[llength [get_ports { cart_haddr_dir   }]]} {set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33                                    } [get_ports { cart_haddr_dir   }] } ;#
if {[llength [get_ports { cart_data_oe_n   }]]} {set_property -dict { PACKAGE_PIN U21   IOSTANDARD LVCMOS33                                    } [get_ports { cart_data_oe_n   }] } ;#
if {[llength [get_ports { cart_data_dir    }]]} {set_property -dict { PACKAGE_PIN V22   IOSTANDARD LVCMOS33                                    } [get_ports { cart_data_dir    }] } ;#
if {[llength [get_ports { cart_phi2        }]]} {set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33                                    } [get_ports { cart_phi2        }] } ;# C64 cartridge port
if {[llength [get_ports { cart_dotclk      }]]} {set_property -dict { PACKAGE_PIN AA19  IOSTANDARD LVCMOS33                                    } [get_ports { cart_dotclk      }] } ;#
if {[llength [get_ports { cart_rst_n       }]]} {set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33                                    } [get_ports { cart_rst_n       }] } ;#
if {[llength [get_ports { cart_nmi_n       }]]} {set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33                                    } [get_ports { cart_nmi_n       }] } ;#
if {[llength [get_ports { cart_irq_n       }]]} {set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33                                    } [get_ports { cart_irq_n       }] } ;#
if {[llength [get_ports { cart_dma_n       }]]} {set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33                                    } [get_ports { cart_dma_n       }] } ;#
if {[llength [get_ports { cart_exrom_n     }]]} {set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33                                    } [get_ports { cart_exrom_n     }] } ;#
if {[llength [get_ports { cart_ba          }]]} {set_property -dict { PACKAGE_PIN N13   IOSTANDARD LVCMOS33                                    } [get_ports { cart_ba          }] } ;#
if {[llength [get_ports { cart_r_w         }]]} {set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33                                    } [get_ports { cart_r_w         }] } ;#
if {[llength [get_ports { cart_roml_n      }]]} {set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS33                                    } [get_ports { cart_roml_n      }] } ;#
if {[llength [get_ports { cart_romh_n      }]]} {set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33                                    } [get_ports { cart_romh_n      }] } ;#
if {[llength [get_ports { cart_game_n      }]]} {set_property -dict { PACKAGE_PIN W22   IOSTANDARD LVCMOS33                                    } [get_ports { cart_game_n      }] } ;#
if {[llength [get_ports { cart_io1_n       }]]} {set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33                                    } [get_ports { cart_io1_n       }] } ;#
if {[llength [get_ports { cart_io2_n       }]]} {set_property -dict { PACKAGE_PIN AA20  IOSTANDARD LVCMOS33                                    } [get_ports { cart_io2_n       }] } ;#
if {[llength [get_ports { cart_a[0]        }]]} {set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[0]        }] } ;#
if {[llength [get_ports { cart_a[1]        }]]} {set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[1]        }] } ;#
if {[llength [get_ports { cart_a[2]        }]]} {set_property -dict { PACKAGE_PIN K21   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[2]        }] } ;#
if {[llength [get_ports { cart_a[3]        }]]} {set_property -dict { PACKAGE_PIN M22   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[3]        }] } ;#
if {[llength [get_ports { cart_a[4]        }]]} {set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[4]        }] } ;#
if {[llength [get_ports { cart_a[5]        }]]} {set_property -dict { PACKAGE_PIN J20   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[5]        }] } ;#
if {[llength [get_ports { cart_a[6]        }]]} {set_property -dict { PACKAGE_PIN J21   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[6]        }] } ;#
if {[llength [get_ports { cart_a[7]        }]]} {set_property -dict { PACKAGE_PIN K22   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[7]        }] } ;#
if {[llength [get_ports { cart_a[8]        }]]} {set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[8]        }] } ;#
if {[llength [get_ports { cart_a[9]        }]]} {set_property -dict { PACKAGE_PIN H20   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[9]        }] } ;#
if {[llength [get_ports { cart_a[10]       }]]} {set_property -dict { PACKAGE_PIN G20   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[10]       }] } ;#
if {[llength [get_ports { cart_a[11]       }]]} {set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[11]       }] } ;#
if {[llength [get_ports { cart_a[12]       }]]} {set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[12]       }] } ;#
if {[llength [get_ports { cart_a[13]       }]]} {set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[13]       }] } ;#
if {[llength [get_ports { cart_a[14]       }]]} {set_property -dict { PACKAGE_PIN N22   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[14]       }] } ;#
if {[llength [get_ports { cart_a[15]       }]]} {set_property -dict { PACKAGE_PIN H18   IOSTANDARD LVCMOS33                                    } [get_ports { cart_a[15]       }] } ;#
if {[llength [get_ports { cart_d[0]        }]]} {set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33                                    } [get_ports { cart_d[0]        }] } ;#
if {[llength [get_ports { cart_d[1]        }]]} {set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33                                    } [get_ports { cart_d[1]        }] } ;#
if {[llength [get_ports { cart_d[2]        }]]} {set_property -dict { PACKAGE_PIN P20   IOSTANDARD LVCMOS33                                    } [get_ports { cart_d[2]        }] } ;#
if {[llength [get_ports { cart_d[3]        }]]} {set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33                                    } [get_ports { cart_d[3]        }] } ;#
if {[llength [get_ports { cart_d[4]        }]]} {set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33                                    } [get_ports { cart_d[4]        }] } ;#
if {[llength [get_ports { cart_d[5]        }]]} {set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33                                    } [get_ports { cart_d[5]        }] } ;#
if {[llength [get_ports { cart_d[6]        }]]} {set_property -dict { PACKAGE_PIN W20   IOSTANDARD LVCMOS33                                    } [get_ports { cart_d[6]        }] } ;#
if {[llength [get_ports { cart_d[7]        }]]} {set_property -dict { PACKAGE_PIN W21   IOSTANDARD LVCMOS33                                    } [get_ports { cart_d[7]        }] } ;#
if {[llength [get_ports { pmod1lo[0]       }]]} {set_property -dict { PACKAGE_PIN F1    IOSTANDARD LVCMOS33                                    } [get_ports { pmod1lo[0]       }] } ;# Pmod Header P1
if {[llength [get_ports { pmod1lo[1]       }]]} {set_property -dict { PACKAGE_PIN D1    IOSTANDARD LVCMOS33                                    } [get_ports { pmod1lo[1]       }] } ;#
if {[llength [get_ports { pmod1lo[2]       }]]} {set_property -dict { PACKAGE_PIN B2    IOSTANDARD LVCMOS33                                    } [get_ports { pmod1lo[2]       }] } ;#
if {[llength [get_ports { pmod1lo[3]       }]]} {set_property -dict { PACKAGE_PIN A1    IOSTANDARD LVCMOS33                                    } [get_ports { pmod1lo[3]       }] } ;#
if {[llength [get_ports { pmod1hi[0]       }]]} {set_property -dict { PACKAGE_PIN G1    IOSTANDARD LVCMOS33                                    } [get_ports { pmod1hi[0]       }] } ;#
if {[llength [get_ports { pmod1hi[1]       }]]} {set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33                                    } [get_ports { pmod1hi[1]       }] } ;#
if {[llength [get_ports { pmod1hi[2]       }]]} {set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33                                    } [get_ports { pmod1hi[2]       }] } ;#
if {[llength [get_ports { pmod1hi[3]       }]]} {set_property -dict { PACKAGE_PIN B1    IOSTANDARD LVCMOS33                                    } [get_ports { pmod1hi[3]       }] } ;#
if {[llength [get_ports { pmod2lo[0]       }]]} {set_property -dict { PACKAGE_PIN F3    IOSTANDARD LVCMOS33                                    } [get_ports { pmod2lo[0]       }] } ;# Pmod Header P2
if {[llength [get_ports { pmod2lo[1]       }]]} {set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33                                    } [get_ports { pmod2lo[1]       }] } ;#
if {[llength [get_ports { pmod2lo[2]       }]]} {set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33                                    } [get_ports { pmod2lo[2]       }] } ;#
if {[llength [get_ports { pmod2lo[3]       }]]} {set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33                                    } [get_ports { pmod2lo[3]       }] } ;#
if {[llength [get_ports { pmod2hi[0]       }]]} {set_property -dict { PACKAGE_PIN E2    IOSTANDARD LVCMOS33                                    } [get_ports { pmod2hi[0]       }] } ;#
if {[llength [get_ports { pmod2hi[1]       }]]} {set_property -dict { PACKAGE_PIN D2    IOSTANDARD LVCMOS33                                    } [get_ports { pmod2hi[1]       }] } ;#
if {[llength [get_ports { pmod2hi[2]       }]]} {set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33                                    } [get_ports { pmod2hi[2]       }] } ;#
if {[llength [get_ports { pmod2hi[3]       }]]} {set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33                                    } [get_ports { pmod2hi[3]       }] } ;#
if {[llength [get_ports { tp[1]            }]]} {set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33                                    } [get_ports { tp[1]            }] } ;# testpoints
if {[llength [get_ports { tp[2]            }]]} {set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33                                    } [get_ports { tp[2]            }] } ;#
if {[llength [get_ports { tp[3]            }]]} {set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33                                    } [get_ports { tp[3]            }] } ;#
if {[llength [get_ports { tp[4]            }]]} {set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33                                    } [get_ports { tp[4]            }] } ;#
if {[llength [get_ports { tp[5]            }]]} {set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33                                    } [get_ports { tp[5]            }] } ;#
if {[llength [get_ports { tp[6]            }]]} {set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33                                    } [get_ports { tp[6]            }] } ;#
if {[llength [get_ports { tp[7]            }]]} {set_property -dict { PACKAGE_PIN N20   IOSTANDARD LVCMOS33                                    } [get_ports { tp[7]            }] } ;#
if {[llength [get_ports { tp[8]            }]]} {set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33                                    } [get_ports { tp[8]            }] } ;#
if {[llength [get_ports { qspi_cs_n        }]]} {set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33                                    } [get_ports { qspi_cs_n        }] } ;# QSPI flash (for bitstream update)
if {[llength [get_ports { qspi_d[0]        }]]} {set_property -dict { PACKAGE_PIN P22   IOSTANDARD LVCMOS33  PULLUP TRUE                       } [get_ports { qspi_d[0]        }] } ;#
if {[llength [get_ports { qspi_d[1]        }]]} {set_property -dict { PACKAGE_PIN R22   IOSTANDARD LVCMOS33  PULLUP TRUE                       } [get_ports { qspi_d[1]        }] } ;#
if {[llength [get_ports { qspi_d[2]        }]]} {set_property -dict { PACKAGE_PIN P21   IOSTANDARD LVCMOS33  PULLUP TRUE                       } [get_ports { qspi_d[2]        }] } ;#
if {[llength [get_ports { qspi_d[3]        }]]} {set_property -dict { PACKAGE_PIN R21   IOSTANDARD LVCMOS33  PULLUP TRUE                       } [get_ports { qspi_d[3]        }] } ;#

set_property CONFIG_VOLTAGE                  3.3   [current_design]
set_property CFGBVS                          VCCO  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS      TRUE  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE     66    [current_design]
set_property CONFIG_MODE                     SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH   4     [current_design]
