create_clock -add -name ref_clk -period 8.00 [get_ports ref_clk]

create_clock -add -name rgmii_tx_clk -period 8.00
create_clock -add -name rgmii_rx_clk -period 8.00 [get_ports rgmii_clk]

set tCOmin -0.5
set tCOmax  0.5

set rgmii_ports [get_ports {rgmii_ctl rgmii_d[*]}]

set_multicycle_path 0 -rise_from [get_clocks rgmii_tx_clk] -rise_to [get_clocks rgmii_rx_clk]
set_false_path -setup -rise_from [get_clocks rgmii_tx_clk] -fall_to [get_clocks rgmii_rx_clk]
set_false_path -hold  -rise_from [get_clocks rgmii_tx_clk] -rise_to [get_clocks rgmii_rx_clk]

set_multicycle_path 0 -fall_from [get_clocks rgmii_tx_clk] -fall_to [get_clocks rgmii_rx_clk]
set_false_path -setup -fall_from [get_clocks rgmii_tx_clk] -rise_to [get_clocks rgmii_rx_clk]
set_false_path -hold  -fall_from [get_clocks rgmii_tx_clk] -fall_to [get_clocks rgmii_rx_clk]

set_input_delay            -clock rgmii_tx_clk             -min $tCOmin $rgmii_ports
set_input_delay -add_delay -clock rgmii_tx_clk -clock_fall -min $tCOmin $rgmii_ports
set_input_delay -add_delay -clock rgmii_tx_clk             -max $tCOmax $rgmii_ports
set_input_delay -add_delay -clock rgmii_tx_clk -clock_fall -max $tCOmax $rgmii_ports
