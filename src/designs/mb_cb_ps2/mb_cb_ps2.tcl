################################################################################
## mb_cb_ps2.tcl                                                              ##
## Constraints for the mb_cb_ps2 design.                                      ##
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

create_clock -add -name ps2_clk -period 60000 [get_ports ps2_clk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ps2_clk_IOBUF_inst/O]

create_generated_clock -name cpu_clk    [get_pins MMCM_CPU/MMCM/CLKOUT0]
create_generated_clock -name pix_clk_x5 [get_pins MMCM_PIX/MMCM/CLKOUT0]
create_generated_clock -name pix_clk    [get_pins MMCM_PIX/MMCM/CLKOUT1]
set_clock_groups -asynchronous \
-group {cpu_clk} \
-group {ps2_clk} \
-group {pix_clk pix_clk_x5}
