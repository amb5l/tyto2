create_clock -period 20 [get_ports fpga_clk1_50]
create_clock -period 20 [get_ports fpga_clk2_50]
create_clock -period 20 [get_ports fpga_clk3_50]
derive_pll_clocks
derive_clock_uncertainty
