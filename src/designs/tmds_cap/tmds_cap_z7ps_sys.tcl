
################################################################
# This is a generated script based on design: tmds_cap_z7ps_sys
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
set scripts_vivado_version 2023.1
set current_vivado_version [version -short]

# skip version check
#if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
#   puts ""
#   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}
#
#   return 1
#}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source tmds_cap_z7ps_sys_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg400-1
   set_property BOARD_PART digilentinc.com:zybo-z7-20:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name tmds_cap_z7ps_sys

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
xilinx.com:ip:axi_dma:7.1\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:processing_system7:5.5\
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

  set tmds_maxi32 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 tmds_maxi32 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.PROTOCOL {AXI4} \
   ] $tmds_maxi32

  set tmds_saxis64 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 tmds_saxis64 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {8} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $tmds_saxis64


  # Create ports
  set axi_clk [ create_bd_port -dir O -type clk axi_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {tmds_saxis64:tmds_maxi32} \
   CONFIG.ASSOCIATED_RESET {axi_rst_n} \
 ] $axi_clk
  set axi_rst_n [ create_bd_port -dir O -from 0 -to 0 -type rst axi_rst_n ]

  # Create instance: axi_dma, and set properties
  set axi_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_sg {0} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_s2mm_burst_size {256} \
    CONFIG.c_s_axis_s2mm_tdata_width {64} \
    CONFIG.c_sg_length_width {26} \
  ] $axi_dma


  # Create instance: axi_mem_intercon1, and set properties
  set axi_mem_intercon1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon1 ]
  set_property CONFIG.NUM_MI {1} $axi_mem_intercon1


  # Create instance: axi_mem_intercon2, and set properties
  set axi_mem_intercon2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon2 ]
  set_property CONFIG.NUM_MI {1} $axi_mem_intercon2


  # Create instance: axi_gpio, and set properties
  set axi_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio ]

  # Create instance: ps_reset, and set properties
  set ps_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 ps_reset ]

  # Create instance: smartconnect, and set properties
  set smartconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect ]
  set_property -dict [list \
    CONFIG.NUM_MI {3} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect


  # Create instance: z7ps, and set properties
  set z7ps [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 z7ps ]
  set_property -dict [list \
    CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
    CONFIG.PCW_USE_S_AXI_HP0 {1} \
  ] $z7ps


  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_S2MM_0_1 [get_bd_intf_ports tmds_saxis64] [get_bd_intf_pins axi_dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_dma/M_AXI_S2MM] [get_bd_intf_pins axi_mem_intercon2/S00_AXI]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports gpio] [get_bd_intf_pins axi_gpio/GPIO]
  connect_bd_intf_net -intf_net axi_mem_intercon2_M00_AXI [get_bd_intf_pins axi_mem_intercon2/M00_AXI] [get_bd_intf_pins z7ps/S_AXI_HP0]
  connect_bd_intf_net -intf_net axi_mem_intercon3_M00_AXI [get_bd_intf_pins axi_dma/S_AXI_LITE] [get_bd_intf_pins axi_mem_intercon1/M00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins z7ps/M_AXI_GP0] [get_bd_intf_pins smartconnect/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins axi_gpio/S_AXI] [get_bd_intf_pins smartconnect/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins axi_mem_intercon1/S00_AXI] [get_bd_intf_pins smartconnect/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_ports tmds_maxi32] [get_bd_intf_pins smartconnect/M02_AXI]

  # Create port connections
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins z7ps/FCLK_RESET0_N] [get_bd_pins ps_reset/ext_reset_in]
  connect_bd_net -net z7ps_FCLK_CLK0 [get_bd_pins z7ps/FCLK_CLK0] [get_bd_ports axi_clk] [get_bd_pins axi_dma/m_axi_s2mm_aclk] [get_bd_pins axi_dma/s_axi_lite_aclk] [get_bd_pins axi_mem_intercon1/ACLK] [get_bd_pins axi_mem_intercon1/M00_ACLK] [get_bd_pins axi_mem_intercon1/S00_ACLK] [get_bd_pins axi_mem_intercon2/ACLK] [get_bd_pins axi_mem_intercon2/M00_ACLK] [get_bd_pins axi_mem_intercon2/S00_ACLK] [get_bd_pins axi_gpio/s_axi_aclk] [get_bd_pins ps_reset/slowest_sync_clk] [get_bd_pins smartconnect/aclk] [get_bd_pins z7ps/S_AXI_HP0_ACLK] [get_bd_pins z7ps/M_AXI_GP0_ACLK]
  connect_bd_net -net z7ps_FCLK_RESET0_N [get_bd_pins ps_reset/peripheral_aresetn] [get_bd_ports axi_rst_n] [get_bd_pins axi_dma/axi_resetn] [get_bd_pins axi_mem_intercon1/ARESETN] [get_bd_pins axi_mem_intercon1/M00_ARESETN] [get_bd_pins axi_mem_intercon1/S00_ARESETN] [get_bd_pins axi_mem_intercon2/ARESETN] [get_bd_pins axi_mem_intercon2/M00_ARESETN] [get_bd_pins axi_mem_intercon2/S00_ARESETN] [get_bd_pins axi_gpio/s_axi_aresetn] [get_bd_pins smartconnect/aresetn]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_dma/Data_S2MM] [get_bd_addr_segs z7ps/S_AXI_HP0/HP0_DDR_LOWOCM] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces z7ps/Data] [get_bd_addr_segs axi_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces z7ps/Data] [get_bd_addr_segs axi_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces z7ps/Data] [get_bd_addr_segs tmds_maxi32/Reg] -force

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"1.0",
   "Default View_TopLeft":"-493,-86",
   "ExpandedHierarchyInLayout":"",
   "PinnedBlocks":"/axi_dma|/axi_mem_intercon2|/ps_reset|/axi_mem_intercon1|/axi_gpio|/smartconnect|",
   "PinnedPorts":"axi_clk|axi_rst_n|tmds_saxis64|gpio|tmds_maxi32|",
   "guistr":"# # String gsaved with Nlview 7.5.8 2022-09-21 7111 VDI=41 GEI=38 GUI=JA:10.0
