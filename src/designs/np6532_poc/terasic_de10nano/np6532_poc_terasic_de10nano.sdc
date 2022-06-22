set ratio 3
set n_setup [expr $ratio]
set n_hold  [expr $ratio-1]

set clk_mem [get_clocks {CLOCK|pll_otus_50m_96m_32m_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}]
set clk_cpu [get_clocks {CLOCK|pll_otus_50m_96m_32m_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk}]

# CPU RAM and cache read paths
set pins_ram_cache_rd                                       [get_pins -compatibility_mode {SYS|CORE|RAM|LATCH_A|*|combout}]
set pins_ram_cache_rd [add_to_collection $pins_ram_cache_rd [get_pins -compatibility_mode {SYS|CORE|RAM|LATCH_B|*|combout}]]
set pins_ram_cache_rd [add_to_collection $pins_ram_cache_rd [get_pins -compatibility_mode {SYS|CORE|CACHE_*|*|portbdataout[0]}]]

# clk_mem to clk_cpu: multicycle paths
set_multicycle_path $n_setup -setup -start -from $clk_mem -to $clk_cpu -through $pins_ram_cache_rd
set_multicycle_path $n_hold  -hold  -start -from $clk_mem -to $clk_cpu -through $pins_ram_cache_rd

# clk_mem to clk_mem: multicycle paths
set_multicycle_path $n_setup -setup -end   -from $clk_mem -to $clk_mem -through $pins_ram_cache_rd
set_multicycle_path $n_hold  -hold  -end   -from $clk_mem -to $clk_mem -through $pins_ram_cache_rd

# clk_cpu to clk_mem: multicycle by default, with few exceptions
set_multicycle_path $n_setup -setup -end   -from $clk_cpu -to $clk_mem
set_multicycle_path $n_hold  -hold  -end   -from $clk_cpu -to $clk_mem
set c2m_sc                            [get_pins -compatibility_mode {SYS|CORE|rst_s[1]|q}]
set c2m_sc [add_to_collection $c2m_sc [get_pins -compatibility_mode {SYS|CORE|rst|q}]]
set c2m_sc [add_to_collection $c2m_sc [get_pins -compatibility_mode {SYS|CORE|clk_phdet[0]|q}]]
set_multicycle_path 1 -setup -end -from $clk_cpu -to $clk_mem -through $c2m_sc
set_multicycle_path 0 -hold  -end -from $clk_cpu -to $clk_mem -through $c2m_sc
