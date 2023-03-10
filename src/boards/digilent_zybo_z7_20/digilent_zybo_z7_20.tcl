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

create_clock -add -name sysclk -period 8.00 -waveform {0 4} [get_ports sysclk_i]

if {[llength [get_ports { sysclk_i              }]]}     {set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33              } [get_ports { sysclk_i            }]}
if {[llength [get_ports { sw_i[0]               }]]}     {set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33              } [get_ports { sw_i[0]             }]}
if {[llength [get_ports { sw_i[1]               }]]}     {set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33              } [get_ports { sw_i[1]             }]}
if {[llength [get_ports { sw_i[2]               }]]}     {set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33              } [get_ports { sw_i[2]             }]}
if {[llength [get_ports { sw_i[3]               }]]}     {set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33              } [get_ports { sw_i[3]             }]}
if {[llength [get_ports { btn_i[0]              }]]}     {set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33              } [get_ports { btn_i[0]            }]}
if {[llength [get_ports { btn_i[1]              }]]}     {set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33              } [get_ports { btn_i[1]            }]}
if {[llength [get_ports { btn_i[2]              }]]}     {set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33              } [get_ports { btn_i[2]            }]}
if {[llength [get_ports { btn_i[3]              }]]}     {set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33              } [get_ports { btn_i[3]            }]}
if {[llength [get_ports { led_o[0]              }]]}     {set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33              } [get_ports { led_o[0]            }]}
if {[llength [get_ports { led_o[1]              }]]}     {set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33              } [get_ports { led_o[1]            }]}
if {[llength [get_ports { led_o[2]              }]]}     {set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33              } [get_ports { led_o[2]            }]}
if {[llength [get_ports { led_o[3]              }]]}     {set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33              } [get_ports { led_o[3]            }]}
if {[llength [get_ports { led5_r_o              }]]}     {set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33              } [get_ports { led5_r_o            }]}
if {[llength [get_ports { led5_g_o              }]]}     {set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33              } [get_ports { led5_g_o            }]}
if {[llength [get_ports { led5_b_o              }]]}     {set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS33              } [get_ports { led5_b_o            }]}
if {[llength [get_ports { led6_r_o              }]]}     {set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33              } [get_ports { led6_r_o            }]}
if {[llength [get_ports { led6_g_o              }]]}     {set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33              } [get_ports { led6_g_o            }]}
if {[llength [get_ports { led6_b_o              }]]}     {set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33              } [get_ports { led6_b_o            }]}
if {[llength [get_ports { ac_bclk_io            }]]}     {set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33              } [get_ports { ac_bclk_io          }]}
if {[llength [get_ports { ac_mclk_i             }]]}     {set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33              } [get_ports { ac_mclk_i           }]}
if {[llength [get_ports { ac_muten_o            }]]}     {set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33              } [get_ports { ac_muten_o          }]}
if {[llength [get_ports { ac_pbdat_o            }]]}     {set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33              } [get_ports { ac_pbdat_o          }]}
if {[llength [get_ports { ac_pblrc_io           }]]}     {set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33              } [get_ports { ac_pblrc_io         }]}
if {[llength [get_ports { ac_recdat_i           }]]}     {set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33              } [get_ports { ac_recdat_i         }]}
if {[llength [get_ports { ac_reclrc_io          }]]}     {set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33              } [get_ports { ac_reclrc_io        }]}
if {[llength [get_ports { ac_scl_o              }]]}     {set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33              } [get_ports { ac_scl_o            }]}
if {[llength [get_ports { ac_sda_io             }]]}     {set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33              } [get_ports { ac_sda_io           }]}
if {[llength [get_ports { eth_int_pu_b_i        }]]}     {set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { eth_int_pu_b_i      }]}
if {[llength [get_ports { eth_rst_b_o           }]]}     {set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33              } [get_ports { eth_rst_b_o         }]}
if {[llength [get_ports { fan_fb_pu_i           }]]}     {set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { fan_fb_pu_i         }]}
if {[llength [get_ports { hdmi_rx_hpd_o         }]]}     {set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33              } [get_ports { hdmi_rx_hpd_o       }]}
if {[llength [get_ports { hdmi_rx_scl_io        }]]}     {set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33              } [get_ports { hdmi_rx_scl_io      }]}
if {[llength [get_ports { hdmi_rx_sda_io        }]]}     {set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33              } [get_ports { hdmi_rx_sda_io      }]}
if {[llength [get_ports { hdmi_rx_clk_n_i       }]]}     {set_property -dict { PACKAGE_PIN U19   IOSTANDARD TMDS_33               } [get_ports { hdmi_rx_clk_n_i     }]}
if {[llength [get_ports { hdmi_rx_clk_p_i       }]]}     {set_property -dict { PACKAGE_PIN U18   IOSTANDARD TMDS_33               } [get_ports { hdmi_rx_clk_p_i     }]}
if {[llength [get_ports { hdmi_rx_n_i[0]        }]]}     {set_property -dict { PACKAGE_PIN W20   IOSTANDARD TMDS_33               } [get_ports { hdmi_rx_n_i[0]      }]}
if {[llength [get_ports { hdmi_rx_p_i[0]        }]]}     {set_property -dict { PACKAGE_PIN V20   IOSTANDARD TMDS_33               } [get_ports { hdmi_rx_p_i[0]      }]}
if {[llength [get_ports { hdmi_rx_n_i[1]        }]]}     {set_property -dict { PACKAGE_PIN U20   IOSTANDARD TMDS_33               } [get_ports { hdmi_rx_n_i[1]      }]}
if {[llength [get_ports { hdmi_rx_p_i[1]        }]]}     {set_property -dict { PACKAGE_PIN T20   IOSTANDARD TMDS_33               } [get_ports { hdmi_rx_p_i[1]      }]}
if {[llength [get_ports { hdmi_rx_n_i[2]        }]]}     {set_property -dict { PACKAGE_PIN P20   IOSTANDARD TMDS_33               } [get_ports { hdmi_rx_n_i[2]      }]}
if {[llength [get_ports { hdmi_rx_p_i[2]        }]]}     {set_property -dict { PACKAGE_PIN N20   IOSTANDARD TMDS_33               } [get_ports { hdmi_rx_p_i[2]      }]}
if {[llength [get_ports { hdmi_rx_cec_i         }]]}     {set_property -dict { PACKAGE_PIN Y8    IOSTANDARD LVCMOS33              } [get_ports { hdmi_rx_cec_i       }]}
if {[llength [get_ports { hdmi_tx_hpd_i         }]]}     {set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33              } [get_ports { hdmi_tx_hpd_i       }]}
if {[llength [get_ports { hdmi_tx_scl_io        }]]}     {set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33              } [get_ports { hdmi_tx_scl_io      }]}
if {[llength [get_ports { hdmi_tx_sda_io        }]]}     {set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33              } [get_ports { hdmi_tx_sda_io      }]}
if {[llength [get_ports { hdmi_tx_clk_n_o       }]]}     {set_property -dict { PACKAGE_PIN H17   IOSTANDARD TMDS_33               } [get_ports { hdmi_tx_clk_n_o     }]}
if {[llength [get_ports { hdmi_tx_clk_p_o       }]]}     {set_property -dict { PACKAGE_PIN H16   IOSTANDARD TMDS_33               } [get_ports { hdmi_tx_clk_p_o     }]}
if {[llength [get_ports { hdmi_tx_n_o[0]        }]]}     {set_property -dict { PACKAGE_PIN D20   IOSTANDARD TMDS_33               } [get_ports { hdmi_tx_n_o[0]      }]}
if {[llength [get_ports { hdmi_tx_p_o[0]        }]]}     {set_property -dict { PACKAGE_PIN D19   IOSTANDARD TMDS_33               } [get_ports { hdmi_tx_p_o[0]      }]}
if {[llength [get_ports { hdmi_tx_n_o[1]        }]]}     {set_property -dict { PACKAGE_PIN B20   IOSTANDARD TMDS_33               } [get_ports { hdmi_tx_n_o[1]      }]}
if {[llength [get_ports { hdmi_tx_p_o[1]        }]]}     {set_property -dict { PACKAGE_PIN C20   IOSTANDARD TMDS_33               } [get_ports { hdmi_tx_p_o[1]      }]}
if {[llength [get_ports { hdmi_tx_n_o[2]        }]]}     {set_property -dict { PACKAGE_PIN A20   IOSTANDARD TMDS_33               } [get_ports { hdmi_tx_n_o[2]      }]}
if {[llength [get_ports { hdmi_tx_p_o[2]        }]]}     {set_property -dict { PACKAGE_PIN B19   IOSTANDARD TMDS_33               } [get_ports { hdmi_tx_p_o[2]      }]}
if {[llength [get_ports { hdmi_tx_cec_o         }]]}     {set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33              } [get_ports { hdmi_tx_cec_o       }]}
if {[llength [get_ports { ja_io[0]              }]]}     {set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33              } [get_ports { ja_io[0]            }]}
if {[llength [get_ports { ja_io[1]              }]]}     {set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33              } [get_ports { ja_io[1]            }]}
if {[llength [get_ports { ja_io[2]              }]]}     {set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33              } [get_ports { ja_io[2]            }]}
if {[llength [get_ports { ja_io[3]              }]]}     {set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33              } [get_ports { ja_io[3]            }]}
if {[llength [get_ports { ja_io[4]              }]]}     {set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33              } [get_ports { ja_io[4]            }]}
if {[llength [get_ports { ja_io[5]              }]]}     {set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33              } [get_ports { ja_io[5]            }]}
if {[llength [get_ports { ja_io[6]              }]]}     {set_property -dict { PACKAGE_PIN J16   IOSTANDARD LVCMOS33              } [get_ports { ja_io[6]            }]}
if {[llength [get_ports { ja_io[7]              }]]}     {set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33              } [get_ports { ja_io[7]            }]}
if {[llength [get_ports { jb_io[0]              }]]}     {set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33              } [get_ports { jb_io[0]            }]}
if {[llength [get_ports { jb_io[1]              }]]}     {set_property -dict { PACKAGE_PIN W8    IOSTANDARD LVCMOS33              } [get_ports { jb_io[1]            }]}
if {[llength [get_ports { jb_io[2]              }]]}     {set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33              } [get_ports { jb_io[2]            }]}
if {[llength [get_ports { jb_io[3]              }]]}     {set_property -dict { PACKAGE_PIN V7    IOSTANDARD LVCMOS33              } [get_ports { jb_io[3]            }]}
if {[llength [get_ports { jb_io[4]              }]]}     {set_property -dict { PACKAGE_PIN Y7    IOSTANDARD LVCMOS33              } [get_ports { jb_io[4]            }]}
if {[llength [get_ports { jb_io[5]              }]]}     {set_property -dict { PACKAGE_PIN Y6    IOSTANDARD LVCMOS33              } [get_ports { jb_io[5]            }]}
if {[llength [get_ports { jb_io[6]              }]]}     {set_property -dict { PACKAGE_PIN V6    IOSTANDARD LVCMOS33              } [get_ports { jb_io[6]            }]}
if {[llength [get_ports { jb_io[7]              }]]}     {set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33              } [get_ports { jb_io[7]            }]}
if {[llength [get_ports { jc_io[0]              }]]}     {set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33              } [get_ports { jc_io[0]            }]}
if {[llength [get_ports { jc_io[1]              }]]}     {set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33              } [get_ports { jc_io[1]            }]}
if {[llength [get_ports { jc_io[2]              }]]}     {set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33              } [get_ports { jc_io[2]            }]}
if {[llength [get_ports { jc_io[3]              }]]}     {set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33              } [get_ports { jc_io[3]            }]}
if {[llength [get_ports { jc_io[4]              }]]}     {set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33              } [get_ports { jc_io[4]            }]}
if {[llength [get_ports { jc_io[5]              }]]}     {set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33              } [get_ports { jc_io[5]            }]}
if {[llength [get_ports { jc_io[6]              }]]}     {set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33              } [get_ports { jc_io[6]            }]}
if {[llength [get_ports { jc_io[7]              }]]}     {set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33              } [get_ports { jc_io[7]            }]}
if {[llength [get_ports { jd_io[0]              }]]}     {set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33              } [get_ports { jd_io[0]            }]}
if {[llength [get_ports { jd_io[1]              }]]}     {set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33              } [get_ports { jd_io[1]            }]}
if {[llength [get_ports { jd_io[2]              }]]}     {set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33              } [get_ports { jd_io[2]            }]}
if {[llength [get_ports { jd_io[3]              }]]}     {set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33              } [get_ports { jd_io[3]            }]}
if {[llength [get_ports { jd_io[4]              }]]}     {set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33              } [get_ports { jd_io[4]            }]}
if {[llength [get_ports { jd_io[5]              }]]}     {set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33              } [get_ports { jd_io[5]            }]}
if {[llength [get_ports { jd_io[6]              }]]}     {set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33              } [get_ports { jd_io[6]            }]}
if {[llength [get_ports { jd_io[7]              }]]}     {set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33              } [get_ports { jd_io[7]            }]}
if {[llength [get_ports { je_io[0]              }]]}     {set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33              } [get_ports { je_io[0]            }]}
if {[llength [get_ports { je_io[1]              }]]}     {set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33              } [get_ports { je_io[1]            }]}
if {[llength [get_ports { je_io[2]              }]]}     {set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33              } [get_ports { je_io[2]            }]}
if {[llength [get_ports { je_io[3]              }]]}     {set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33              } [get_ports { je_io[3]            }]}
if {[llength [get_ports { je_io[4]              }]]}     {set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33              } [get_ports { je_io[4]            }]}
if {[llength [get_ports { je_io[5]              }]]}     {set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33              } [get_ports { je_io[5]            }]}
if {[llength [get_ports { je_io[6]              }]]}     {set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33              } [get_ports { je_io[6]            }]}
if {[llength [get_ports { je_io[7]              }]]}     {set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33              } [get_ports { je_io[7]            }]}
if {[llength [get_ports { dphy_clk_lp_n         }]]}     {set_property -dict { PACKAGE_PIN J19   IOSTANDARD HSUL_12               } [get_ports { dphy_clk_lp_n       }]}
if {[llength [get_ports { dphy_clk_lp_p         }]]}     {set_property -dict { PACKAGE_PIN H20   IOSTANDARD HSUL_12               } [get_ports { dphy_clk_lp_p       }]}
if {[llength [get_ports { dphy_data_lp_n[0]     }]]}     {set_property -dict { PACKAGE_PIN M18   IOSTANDARD HSUL_12               } [get_ports { dphy_data_lp_n[0]   }]}
if {[llength [get_ports { dphy_data_lp_p[0]     }]]}     {set_property -dict { PACKAGE_PIN L19   IOSTANDARD HSUL_12               } [get_ports { dphy_data_lp_p[0]   }]}
if {[llength [get_ports { dphy_data_lp_n[1]     }]]}     {set_property -dict { PACKAGE_PIN L20   IOSTANDARD HSUL_12               } [get_ports { dphy_data_lp_n[1]   }]}
if {[llength [get_ports { dphy_data_lp_p[1]     }]]}     {set_property -dict { PACKAGE_PIN J20   IOSTANDARD HSUL_12               } [get_ports { dphy_data_lp_p[1]   }]}
if {[llength [get_ports { dphy_hs_clock_clk_n   }]]}     {set_property -dict { PACKAGE_PIN H18   IOSTANDARD LVDS_25               } [get_ports { dphy_hs_clock_clk_n }]}
if {[llength [get_ports { dphy_hs_clock_clk_p   }]]}     {set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVDS_25               } [get_ports { dphy_hs_clock_clk_p }]}
if {[llength [get_ports { dphy_data_hs_n[0]     }]]}     {set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVDS_25               } [get_ports { dphy_data_hs_n[0]   }]}
if {[llength [get_ports { dphy_data_hs_p[0]     }]]}     {set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVDS_25               } [get_ports { dphy_data_hs_p[0]   }]}
if {[llength [get_ports { dphy_data_hs_n[1]     }]]}     {set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVDS_25               } [get_ports { dphy_data_hs_n[1]   }]}
if {[llength [get_ports { dphy_data_hs_p[1]     }]]}     {set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVDS_25               } [get_ports { dphy_data_hs_p[1]   }]}
if {[llength [get_ports { cam_clk_i             }]]}     {set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33              } [get_ports { cam_clk_i           }]}
if {[llength [get_ports { cam_gpio_i            }]]}     {set_property -dict { PACKAGE_PIN G20   IOSTANDARD LVCMOS33  PULLUP true } [get_ports { cam_gpio_i          }]}
if {[llength [get_ports { cam_scl_io            }]]}     {set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS33              } [get_ports { cam_scl_io          }]}
if {[llength [get_ports { cam_sda_io            }]]}     {set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33              } [get_ports { cam_sda_io          }]}
if {[llength [get_ports { crypto_sda_io         }]]}     {set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33              } [get_ports { crypto_sda_io       }]}
