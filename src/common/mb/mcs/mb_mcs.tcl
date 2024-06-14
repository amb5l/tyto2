set bd_name [file rootname [file tail [file normalize [info script]]]]
create_bd_design $bd_name

set cpu_type [lindex $argv 0]
set freq_hz  [lindex $argv 1]
puts "$bd_name: CPU type = $cpu_type  frequency = $freq_hz Hz"

if {"$cpu_type" == "mbv"} {
  set cpu_ip xilinx.com:ip:microblaze_mcs_riscv:1.0
} else {
  set cpu_ip xilinx.com:ip:microblaze_mcs:3.0
}

set cpu [ create_bd_cell -type ip -vlnv $cpu_ip cpu ]
set_property -dict [list \
    CONFIG.MEMSIZE       {131072} \
    CONFIG.UART_BAUDRATE {115200} \
    CONFIG.USE_GPI1      {1}      \
    CONFIG.USE_GPI2      {1}      \
    CONFIG.USE_GPI3      {1}      \
    CONFIG.USE_GPI4      {1}      \
    CONFIG.USE_GPO1      {1}      \
    CONFIG.USE_GPO2      {1}      \
    CONFIG.USE_GPO3      {1}      \
    CONFIG.USE_GPO4      {1}      \
    CONFIG.USE_IO_BUS    {1}      \
    CONFIG.USE_UART_RX   {1}      \
    CONFIG.USE_UART_TX   {1}      \
  ] $cpu

set clk   [ create_bd_port -dir I -type clk -freq_hz $freq_hz clk ]
set rst_n [ create_bd_port -dir I -type rst rst_n ]

set uart  [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0      uart  ]
set gpio1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0      gpio1 ]
set gpio2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0      gpio2 ]
set gpio3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0      gpio3 ]
set gpio4 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0      gpio4 ]
set io    [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mcsio_bus_rtl:1.0 io    ]

connect_bd_net -net cpu_clk   [ get_bd_ports clk   ] [ get_bd_pins cpu/Clk   ]
connect_bd_net -net cpu_rst_n [ get_bd_ports rst_n ] [ get_bd_pins cpu/Reset ]

connect_bd_intf_net -intf_net cpu_uart  [ get_bd_intf_ports uart  ] [ get_bd_intf_pins cpu/UART  ]
connect_bd_intf_net -intf_net cpu_gpio1 [ get_bd_intf_ports gpio1 ] [ get_bd_intf_pins cpu/GPIO1 ]
connect_bd_intf_net -intf_net cpu_gpio2 [ get_bd_intf_ports gpio2 ] [ get_bd_intf_pins cpu/GPIO2 ]
connect_bd_intf_net -intf_net cpu_gpio3 [ get_bd_intf_ports gpio3 ] [ get_bd_intf_pins cpu/GPIO3 ]
connect_bd_intf_net -intf_net cpu_gpio4 [ get_bd_intf_ports gpio4 ] [ get_bd_intf_pins cpu/GPIO4 ]
connect_bd_intf_net -intf_net cpu_io    [ get_bd_intf_ports io    ] [ get_bd_intf_pins cpu/IO    ]

regenerate_bd_layout
save_bd_design
