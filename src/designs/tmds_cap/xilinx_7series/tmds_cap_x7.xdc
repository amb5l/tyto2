################################################################################
## tmds_cap_x7.xdc                                                            ##
## AMD/Xilinx 7 series constraints for the tmds_cap design.                   ##
################################################################################
## (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        ##
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

# HDMI input clock set at 100MHz to match fictional recipe for MMCM
create_clock -add -name hdmi_rx_clk -period 10.00 -waveform {0 5} [get_ports hdmi_rx_clk_p]

# clock renaming
create_generated_clock -name pclk [get_pins U_IO/U_HDMI_RX/U_CLK/U_MMCM/CLKOUT0]
create_generated_clock -name sclk [get_pins U_IO/U_HDMI_RX/U_CLK/U_MMCM/CLKOUT1]

# false paths
set_false_path -through U_IO/U_CSR/cap_size_reg[*]
set_false_path -through U_IO/U_CSR/cap_test_reg
set_false_path -through U_IO/U_STREAM/cap_loss_reg
set_false_path -through U_IO/U_CSR/capstat_reg[*]
