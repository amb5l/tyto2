# unconstrained I/Os
set_input_delay -max 0 -clock clk_in [get_ports rst] -add_delay
set_input_delay -min 0 -clock clk_in [get_ports rst] -add_delay
set_false_path -through [get_ports rst]
