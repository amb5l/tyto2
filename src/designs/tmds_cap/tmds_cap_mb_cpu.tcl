
################################################################
# This is a generated script based on design: tmds_cap_mb_cpu
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source tmds_cap_mb_cpu_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a200tsbg484-1
   set_property BOARD_PART digilentinc.com:nexys_video:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name tmds_cap_mb_cpu

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: ram
proc create_hier_cell_ram { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_ram() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $dlmb_bram_if_cntlr


  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $ilmb_bram_if_cntlr


  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.use_bram_block {BRAM_Controller} \
  ] $lmb_bram


  # Create interface connections
  connect_bd_intf_net -intf_net cpu_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net cpu_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net cpu_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net cpu_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net cpu_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net cpu_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net cpu_Clk [get_bd_pins Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set gpio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio ]

  set maxi128 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 maxi128 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.PHASE {0} \
   CONFIG.PROTOCOL {AXI4} \
   ] $maxi128

  set maxi32a [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 maxi32a ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {0} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.PHASE {0} \
   CONFIG.PROTOCOL {AXI4} \
   ] $maxi32a

  set maxi32b [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 maxi32b ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {0} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.PHASE {0} \
   CONFIG.PROTOCOL {AXI4} \
   ] $maxi32b

  set maxi32c [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 maxi32c ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {0} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.PHASE {0} \
   CONFIG.PROTOCOL {AXI4} \
   ] $maxi32c

  set saxi32a [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 saxi32a ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {0} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PHASE {0} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $saxi32a

  set saxi32b [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 saxi32b ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {0} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PHASE {0} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $saxi32b

  set saxi64 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 saxi64 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.HAS_BRESP {0} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.HAS_WSTRB {0} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PHASE {0} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $saxi64

  set uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart ]


  # Create ports
  set axi_clk [ create_bd_port -dir I -type clk axi_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {saxi32a:saxi64:maxi32a:maxi32b:maxi128:saxi32b:maxi32c} \
   CONFIG.ASSOCIATED_RESET {axi_rst_n:rsti_n} \
   CONFIG.PHASE {0} \
 ] $axi_clk
  set axi_rst_n [ create_bd_port -dir O -from 0 -to 0 -type rst axi_rst_n ]
  set lock [ create_bd_port -dir I lock ]
  set rsti_n [ create_bd_port -dir I -type rst rsti_n ]

  # Create instance: cpu, and set properties
  set cpu [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 cpu ]
  set_property -dict [list \
    CONFIG.C_ADDR_TAG_BITS {0} \
    CONFIG.C_AREA_OPTIMIZED {1} \
    CONFIG.C_DCACHE_ADDR_TAG {0} \
    CONFIG.C_DEBUG_ENABLED {1} \
    CONFIG.C_D_AXI {1} \
    CONFIG.C_D_LMB {1} \
    CONFIG.C_I_LMB {1} \
    CONFIG.C_USE_BARREL {1} \
    CONFIG.C_USE_HW_MUL {1} \
    CONFIG.C_USE_MSR_INSTR {1} \
    CONFIG.C_USE_PCMP_INSTR {1} \
    CONFIG.C_USE_REORDER_INSTR {0} \
    CONFIG.G_TEMPLATE_LIST {8} \
  ] $cpu


  # Create instance: debug, and set properties
  set debug [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 debug ]
  set_property -dict [list \
    CONFIG.C_ADDR_SIZE {32} \
    CONFIG.C_M_AXI_ADDR_WIDTH {32} \
    CONFIG.C_USE_UART {0} \
  ] $debug


  # Create instance: gpio, and set properties
  set gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 gpio ]

  # Create instance: ram
  create_hier_cell_ram [current_bd_instance .] ram

  # Create instance: rstctrl, and set properties
  set rstctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rstctrl ]
  set_property -dict [list \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $rstctrl


  # Create instance: smartconnect, and set properties
  set smartconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect ]
  set_property -dict [list \
    CONFIG.NUM_MI {6} \
    CONFIG.NUM_SI {4} \
  ] $smartconnect


  # Create instance: uart, and set properties
  set uart [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 uart ]
  set_property CONFIG.C_BAUDRATE {115200} $uart


  # Create interface connections
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports uart] [get_bd_intf_pins uart/UART]
  connect_bd_intf_net -intf_net cpu_M_AXI_DP [get_bd_intf_pins cpu/M_AXI_DP] [get_bd_intf_pins smartconnect/S00_AXI]
  connect_bd_intf_net -intf_net cpu_debug [get_bd_intf_pins cpu/DEBUG] [get_bd_intf_pins debug/MBDEBUG_0]
  connect_bd_intf_net -intf_net cpu_dlmb_1 [get_bd_intf_pins cpu/DLMB] [get_bd_intf_pins ram/DLMB]
  connect_bd_intf_net -intf_net cpu_ilmb_1 [get_bd_intf_pins cpu/ILMB] [get_bd_intf_pins ram/ILMB]
  connect_bd_intf_net -intf_net gpio_GPIO [get_bd_intf_ports gpio] [get_bd_intf_pins gpio/GPIO]
  connect_bd_intf_net -intf_net s_axi_32_1 [get_bd_intf_ports saxi32a] [get_bd_intf_pins smartconnect/S01_AXI]
  connect_bd_intf_net -intf_net saxi32b_1 [get_bd_intf_ports saxi32b] [get_bd_intf_pins smartconnect/S02_AXI]
  connect_bd_intf_net -intf_net saxi64_1 [get_bd_intf_ports saxi64] [get_bd_intf_pins smartconnect/S03_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect/M00_AXI] [get_bd_intf_pins uart/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins gpio/S_AXI] [get_bd_intf_pins smartconnect/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_ports maxi32a] [get_bd_intf_pins smartconnect/M02_AXI]
  connect_bd_intf_net -intf_net smartconnect_M03_AXI [get_bd_intf_ports maxi32b] [get_bd_intf_pins smartconnect/M03_AXI]
  connect_bd_intf_net -intf_net smartconnect_M04_AXI [get_bd_intf_ports maxi32c] [get_bd_intf_pins smartconnect/M04_AXI]
  connect_bd_intf_net -intf_net smartconnect_M05_AXI [get_bd_intf_ports maxi128] [get_bd_intf_pins smartconnect/M05_AXI]

  # Create port connections
  connect_bd_net -net Clk_0_1 [get_bd_ports axi_clk] [get_bd_pins cpu/Clk] [get_bd_pins gpio/s_axi_aclk] [get_bd_pins ram/Clk] [get_bd_pins rstctrl/slowest_sync_clk] [get_bd_pins smartconnect/aclk] [get_bd_pins uart/s_axi_aclk]
  connect_bd_net -net dcm_locked_0_1 [get_bd_ports lock] [get_bd_pins rstctrl/dcm_locked]
  connect_bd_net -net ext_reset_in_0_1 [get_bd_ports rsti_n] [get_bd_pins rstctrl/ext_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins debug/Debug_SYS_Rst] [get_bd_pins rstctrl/mb_debug_sys_rst]
  connect_bd_net -net rst_Clk_100M_bus_struct_reset [get_bd_pins ram/SYS_Rst] [get_bd_pins rstctrl/bus_struct_reset]
  connect_bd_net -net rst_Clk_100M_mb_reset [get_bd_pins cpu/Reset] [get_bd_pins rstctrl/mb_reset]
  connect_bd_net -net rstctrl_interconnect_aresetn [get_bd_ports axi_rst_n] [get_bd_pins gpio/s_axi_aresetn] [get_bd_pins rstctrl/interconnect_aresetn] [get_bd_pins smartconnect/aresetn] [get_bd_pins uart/s_axi_aresetn]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs ram/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs maxi128/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs maxi32a/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs maxi32b/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs maxi32c/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces cpu/Data] [get_bd_addr_segs uart/S_AXI/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces cpu/Instruction] [get_bd_addr_segs ram/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32a] [get_bd_addr_segs gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces saxi32a] [get_bd_addr_segs maxi128/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32a] [get_bd_addr_segs maxi32a/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32a] [get_bd_addr_segs maxi32b/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32a] [get_bd_addr_segs maxi32c/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32a] [get_bd_addr_segs uart/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32b] [get_bd_addr_segs gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces saxi32b] [get_bd_addr_segs maxi128/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32b] [get_bd_addr_segs maxi32a/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32b] [get_bd_addr_segs maxi32b/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32b] [get_bd_addr_segs maxi32c/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi32b] [get_bd_addr_segs uart/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi64] [get_bd_addr_segs gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces saxi64] [get_bd_addr_segs maxi128/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi64] [get_bd_addr_segs maxi32a/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi64] [get_bd_addr_segs maxi32b/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi64] [get_bd_addr_segs maxi32c/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces saxi64] [get_bd_addr_segs uart/S_AXI/Reg] -force

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"1.0",
   "Default View_TopLeft":"-539,-19",
   "ExpandedHierarchyInLayout":"",
   "PinnedBlocks":"/ram|/gpio|/uart|/cpu|/rstctrl|/debug|/smartconnect|",
   "PinnedPorts":"gpio|uart|lock|rsti_n|axi_clk|axi_rst_n|maxi128|maxi32a|maxi32b|maxi32c|saxi32a|saxi32b|saxi64|",
   "guistr":"# # String gsaved with Nlview 7.0r6  2020-01-29 bk=1.5227 VDI=41 GEI=36 GUI=JA:10.0 non-TLS
