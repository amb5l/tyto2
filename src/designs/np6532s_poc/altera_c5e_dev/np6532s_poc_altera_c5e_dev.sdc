create_clock -period 20 [get_ports clkin_50_top]
derive_pll_clocks
derive_clock_uncertainty
