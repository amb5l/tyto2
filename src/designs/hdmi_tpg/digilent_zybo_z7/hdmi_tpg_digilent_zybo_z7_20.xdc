################################################################################
## hdmi_tpg_digilent_zybo_z7_20.xdc                                           ##
## Board specific constraints for the hdmi_tpg design.                        ##
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

# clock renaming
create_generated_clock -name clk_100m   [get_pins REF_CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk_x5 [get_pins MAIN/VIDEO_CLOCK/MMCM/CLKOUT0]
create_generated_clock -name pix_clk    [get_pins MAIN/VIDEO_CLOCK/MMCM/CLKOUT1]
create_generated_clock -name pcm_clk    [get_pins MAIN/AUDIO_TONE/CLOCK/MMCM/CLKOUT0]

# false paths
set_false_path -from [get_clocks clk_100m] -to [get_clocks pix_clk]
set_false_path -from [get_clocks pcm_clk] -to [get_clocks pix_clk]
set_false_path -from [get_clocks pix_clk] -to [get_clocks pcm_clk]
