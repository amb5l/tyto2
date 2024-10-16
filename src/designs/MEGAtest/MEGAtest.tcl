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

# global clock renaming
create_generated_clock -name clk_200m  [get_pins MAIN/U_CLK_RST/U_MMCM/MMCM/CLKOUT0]
create_generated_clock -name s_clk     [get_pins MAIN/U_CLK_RST/U_MMCM/MMCM/CLKOUT1]
create_generated_clock -name i_clk     [get_pins MAIN/U_HRAM_TEST/U_MMCM/MMCM/MMCM/CLKOUT0]
create_generated_clock -name i_clk_dly [get_pins MAIN/U_HRAM_TEST/U_MMCM/MMCM/MMCM/CLKOUT1]
create_generated_clock -name p_clk_x5  [get_pins MAIN/U_DISPLAY/U_MMCM/MMCM/MMCM/CLKOUT0]
create_generated_clock -name p_clk     [get_pins MAIN/U_DISPLAY/U_MMCM/MMCM/MMCM/CLKOUT1]

# basic timing parameters
set tCK 10.00           ; # clock period
set tCKHP [expr $tCK/2] ; # half clock period
set tPCB 0.1            ; # assumed PCB delay (FPGA <-> HyperRAM)

################################################################################
# HyperRAM

# use the following post-implementaion timing reports to check and amend these constraints:
#  report_datasheet -name timing_0
#  report_timing -from [get_clocks i_clk]        -to [get_clocks hr_rwds_fast] -delay_type min_max -max_paths 1000 -sort_by group -input_pins -routable_nets -name timing_1
#  report_timing -from [get_clocks i_clk]        -to [get_clocks hr_rwds_slow] -delay_type min_max -max_paths 1000 -sort_by group -input_pins -routable_nets -name timing_2
#  report_timing -from [get_clocks hr_rwds_fast] -to [get_clocks i_clk]        -delay_type min_max -max_paths 1000 -sort_by group -input_pins -routable_nets -name timing_3
#  report_timing -from [get_clocks hr_rwds_slow] -to [get_clocks i_clk]        -delay_type min_max -max_paths 1000 -sort_by group -input_pins -routable_nets -name timing_4
#  report_timing -from [get_clocks clk_in]       -to [get_clocks i_clk]        -delay_type min_max -max_paths 1000 -sort_by group -input_pins -routable_nets -name timing_5

# TODO debug problems with the below
#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk_in_IBUF]
#set_property LOC MMCME2_ADV_X0Y0 [get_cells MAIN/U_HRAM_TEST/U_MMCM/MMCM/MMCM]

# IS66WVH8M8DBLL-100B1LI timing parameters
set tIS       1.0 ; # input setup time
set tIH       1.0 ; # input hold time
set tDSSmax   0.8 ; # RWDS to data, max
set tDSSmin  -0.8 ; # RWDS to data, min
set tCKDSmin  1.0 ; # read: CLK to RWDS, min
set tCKDSmax  7.0 ; # read: CLK to RWDS, max
set tDSVmin   0.0 ; # chip select to RWDS valid, min
set tDSVmax  12.0 ; # chip select to RWDS valid, max

# from post-implementation timing report
# depends on MMCM and package pin placement - revisit if these are changed !!!
set tCO_hr_clk_min  10.611 ; # clk_in to hr_clk out,  min
set tCO_hr_clk_max  16.114 ; # clk_in to hr_clk out,  max
set tCO_hr_cs_n_min  2.998 ; # clk_in to hr_cs_n out, min
set tCO_hr_cs_n_max  8.840 ; # clk_in to hr_cs_n out, max
# TODO: generate datasheet automatically and check the above

# HyperRAM related clocks
create_generated_clock -name hr_clk -add -master_clock i_clk_dly -source [get_pins MAIN/U_HRAM_TEST/U_MMCM/MMCM/MMCM/CLKOUT1] -multiply_by 1 [get_ports hr_clk_p]
set_output_delay -max $tPCB [get_ports hr_clk_p] -add_delay
set_output_delay -min $tPCB [get_ports hr_clk_p] -add_delay
set tRWDSmin [expr $tCO_hr_clk_min+$tPCB+$tCKDSmin+$tPCB] ; # should be 11.717
set tRWDSmax [expr $tCO_hr_clk_max+$tPCB+$tCKDSmax+$tPCB] ; # should be 23.408
set hr_rwds_fast_edges [list $tRWDSmin [expr $tRWDSmin+$tCKHP]]
set hr_rwds_slow_edges [list $tRWDSmax [expr $tRWDSmax+$tCKHP]]
create_clock -add -name hr_rwds_fast -period $tCK -waveform $hr_rwds_fast_edges [get_ports hr_rwds] ; # minimum delay from clk_in to hr_rwds
create_clock -add -name hr_rwds_slow -period $tCK -waveform $hr_rwds_slow_edges [get_ports hr_rwds] ; # maximum delay from clk_in to hr_rwds
set_false_path -from [get_clocks hr_rwds_fast] -to [get_clocks hr_rwds_slow]
set_false_path -from [get_clocks hr_rwds_slow] -to [get_clocks hr_rwds_fast]

