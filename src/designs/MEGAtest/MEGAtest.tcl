################################################################################
## MEGAtest.tcl                                                               ##
## MEGAtest design constraints.                                               ##
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

create_generated_clock -name clk_200m  [get_pins MAIN/U_CLK_RST/U_MMCM/MMCM/CLKOUT0]
create_generated_clock -name s_clk     [get_pins MAIN/U_CLK_RST/U_MMCM/MMCM/CLKOUT1]
#create_generated_clock -name s_clk_dly [get_pins MAIN/U_CLK_RST/U_MMCM/MMCM/CLKOUT2]
create_generated_clock -name p_clk_x5  [get_pins MAIN/U_DISPLAY/U_MMCM/MMCM/MMCM/CLKOUT0]
create_generated_clock -name p_clk     [get_pins MAIN/U_DISPLAY/U_MMCM/MMCM/MMCM/CLKOUT1]

set_clock_groups -asynchronous \
-group {clk_in} \
-group {clk_200m} \
-group {s_clk s_clk_dly} \
-group {p_clk p_clk_x5}