#  -string -flagsOSRD
preplace port gpio -pg 1 -lvl 6 -x 1810 -y 220 -defaultsOSRD
preplace port tmds_maxi32 -pg 1 -lvl 6 -x 1810 -y 400 -defaultsOSRD
preplace port tmds_saxis64 -pg 1 -lvl 0 -x -50 -y 270 -defaultsOSRD
preplace port port-id_axi_clk -pg 1 -lvl 6 -x 1810 -y 490 -defaultsOSRD
preplace portBus axi_rst_n -pg 1 -lvl 6 -x 1810 -y 640 -defaultsOSRD
preplace inst axi_dma -pg 1 -lvl 2 -x 510 -y 290 -defaultsOSRD
preplace inst axi_mem_intercon1 -pg 1 -lvl 1 -x 130 -y 90 -defaultsOSRD
preplace inst axi_mem_intercon2 -pg 1 -lvl 3 -x 860 -y 350 -defaultsOSRD -resize 230 194
preplace inst axi_gpio -pg 1 -lvl 5 -x 1640 -y 220 -defaultsOSRD
preplace inst ps_reset -pg 1 -lvl 4 -x 1240 -y 600 -defaultsOSRD
preplace inst smartconnect -pg 1 -lvl 5 -x 1640 -y 380 -defaultsOSRD
preplace inst z7ps -pg 1 -lvl 4 -x 1240 -y 360 -defaultsOSRD
preplace netloc z7ps_FCLK_CLK0 1 0 6 -20 210 330 180 720 470 1000 460 1480 490 NJ
preplace netloc z7ps_FCLK_RESET0_N 1 0 6 -30 220 340 190 700 480 NJ 480 1490 640 NJ
preplace netloc processing_system7_0_FCLK_RESET0_N 1 3 2 1010 470 1470
preplace netloc S_AXIS_S2MM_0_1 1 0 2 NJ 270 NJ
preplace netloc axi_dma_0_M_AXI_S2MM 1 2 1 710 270n
preplace netloc axi_gpio_0_GPIO 1 5 1 N 220
preplace netloc axi_mem_intercon3_M00_AXI 1 1 1 280 90n
preplace netloc smartconnect_0_M00_AXI 1 4 2 1500 300 1780
preplace netloc smartconnect_0_M01_AXI 1 0 6 -20 -30 N -30 N -30 N -30 N -30 1790
preplace netloc smartconnect_0_M02_AXI 1 5 1 N 400
preplace netloc axi_mem_intercon2_M00_AXI 1 3 1 N 350
preplace netloc processing_system7_0_M_AXI_GP0 1 4 1 N 360
levelinfo -pg 1 -50 130 510 860 1240 1640 1810
pagesize -pg 1 -db -bbox -sgen -190 -40 1950 730
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


