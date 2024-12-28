set bd_name [file rootname [file tail [file normalize [info script]]]]
create_bd_design $bd_name

if {$argc < 1} {
    error "missing argument: frequency (Hz)"
}
set freq_hz [lindex $argv 0]
puts "$bd_name: frequency = $freq_hz Hz"

set clk    [ create_bd_port -dir I -type clk -freq_hz $freq_hz clk ]
set rst_n  [ create_bd_port -dir I -type rst rst_n ]
set arst_n [ create_bd_port -dir O -from 0 -to 0 -type rst arst_n ]
set maxi   [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 maxi ]
set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
 ] $maxi

set cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze_riscv:1.0 cpu ]
set_property -dict [list \
    CONFIG.C_D_AXI {1} \
    CONFIG.C_ENABLE_DISCRETE_PORTS {1} \
    CONFIG.C_ILL_INSTR_EXCEPTION {0} \
    CONFIG.C_MISALIGNED_EXCEPTIONS {0} \
    CONFIG.C_M_AXI_D_BUS_EXCEPTION {0} \
    CONFIG.C_USE_BRANCH_TARGET_CACHE {1} \
    CONFIG.C_USE_COMPRESSION {1} \
    CONFIG.C_USE_DCACHE {0} \
    CONFIG.C_USE_ICACHE {0} \
  ] $cpu
set mdm [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm_riscv:1.0 mdm ]
set_property -dict [list \
    CONFIG.C_ADDR_SIZE {32} \
    CONFIG.C_M_AXI_ADDR_WIDTH {32} \
    CONFIG.C_USE_UART {1} \
  ] $mdm
set reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset ]
set xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat ]
set dlmb [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb ]
set ilmb [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb ]
set dlmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram ]
set ilmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram ]
set bram_gen [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 bram_gen ]
set_property -dict [list \
    CONFIG.Assume_Synchronous_Clk {true} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
  ] $bram_gen
set axi_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect ]
set_property CONFIG.NUM_MI {2} $axi_interconnect

connect_bd_net -net clk \
    [get_bd_ports clk] \
    [get_bd_pins cpu/Clk] \
    [get_bd_pins dlmb/LMB_Clk] \
    [get_bd_pins ilmb/LMB_Clk] \
    [get_bd_pins reset/slowest_sync_clk] \
    [get_bd_pins dlmb_bram/LMB_Clk] \
    [get_bd_pins ilmb_bram/LMB_Clk] \
    [get_bd_pins axi_interconnect/ACLK] \
    [get_bd_pins mdm/S_AXI_ACLK] \
    [get_bd_pins axi_interconnect/S00_ACLK] \
    [get_bd_pins axi_interconnect/M00_ACLK] \
    [get_bd_pins axi_interconnect/M01_ACLK]
connect_bd_net -net rsti_n \
    [get_bd_ports rst_n] \
    [get_bd_pins reset/ext_reset_in]
connect_bd_net -net rst_cpu \
    [get_bd_pins reset/mb_reset] \
    [get_bd_pins cpu/Reset]
connect_bd_net -net rst_bus \
    [get_bd_pins reset/bus_struct_reset] \
    [get_bd_pins dlmb/SYS_Rst] \
    [get_bd_pins ilmb/SYS_Rst] \
    [get_bd_pins dlmb_bram/LMB_Rst] \
    [get_bd_pins ilmb_bram/LMB_Rst]
connect_bd_net -net arst_n \
    [get_bd_pins reset/interconnect_aresetn] \
    [get_bd_pins axi_interconnect/ARESETN] \
    [get_bd_pins axi_interconnect/M01_ARESETN] \
    [get_bd_pins axi_interconnect/M00_ARESETN] \
    [get_bd_pins axi_interconnect/S00_ARESETN]
connect_bd_net -net rsto_n \
    [get_bd_pins reset/peripheral_aresetn] \
    [get_bd_pins mdm/S_AXI_ARESETN] \
    [get_bd_ports arst_n]
connect_bd_net -net rst_dbg \
    [get_bd_pins mdm/Debug_SYS_Rst] \
    [get_bd_pins reset/mb_debug_sys_rst]
connect_bd_net -net wake_o \
    [get_bd_pins cpu/Dbg_Wakeup] \
    [get_bd_pins xlconcat/In1] \
    [get_bd_pins xlconcat/In0]
connect_bd_net -net wake_i \
    [get_bd_pins xlconcat/dout] \
    [get_bd_pins cpu/Wakeup]

connect_bd_intf_net -intf_net dlmb_bram      [get_bd_intf_pins dlmb/LMB_Sl_0]            [get_bd_intf_pins dlmb_bram/SLMB]
connect_bd_intf_net -intf_net ilmb_bram      [get_bd_intf_pins ilmb/LMB_Sl_0]            [get_bd_intf_pins ilmb_bram/SLMB]
connect_bd_intf_net -intf_net axi_x_m0       [get_bd_intf_pins axi_interconnect/M00_AXI] [get_bd_intf_pins mdm/S_AXI]
connect_bd_intf_net -intf_net axi_x_m1       [get_bd_intf_ports maxi]                    [get_bd_intf_pins axi_interconnect/M01_AXI]
connect_bd_intf_net -intf_net dlmb_bram_port [get_bd_intf_pins dlmb_bram/BRAM_PORT]      [get_bd_intf_pins bram_gen/BRAM_PORTA]
connect_bd_intf_net -intf_net ilmb_bram_port [get_bd_intf_pins ilmb_bram/BRAM_PORT]      [get_bd_intf_pins bram_gen/BRAM_PORTB]
connect_bd_intf_net -intf_net cpu_mdm        [get_bd_intf_pins mdm/MBDEBUG_0]            [get_bd_intf_pins cpu/DEBUG]
connect_bd_intf_net -intf_net cpu_dlmb       [get_bd_intf_pins cpu/DLMB]                 [get_bd_intf_pins dlmb/LMB_M]
connect_bd_intf_net -intf_net cpu_ilmb       [get_bd_intf_pins cpu/ILMB]                 [get_bd_intf_pins ilmb/LMB_M]
connect_bd_intf_net -intf_net cpu_maxi       [get_bd_intf_pins cpu/M_AXI_DP]             [get_bd_intf_pins axi_interconnect/S00_AXI]

assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cpu/Data]        [get_bd_addr_segs dlmb_bram/SLMB/Mem] -force
assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces cpu/Data]        [get_bd_addr_segs maxi/Reg]           -force
assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data]        [get_bd_addr_segs mdm/S_AXI/Reg]      -force
assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cpu/Instruction] [get_bd_addr_segs ilmb_bram/SLMB/Mem] -force

validate_bd_design
save_bd_design