# FPGA to HyperRAM: address and write data, ODDR clocked by i_clk
set_output_delay -max  $tIS -clock hr_clk [get_ports {hr_cs_n hr_rwds hr_d[*]}]             -add_delay ; # setup, rising edge
set_output_delay -max  $tIS -clock hr_clk [get_ports {hr_cs_n hr_rwds hr_d[*]}] -clock_fall -add_delay ; # setup, falling edge
set_output_delay -min -$tIH -clock hr_clk [get_ports {hr_cs_n hr_rwds hr_d[*]}]             -add_delay ; # hold,  rising edge
set_output_delay -min -$tIH -clock hr_clk [get_ports {hr_cs_n hr_rwds hr_d[*]}] -clock_fall -add_delay ; # hold,  falling edge

# HyperRAM to FPGA: RWDS as an input sampled by state machine (clocked by i_clk)
set_input_delay -max [expr $tCO_hr_clk_max+$tCKDSmax] -clock clk_in [get_ports hr_rwds] -add_delay
set_input_delay -min [expr $tCO_hr_clk_min+$tCKDSmin] -clock clk_in [get_ports hr_rwds] -add_delay
set_multicycle_path 3 -setup -end -from [get_clocks clk_in] -to [get_pins MAIN/U_HRAM_TEST/U_CTRL/FSM_sequential_state_reg[*]/D] ; # setup to end of 3rd CA cycle
set_multicycle_path 2 -hold  -end -from [get_clocks clk_in] -to [get_pins MAIN/U_HRAM_TEST/U_CTRL/FSM_sequential_state_reg[*]/D] ; # corresponding hold
set_false_path -from [get_clocks hr_rwds_fast] -to [get_pins MAIN/U_HRAM_TEST/U_CTRL/FSM_sequential_state_reg[*]/D]
set_false_path -from [get_clocks hr_rwds_slow] -to [get_pins MAIN/U_HRAM_TEST/U_CTRL/FSM_sequential_state_reg[*]/D]

# HyperRAM to FPGA: read data, clocked into IDDR by RWDS
# edge aligned, so pretend that data is launched by previous edge
set_input_delay -max [expr $tCKHP+$tDSSmax] -clock hr_rwds_fast [get_ports hr_d[*]]             -add_delay ; # fast: setup, rising edge
set_input_delay -max [expr $tCKHP+$tDSSmax] -clock hr_rwds_fast [get_ports hr_d[*]] -clock_fall -add_delay ; # fast: setup, falling edge
set_input_delay -min [expr $tCKHP+$tDSSmin] -clock hr_rwds_fast [get_ports hr_d[*]]             -add_delay ; # fast: hold,  rising edge
set_input_delay -min [expr $tCKHP+$tDSSmin] -clock hr_rwds_fast [get_ports hr_d[*]] -clock_fall -add_delay ; # fast: hold,  falling edge
set_input_delay -max [expr $tCKHP+$tDSSmax] -clock hr_rwds_slow [get_ports hr_d[*]]             -add_delay ; # slow: setup, rising edge
set_input_delay -max [expr $tCKHP+$tDSSmax] -clock hr_rwds_slow [get_ports hr_d[*]] -clock_fall -add_delay ; # slow: setup, falling edge
set_input_delay -min [expr $tCKHP+$tDSSmin] -clock hr_rwds_slow [get_ports hr_d[*]]             -add_delay ; # slow: hold,  rising edge
set_input_delay -min [expr $tCKHP+$tDSSmin] -clock hr_rwds_slow [get_ports hr_d[*]] -clock_fall -add_delay ; # slow: hold,  falling edge

# HyperRAM read data path: RWDS clocked IDDR to system clock domain (final word FIFO bypass via U_MUX2)
set_multicycle_path 3 -setup -end -fall_from [get_clocks hr_rwds_fast] -through [get_cells MAIN/U_HRAM_TEST/U_CTRL/U_MUX2/GEN[*].U_LUT3] -rise_to [get_clocks i_clk] ; # fast
set_multicycle_path 2 -hold  -end -fall_from [get_clocks hr_rwds_fast] -through [get_cells MAIN/U_HRAM_TEST/U_CTRL/U_MUX2/GEN[*].U_LUT3] -rise_to [get_clocks i_clk] ; # fast
set_multicycle_path 2 -setup -end -fall_from [get_clocks hr_rwds_slow] -through [get_cells MAIN/U_HRAM_TEST/U_CTRL/U_MUX2/GEN[*].U_LUT3] -rise_to [get_clocks i_clk] ; # slow
set_multicycle_path 1 -hold  -end -fall_from [get_clocks hr_rwds_slow] -through [get_cells MAIN/U_HRAM_TEST/U_CTRL/U_MUX2/GEN[*].U_LUT3] -rise_to [get_clocks i_clk] ; # slow

