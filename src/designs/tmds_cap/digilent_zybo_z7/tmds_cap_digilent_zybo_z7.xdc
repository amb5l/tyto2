################################################################################
## tmds_cap_digilent_zybo_z7.xdc                                              ##
## Digilent Zybo Z7 board constraints for the tmds_cap design.                ##
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

create_generated_clock -name clk_200m [get_pins U_MMCM/MMCM/CLKOUT0]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets hdmi_tx_scl_TRI]
