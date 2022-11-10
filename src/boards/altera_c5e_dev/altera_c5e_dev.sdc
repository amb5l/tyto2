create_clock -period 20 [get_ports clkin_50_top]
create_clock -period 20 [get_ports clkin_50_right]
create_clock -period 8  [get_ports clkin_top_125]
create_clock -period 8  [get_ports clkin_bot_125]
derive_pll_clocks
derive_clock_uncertainty
