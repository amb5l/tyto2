set ratio 3
set n_setup [expr $ratio]
set n_hold  [expr $ratio-1]

create_generated_clock -name clk_mem [get_pins CLOCK/MMCM/CLKOUT0]
create_generated_clock -name clk_cpu [get_pins CLOCK/MMCM/CLKOUT1]

# CPU RAM and cache read paths
set pins_ram_cache_rd                            [get_pins -include_replicated_objects {SYS/CORE/RAM/LATCH_A/if_d[*]}]
set pins_ram_cache_rd [concat $pins_ram_cache_rd [get_pins -include_replicated_objects {SYS/CORE/RAM/LATCH_B/ls_dr[*]}]]
set pins_ram_cache_rd [concat $pins_ram_cache_rd [get_pins -include_replicated_objects {SYS/CORE/CACHE_*/cache_dr[*]_INST_0/O}]]

# clk_mem to clk_cpu: multicycle paths
set_multicycle_path $n_setup -setup -start -from clk_mem -to clk_cpu -through $pins_ram_cache_rd
set_multicycle_path $n_hold  -hold  -start -from clk_mem -to clk_cpu -through $pins_ram_cache_rd

# clk_mem to clk_mem: multicycle paths
set_multicycle_path $n_setup -setup -end   -from clk_mem -to clk_mem -through $pins_ram_cache_rd
set_multicycle_path $n_hold  -hold  -end   -from clk_mem -to clk_mem -through $pins_ram_cache_rd

# clk_cpu to clk_mem: multicycle by default, with few exceptions
set_multicycle_path $n_setup -setup -end   -from clk_cpu -to clk_mem
set_multicycle_path $n_hold  -hold  -end   -from clk_cpu -to clk_mem
set c2m_sc                 [get_pins -include_replicated_objects {SYS/CORE/rst_s_reg[1]/Q}]
set c2m_sc [concat $c2m_sc [get_pins -include_replicated_objects {SYS/CORE/rst_reg/Q}]]
set c2m_sc [concat $c2m_sc [get_pins -include_replicated_objects {SYS/CORE/clk_phdet_reg[0]/Q}]]
set_multicycle_path 1 -setup -end -from clk_cpu -to clk_mem -through $c2m_sc
set_multicycle_path 0 -hold  -end -from clk_cpu -to clk_mem -through $c2m_sc
