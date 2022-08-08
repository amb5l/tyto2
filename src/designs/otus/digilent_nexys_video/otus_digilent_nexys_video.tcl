################################################################################
## otus_digilent_nexys_video.tcl                                              ##
## Digilent Nexys Video board specific constraints for the Otus design.       ##
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

set ratio 3
set n_setup [expr $ratio]
set n_hold  [expr $ratio-1]

# clocks
create_clock -add -name clki_100m -period 10.00 [get_ports clki_100m]
create_generated_clock -name sys_clk_96m [get_pins CLK_SYS/MMCM/CLKOUT0]
create_generated_clock -name sys_clk_48m [get_pins CLK_SYS/MMCM/CLKOUT1]
create_generated_clock -name sys_clk_32m [get_pins CLK_SYS/MMCM/CLKOUT2]
create_generated_clock -name sys_clk_8m  [get_pins CLK_SYS/MMCM/CLKOUT3]
create_generated_clock -name pix_clk     [get_pins CLK_PIX/MMCM/CLKOUT1]
create_generated_clock -name pcm_clk     [get_pins CLK_PCM/MMCM/CLKOUT0]
set_clock_groups -asynchronous \
-group {clki_100m} \
-group {sys_clk_96m sys_clk_48m sys_clk_32m sys_clk_8m} \
-group {pix_clk} \
-group {pcm_clk}

# CPU RAM and cache read paths
set pins_ram_cache_rd                            [get_pins -include_replicated_objects {SYS/CORE/RAM/LATCH_A/if_d[*]}]
set pins_ram_cache_rd [concat $pins_ram_cache_rd [get_pins -include_replicated_objects {SYS/CORE/RAM/LATCH_B/ls_dr[*]}]]
set pins_ram_cache_rd [concat $pins_ram_cache_rd [get_pins -include_replicated_objects {SYS/CORE/CACHE_*/cache_dr[*]_INST_0/O}]]

# clk_96m to clk_32m: multicycle paths
set_multicycle_path $n_setup -setup -start -from sys_clk_96m -to sys_clk_32m -through $pins_ram_cache_rd
set_multicycle_path $n_hold  -hold  -start -from sys_clk_96m -to sys_clk_32m -through $pins_ram_cache_rd

# clk_96m to clk_96m: multicycle paths
set_multicycle_path $n_setup -setup -end   -from sys_clk_96m -to sys_clk_96m -through $pins_ram_cache_rd
set_multicycle_path $n_hold  -hold  -end   -from sys_clk_96m -to sys_clk_96m -through $pins_ram_cache_rd

# clk_32m to clk_96m: multicycle by default, with few exceptions
set_multicycle_path $n_setup -setup -end   -from sys_clk_32m -to sys_clk_96m
set_multicycle_path $n_hold  -hold  -end   -from sys_clk_32m -to sys_clk_96m
set c2m_sc                 [get_pins -include_replicated_objects {SYS/CORE/rst_s_reg[1]/Q}]
set c2m_sc [concat $c2m_sc [get_pins -include_replicated_objects {SYS/CORE/rst_reg/Q}]]
set c2m_sc [concat $c2m_sc [get_pins -include_replicated_objects {SYS/CORE/clk_phdet_reg[0]/Q}]]
set_multicycle_path 1 -setup -end -from sys_clk_32m -to sys_clk_96m -through $c2m_sc
set_multicycle_path 0 -hold  -end -from sys_clk_32m -to sys_clk_96m -through $c2m_sc
