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
create_generated_clock -name i_clk     [get_pins MAIN/U_HRAM_TEST/U_MMCM/MMCM/MMCM/CLKOUT0]
create_generated_clock -name i_clk_dly [get_pins MAIN/U_HRAM_TEST/U_MMCM/MMCM/MMCM/CLKOUT1]
create_generated_clock -name p_clk_x5  [get_pins MAIN/U_DISPLAY/U_MMCM/MMCM/MMCM/CLKOUT0]
create_generated_clock -name p_clk     [get_pins MAIN/U_DISPLAY/U_MMCM/MMCM/MMCM/CLKOUT1]

################################################################################

# clock frequency
set tCK 10.00
set tCKHP [expr $tCK/2]

# IS66WVH8M8DBLL-100B1LI
set tIS      1.0 ; # input setup time
set tIH      1.0 ; # input hold time
set tDSSmax  0.8 ; # RWDS to data, max
set tDSSmin -0.8 ; # RWDS to data, min

# clocks
create_clock -add -name hr_rwds  -period $tCK [get_ports hr_rwds ]
create_generated_clock -name hr_clk -source [get_pins MAIN/U_HRAM_TEST/U_MMCM/MMCM/MMCM/CLKOUT1] -multiply_by 1 [get_ports hr_clk_p]

# FPGA to HyperRAM (address and write data)
# 1) setup
set_output_delay -max  $tIS -clock hr_clk [get_ports {hr_cs_n hr_rwds hr_d[*]}]
set_output_delay -max  $tIS -clock hr_clk [get_ports {hr_cs_n hr_rwds hr_d[*]}] -clock_fall -add_delay
# 2) hold
set_output_delay -min -$tIH -clock hr_clk [get_ports {hr_cs_n hr_rwds hr_d[*]}]
set_output_delay -min -$tIH -clock hr_clk [get_ports {hr_cs_n hr_rwds hr_d[*]}] -clock_fall -add_delay

# HyperRAM to FPGA (read data, clocked in by RWDS)
# edge aligned, so pretend that data is launched by previous edge
# 1) setup
set_input_delay -max [expr $tCKHP+$tDSSmax] -clock hr_rwds [get_ports hr_d[*]]
set_input_delay -max [expr $tCKHP+$tDSSmax] -clock hr_rwds [get_ports hr_d[*]] -clock_fall -add_delay
# 2) hold
set_input_delay -min [expr $tCKHP+$tDSSmin] -clock hr_rwds [get_ports hr_d[*]]
set_input_delay -min [expr $tCKHP+$tDSSmin] -clock hr_rwds [get_ports hr_d[*]] -clock_fall -add_delay

# multicycle to relax hr_rwds_t and hr_dq_t timing
set_multicycle_path 2 -setup -end -from [get_cells {MAIN/U_HRAM_TEST/U_CTRL/h_rwds_t_reg* MAIN/U_HRAM_TEST/U_CTRL/h_dq_t_reg*}]
set_multicycle_path 1  -hold -end -from [get_cells {MAIN/U_HRAM_TEST/U_CTRL/h_rwds_t_reg* MAIN/U_HRAM_TEST/U_CTRL/h_dq_t_reg*}]

# multicycle to relax ce_rd timing
set_multicycle_path 2 -setup -end -from [get_cells MAIN/U_HRAM_TEST/U_CTRL/ce_rd_reg] -to [get_cells MAIN/U_HRAM_TEST/U_CTRL/GEN_DQ[*].U_IDDR]
set_multicycle_path 1  -hold -end -from [get_cells MAIN/U_HRAM_TEST/U_CTRL/ce_rd_reg] -to [get_cells MAIN/U_HRAM_TEST/U_CTRL/GEN_DQ[*].U_IDDR]

# false path on hr_rwds to itself
set_false_path -from hr_rwds -to [get_ports hr_rwds]