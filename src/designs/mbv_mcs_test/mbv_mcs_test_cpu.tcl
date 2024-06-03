set bd_name [file rootname [file tail [file normalize [info script]]]]
create_bd_design $bd_name

set cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze_mcs_riscv:1.0 cpu ]
set_property -dict [list \
    CONFIG.MEMSIZE       {131072} \
    CONFIG.UART_BAUDRATE {115200} \
    CONFIG.USE_UART_RX   {1}      \
    CONFIG.USE_UART_TX   {1}      \
  ] $cpu

set clk   [ create_bd_port -dir I -type clk clk -freq_hz 100000000 ]
set rst_n [ create_bd_port -dir I -type rst rst_n ]

set uart  [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart  ]

connect_bd_net -net cpu_clk   [ get_bd_ports clk   ] [ get_bd_pins cpu/Clk   ]
connect_bd_net -net cpu_rst_n [ get_bd_ports rst_n ] [ get_bd_pins cpu/Reset ]

connect_bd_intf_net -intf_net cpu_uart  [ get_bd_intf_ports uart ] [ get_bd_intf_pins cpu/UART ]

regenerate_bd_layout
validate_bd_design
save_bd_design