# HyperRAM read data path: RWDS clocked FIFO write port to system clock domain
set_multicycle_path 2 -setup -end -from [get_clocks hr_rwds_fast] -through [get_cells MAIN/U_HRAM_TEST/U_CTRL/GEN_DFIFO[*].RAM/RAM] -to [get_clocks i_clk] ; # fast
set_multicycle_path 1 -hold  -end -from [get_clocks hr_rwds_fast] -through [get_cells MAIN/U_HRAM_TEST/U_CTRL/GEN_DFIFO[*].RAM/RAM] -to [get_clocks i_clk] ; # fast

# HyperRAM read data path: exclude async reset
set_false_path -from [get_clocks i_clk] -through [get_cells MAIN/U_HRAM_TEST/U_MMCM/CDC/reg_reg[2][0]] -to [get_clocks hr_rwds_fast] ; # fast
set_false_path -from [get_clocks i_clk] -through [get_cells MAIN/U_HRAM_TEST/U_MMCM/CDC/reg_reg[2][0]] -to [get_clocks hr_rwds_slow] ; # slow

# multicycle to relax hr_rwds_t and hr_dq_t timing
set_multicycle_path 2 -setup -end -from [get_cells {MAIN/U_HRAM_TEST/U_CTRL/h_rwds_t_reg* MAIN/U_HRAM_TEST/U_CTRL/h_dq_t_reg*}]
set_multicycle_path 1  -hold -end -from [get_cells {MAIN/U_HRAM_TEST/U_CTRL/h_rwds_t_reg* MAIN/U_HRAM_TEST/U_CTRL/h_dq_t_reg*}]

# multicycle to relax h_dq_i_ce and h_dq_i_ce_1 timing
set_multicycle_path 2 -setup -end -from [get_clocks i_clk] -through [get_cells {MAIN/U_HRAM_TEST/U_CTRL/h_dq_i_ce_reg}] -to [get_clocks hr_rwds_fast] ; # fast
set_multicycle_path 1  -hold -end -from [get_clocks i_clk] -through [get_cells {MAIN/U_HRAM_TEST/U_CTRL/h_dq_i_ce_reg}] -to [get_clocks hr_rwds_fast] ; # fast
set_multicycle_path 2 -setup -end -from [get_clocks i_clk] -through [get_cells {MAIN/U_HRAM_TEST/U_CTRL/h_dq_i_ce_reg}] -to [get_clocks hr_rwds_slow] ; # slow
set_multicycle_path 1  -hold -end -from [get_clocks i_clk] -through [get_cells {MAIN/U_HRAM_TEST/U_CTRL/h_dq_i_ce_reg}] -to [get_clocks hr_rwds_slow] ; # slow

# exclude RWDS to itself
set_false_path -from [get_ports hr_rwds] -to [get_ports hr_rwds]

# exclude DQ IDDR set/reset
set_false_path -from [get_pins MAIN/U_HRAM_TEST/U_CTRL/r_rst_reg/C] -to [get_pins MAIN/U_HRAM_TEST/U_CTRL/GEN_DQ[*].U_IDDR/R]
set_false_path -from [get_pins MAIN/U_HRAM_TEST/U_CTRL/r_rst_reg/C] -to [get_pins MAIN/U_HRAM_TEST/U_CTRL/GEN_DQ[*].U_IDDR/S]

# exclude RWDS ODDR reset
set_false_path -from [get_pins MAIN/U_HRAM_TEST/U_CTRL/phase_reg/C] -to [get_pins MAIN/U_HRAM_TEST/U_CTRL/U_ODDR_RWDS/R]

################################################################################
# pullups/pulldowns

# pull RWDS down
set_property PULLTYPE PULLDOWN [get_ports hr_rwds]

# pull DQ bus to 0x55 (telltale for bad read timing)
set_property PULLTYPE PULLUP   [get_ports {hr_d[0] hr_d[2] hr_d[4] hr_d[6]}]
set_property PULLTYPE PULLDOWN [get_ports {hr_d[1] hr_d[3] hr_d[5] hr_d[7]}]

################################################################################
# Miscellaneous

# unconstrained I/Os
set_input_delay -max 0 -clock clk_in [get_ports max10_tx] -add_delay
set_input_delay -min 0 -clock clk_in [get_ports max10_tx] -add_delay
set_output_delay -max 0 [get_ports {hdmi_clk_p hdmi_data_p[*] hr_rst_n}] -add_delay
set_output_delay -min 0 [get_ports {hdmi_clk_p hdmi_data_p[*] hr_rst_n}] -add_delay
set_false_path -through [get_ports {hdmi_clk_p hdmi_data_p[*] hr_rst_n}]
