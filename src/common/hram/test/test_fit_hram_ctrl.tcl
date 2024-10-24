################################################################################
# timing parameters

# clock frequency
set tCK 10.00
set tCKHP [expr $tCK/2]

# HyperRAM (correct for IS66WVH8M8DBLL-100B1LI)
set tIS      1.0 ; # input setup time
set tIH      1.0 ; # input hold time
set tDSSmax  0.8 ; # RWDS to data, max
set tDSSmin -0.8 ; # RWDS to data, min

################################################################################

# clocks
create_clock -add -name ref_clk -period $tCK [get_ports ref_clk]
create_clock -add -name h_rwds  -period $tCK [get_ports h_rwds ]
create_generated_clock -name h_clk -source [get_pins U_MMCM/MMCM/CLKOUT2] -multiply_by 1 [get_ports h_clk]

# FPGA to HyperRAM (address and write data)
# 1) setup
set_output_delay -max  $tIS -clock h_clk [get_ports {h_cs_n h_rwds h_dq[*]}]
set_output_delay -max  $tIS -clock h_clk [get_ports {h_cs_n h_rwds h_dq[*]}] -clock_fall -add_delay
# 2) hold
set_output_delay -min -$tIH -clock h_clk [get_ports {h_cs_n h_rwds h_dq[*]}]
set_output_delay -min -$tIH -clock h_clk [get_ports {h_cs_n h_rwds h_dq[*]}] -clock_fall -add_delay

# HyperRAM to FPGA (read data, clocked in by RWDS)
# edge aligned, so pretend that data is launched by previous edge
# 1) setup
set_input_delay -max [expr $tCKHP+$tDSSmax] -clock h_rwds [get_ports h_dq[*]]
set_input_delay -max [expr $tCKHP+$tDSSmax] -clock h_rwds [get_ports h_dq[*]] -clock_fall -add_delay
# 2) hold
set_input_delay -min [expr $tCKHP+$tDSSmin] -clock h_rwds [get_ports h_dq[*]]
set_input_delay -min [expr $tCKHP+$tDSSmin] -clock h_rwds [get_ports h_dq[*]] -clock_fall -add_delay

# multicycle to relax h_rwds_t and h_dq_t timing
set_multicycle_path 2 -setup -end -from [get_cells {U_CTRL/h_rwds_t_reg* U_CTRL/h_dq_t_reg*}]
set_multicycle_path 1  -hold -end -from [get_cells {U_CTRL/h_rwds_t_reg* U_CTRL/h_dq_t_reg*}]

# multicycle to relax ce_rd timing
set_multicycle_path 2 -setup -end -from [get_cells U_CTRL/ce_rd_reg] -to [get_cells U_CTRL/GEN_DQ_I[*].U_IDDR]
set_multicycle_path 1  -hold -end -from [get_cells U_CTRL/ce_rd_reg] -to [get_cells U_CTRL/GEN_DQ_I[*].U_IDDR]

# false path on h_rwds to itself
set_false_path -from h_rwds -to [get_ports h_rwds]


################################################################################

set_property -dict "PACKAGE_PIN F20 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_clk]
set_property -dict "PACKAGE_PIN F19 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_rwds]
set_property -dict "PACKAGE_PIN F22 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_dq[0]]
set_property -dict "PACKAGE_PIN F21 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_dq[1]]
set_property -dict "PACKAGE_PIN D22 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_dq[2]]
set_property -dict "PACKAGE_PIN E22 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_dq[3]]
set_property -dict "PACKAGE_PIN C22 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_dq[4]]
set_property -dict "PACKAGE_PIN D21 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_dq[5]]
set_property -dict "PACKAGE_PIN C20 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_dq[6]]
set_property -dict "PACKAGE_PIN D20 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 12" [get_ports h_dq[7]]
