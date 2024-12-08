set_false_path -setup -hold -to [get_cells "reg_reg[1][*]"]
set_false_path -quiet  -setup -hold -to [get_pins -quiet {reg_reg[*][*]/R reg_reg[*][*]/PRE}]