#  -string -flagsOSRD
preplace port gpio -pg 1 -lvl 5 -x 1690 -y 360 -defaultsOSRD
preplace port maxi128 -pg 1 -lvl 5 -x 1690 -y 630 -defaultsOSRD
preplace port maxi32a -pg 1 -lvl 5 -x 1690 -y 570 -defaultsOSRD
preplace port maxi32b -pg 1 -lvl 5 -x 1690 -y 590 -defaultsOSRD
preplace port maxi32c -pg 1 -lvl 5 -x 1690 -y 610 -defaultsOSRD
preplace port saxi32a -pg 1 -lvl 0 -x -60 -y 550 -defaultsOSRD
preplace port saxi32b -pg 1 -lvl 0 -x -60 -y 570 -defaultsOSRD
preplace port saxi64 -pg 1 -lvl 0 -x -60 -y 590 -defaultsOSRD
preplace port uart -pg 1 -lvl 5 -x 1690 -y 210 -defaultsOSRD
preplace port port-id_axi_clk -pg 1 -lvl 0 -x -60 -y 340 -defaultsOSRD
preplace port port-id_lock -pg 1 -lvl 0 -x -60 -y 480 -defaultsOSRD
preplace port port-id_rsti_n -pg 1 -lvl 0 -x -60 -y 420 -defaultsOSRD
preplace portBus axi_rst_n -pg 1 -lvl 5 -x 1690 -y 460 -defaultsOSRD
preplace inst cpu -pg 1 -lvl 2 -x 780 -y 330 -defaultsOSRD
preplace inst debug -pg 1 -lvl 1 -x 350 -y 200 -defaultsOSRD
preplace inst gpio -pg 1 -lvl 4 -x 1500 -y 360 -defaultsOSRD
preplace inst ram -pg 1 -lvl 3 -x 1200 -y 340 -defaultsOSRD
preplace inst rstctrl -pg 1 -lvl 1 -x 350 -y 440 -defaultsOSRD
preplace inst smartconnect -pg 1 -lvl 3 -x 1200 -y 580 -defaultsOSRD
preplace inst uart -pg 1 -lvl 4 -x 1500 -y 220 -defaultsOSRD
preplace netloc Clk_0_1 1 0 4 -40J 340 520J 430 1050 420 1350
preplace netloc dcm_locked_0_1 1 0 1 N 480
preplace netloc ext_reset_in_0_1 1 0 1 N 420
preplace netloc mdm_1_debug_sys_rst 1 0 2 -30 270 520
preplace netloc rst_Clk_100M_bus_struct_reset 1 1 2 NJ 420 1040
preplace netloc rst_Clk_100M_mb_reset 1 1 1 530 360n
preplace netloc rstctrl_interconnect_aresetn 1 1 4 NJ 460 1020J 460 1360J 460 N
preplace netloc axi_uartlite_0_UART 1 4 1 NJ 210
preplace netloc cpu_M_AXI_DP 1 2 1 1030 350n
preplace netloc cpu_debug 1 1 1 530 190n
preplace netloc cpu_dlmb_1 1 2 1 N 310
preplace netloc cpu_ilmb_1 1 2 1 N 330
preplace netloc gpio_GPIO 1 4 1 NJ 360
preplace netloc s_axi_32_1 1 0 3 N 550 N 550 N
preplace netloc saxi32b_1 1 0 3 N 570 N 570 N
preplace netloc saxi64_1 1 0 3 N 590 N 590 N
preplace netloc smartconnect_0_M00_AXI 1 3 1 1340 200n
preplace netloc smartconnect_0_M01_AXI 1 3 1 1370 340n
preplace netloc smartconnect_0_M02_AXI 1 3 2 N 570 N
preplace netloc smartconnect_M03_AXI 1 3 2 NJ 590 NJ
preplace netloc smartconnect_M04_AXI 1 3 2 N 610 N
preplace netloc smartconnect_M05_AXI 1 3 2 N 630 N
levelinfo -pg 1 -60 350 780 1200 1500 1690
pagesize -pg 1 -db -bbox -sgen -160 -170 1830 1670
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


