################################################################################
## mb_fb_qmtech_wukong.xdc                                                    ##
## Board specific constraints for the mb_fb design.                           ##
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

# clock
create_clock -add -name clki_50m -period 20.00 [get_ports clki_50m]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {clki_50m_IBUF}]

# clock renaming
create_generated_clock -name clk_100m [get_pins MIG/u_ddr3_mig/u_ddr3_infrastructure/gen_ui_extra_clocks.mmcm_i/CLKFBOUT]
create_generated_clock -name pix_clk_x5 [get_pins MAIN/U_CRTC/CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk    [get_pins MAIN/U_CRTC/CLOCK/MMCM/CLKOUT1]

# false paths
set_false_path -from [get_clocks clk_100m] -to [get_clocks pix_clk]
