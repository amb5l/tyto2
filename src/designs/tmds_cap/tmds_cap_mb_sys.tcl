
################################################################
# This is a generated script based on design: tmds_cap_mb_sys
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
# source tmds_cap_mb_sys_script.tcl


# The design that will be created by this Tcl script contains the following 
# block design container source references:
# axi_ddr3, tmds_cap_mb_cpu

# Please add the sources before sourcing this Tcl script.

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
set design_name tmds_cap_mb_sys

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
xilinx.com:ip:util_vector_logic:2.0\
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

##################################################################
# CHECK Block Design Container Sources
##################################################################
set bCheckSources 1
set list_bdc_active "axi_ddr3, tmds_cap_mb_cpu"

array set map_bdc_missing {}
set map_bdc_missing(ACTIVE) ""
set map_bdc_missing(BDC) ""

if { $bCheckSources == 1 } {
   set list_check_srcs "\ 
axi_ddr3 \
tmds_cap_mb_cpu \
"

   common::send_gid_msg -ssname BD::TCL -id 2056 -severity "INFO" "Checking if the following sources for block design container exist in the project: $list_check_srcs .\n\n"

   foreach src $list_check_srcs {
      if { [can_resolve_reference $src] == 0 } {
         if { [lsearch $list_bdc_active $src] != -1 } {
            set map_bdc_missing(ACTIVE) "$map_bdc_missing(ACTIVE) $src"
         } else {
            set map_bdc_missing(BDC) "$map_bdc_missing(BDC) $src"
         }
      }
   }

   if { [llength $map_bdc_missing(ACTIVE)] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2057 -severity "ERROR" "The following source(s) of Active variants are not found in the project: $map_bdc_missing(ACTIVE)" }
      common::send_gid_msg -ssname BD::TCL -id 2060 -severity "INFO" "Please add source files for the missing source(s) above."
      set bCheckIPsPassed 0
   }
   if { [llength $map_bdc_missing(BDC)] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2059 -severity "WARNING" "The following source(s) of variants are not found in the project: $map_bdc_missing(BDC)" }
      common::send_gid_msg -ssname BD::TCL -id 2060 -severity "INFO" "Please add source files for the missing source(s) above."
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
  set ddr3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr3 ]

  set eth_maxi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 eth_maxi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4} \
   ] $eth_maxi

  set eth_saxi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 eth_saxi ]
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
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $eth_saxi

  set gpio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio ]

  set tmds_maxi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 tmds_maxi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4} \
   ] $tmds_maxi

  set tmds_saxis [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 tmds_saxis ]
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
   ] $tmds_saxis


  # Create ports
  set axi_clk [ create_bd_port -dir O -type clk axi_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {tmds_maxi:eth_maxi:eth_saxi:tmds_saxis} \
   CONFIG.ASSOCIATED_RESET {axi_rst_n} \
 ] $axi_clk
  set axi_rst_n [ create_bd_port -dir O -from 0 -to 0 -type rst axi_rst_n ]
  set clk_200m [ create_bd_port -dir O -type clk clk_200m ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] $clk_200m
  set mig_rdy [ create_bd_port -dir O mig_rdy ]
  set mig_ref_clk [ create_bd_port -dir I -type clk mig_ref_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {mig_ref_rst_n} \
 ] $mig_ref_clk
  set mig_ref_rst_n [ create_bd_port -dir I -type rst mig_ref_rst_n ]

  # Create instance: axi_ddr3, and set properties
  set axi_ddr3 [ create_bd_cell -type container -reference axi_ddr3 axi_ddr3 ]
  set_property -dict [list \
    CONFIG.ACTIVE_SIM_BD {axi_ddr3.bd} \
    CONFIG.ACTIVE_SYNTH_BD {axi_ddr3.bd} \
    CONFIG.ENABLE_DFX {0} \
    CONFIG.LIST_SIM_BD {axi_ddr3.bd} \
    CONFIG.LIST_SYNTH_BD {axi_ddr3.bd} \
    CONFIG.LOCK_PROPAGATE {0} \
  ] $axi_ddr3


  # Create instance: axi_dma, and set properties
  set axi_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_s2mm_burst_size {256} \
    CONFIG.c_s_axis_s2mm_tdata_width {64} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_sg_length_width {26} \
  ] $axi_dma


  # Create instance: inverter, and set properties
  set inverter [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 inverter ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $inverter


  # Create instance: tmds_cap_mb_cpu, and set properties
  set tmds_cap_mb_cpu [ create_bd_cell -type container -reference tmds_cap_mb_cpu tmds_cap_mb_cpu ]
  set_property -dict [list \
    CONFIG.ACTIVE_SIM_BD {tmds_cap_mb_cpu.bd} \
    CONFIG.ACTIVE_SYNTH_BD {tmds_cap_mb_cpu.bd} \
    CONFIG.ENABLE_DFX {0} \
    CONFIG.LIST_SIM_BD {tmds_cap_mb_cpu.bd} \
    CONFIG.LIST_SYNTH_BD {tmds_cap_mb_cpu.bd} \
    CONFIG.LOCK_PROPAGATE {0} \
  ] $tmds_cap_mb_cpu


  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_S2MM_0_1 [get_bd_intf_ports tmds_saxis] [get_bd_intf_pins axi_dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net axi_ddr3_0_ddr3 [get_bd_intf_ports ddr3] [get_bd_intf_pins axi_ddr3/ddr3]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_dma/M_AXI_S2MM] [get_bd_intf_pins tmds_cap_mb_cpu/saxi64]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_SG [get_bd_intf_pins axi_dma/M_AXI_SG] [get_bd_intf_pins tmds_cap_mb_cpu/saxi32b]
  connect_bd_intf_net -intf_net saxi32a_0_1 [get_bd_intf_ports eth_saxi] [get_bd_intf_pins tmds_cap_mb_cpu/saxi32a]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_gpio [get_bd_intf_ports gpio] [get_bd_intf_pins tmds_cap_mb_cpu/gpio]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_maxi128 [get_bd_intf_pins axi_ddr3/axi] [get_bd_intf_pins tmds_cap_mb_cpu/maxi128]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_maxi32a [get_bd_intf_ports tmds_maxi] [get_bd_intf_pins tmds_cap_mb_cpu/maxi32a]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_maxi32b [get_bd_intf_ports eth_maxi] [get_bd_intf_pins tmds_cap_mb_cpu/maxi32b]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_maxi32c [get_bd_intf_pins axi_dma/S_AXI_LITE] [get_bd_intf_pins tmds_cap_mb_cpu/maxi32c]

  # Create port connections
  connect_bd_net -net axi_ddr3_0_axi_clk [get_bd_ports axi_clk] [get_bd_pins axi_ddr3/axi_clk] [get_bd_pins axi_dma/m_axi_s2mm_aclk] [get_bd_pins axi_dma/m_axi_sg_aclk] [get_bd_pins axi_dma/s_axi_lite_aclk] [get_bd_pins tmds_cap_mb_cpu/axi_clk]
  connect_bd_net -net axi_ddr3_0_clk_200m [get_bd_ports clk_200m] [get_bd_pins axi_ddr3/clk_200m]
  connect_bd_net -net axi_ddr3_0_lock [get_bd_pins axi_ddr3/lock] [get_bd_pins tmds_cap_mb_cpu/lock]
  connect_bd_net -net axi_ddr3_0_rdy [get_bd_ports mig_rdy] [get_bd_pins axi_ddr3/rdy]
  connect_bd_net -net axi_ddr3_0_rst [get_bd_pins axi_ddr3/rst] [get_bd_pins inverter/Op1]
  connect_bd_net -net mig_ref_clk_0_1 [get_bd_ports mig_ref_clk] [get_bd_pins axi_ddr3/mig_ref_clk]
  connect_bd_net -net mig_ref_rst_n_0_1 [get_bd_ports mig_ref_rst_n] [get_bd_pins axi_ddr3/mig_ref_rst_n]
  connect_bd_net -net tmds_cap_mb_0_axi_rst_n [get_bd_ports axi_rst_n] [get_bd_pins axi_ddr3/axi_rst_n] [get_bd_pins axi_dma/axi_resetn] [get_bd_pins tmds_cap_mb_cpu/axi_rst_n]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins inverter/Res] [get_bd_pins tmds_cap_mb_cpu/rsti_n]

  # Create address segments
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_S2MM] [get_bd_addr_segs eth_maxi/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_dma/Data_S2MM] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_S2MM] [get_bd_addr_segs tmds_maxi/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_SG] [get_bd_addr_segs eth_maxi/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces axi_dma/Data_SG] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_SG] [get_bd_addr_segs tmds_maxi/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs axi_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs eth_maxi/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs tmds_maxi/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces eth_saxi] [get_bd_addr_segs axi_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces eth_saxi] [get_bd_addr_segs eth_maxi/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces eth_saxi] [get_bd_addr_segs tmds_cap_mb_cpu/gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces eth_saxi] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces eth_saxi] [get_bd_addr_segs tmds_maxi/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces eth_saxi] [get_bd_addr_segs tmds_cap_mb_cpu/uart/S_AXI/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x41E00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_S2MM] [get_bd_addr_segs axi_dma/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_S2MM] [get_bd_addr_segs tmds_cap_mb_cpu/gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_S2MM] [get_bd_addr_segs tmds_cap_mb_cpu/uart/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x41E00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_SG] [get_bd_addr_segs axi_dma/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_SG] [get_bd_addr_segs tmds_cap_mb_cpu/gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma/Data_SG] [get_bd_addr_segs tmds_cap_mb_cpu/uart/S_AXI/Reg]

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"1.0",
   "Default View_TopLeft":"-863,-609",
   "ExpandedHierarchyInLayout":"",
   "PinnedBlocks":"/axi_ddr3|/axi_dma|/inverter|/tmds_cap_mb_cpu|",
   "PinnedPorts":"axi_clk|axi_rst_n|clk_200m|mig_rdy|mig_ref_clk|mig_ref_rst_n|ddr3|eth_maxi|eth_saxi|gpio|tmds_maxi|tmds_saxis|",
   "guistr":"# # String gsaved with Nlview 7.0r6  2020-01-29 bk=1.5227 VDI=41 GEI=36 GUI=JA:10.0 non-TLS
#  -string -flagsOSRD
preplace port ddr3 -pg 1 -lvl 5 -x 1170 -y -390 -defaultsOSRD
preplace port eth_maxi -pg 1 -lvl 5 -x 1170 -y -80 -defaultsOSRD
preplace port eth_saxi -pg 1 -lvl 0 -x -150 -y -190 -defaultsOSRD
preplace port gpio -pg 1 -lvl 5 -x 1170 -y -140 -defaultsOSRD
preplace port tmds_maxi -pg 1 -lvl 5 -x 1170 -y -100 -defaultsOSRD
preplace port tmds_saxis -pg 1 -lvl 0 -x -150 -y -110 -defaultsOSRD
preplace port port-id_axi_clk -pg 1 -lvl 5 -x 1170 -y -370 -defaultsOSRD
preplace port port-id_clk_200m -pg 1 -lvl 5 -x 1170 -y -350 -defaultsOSRD
preplace port port-id_mig_rdy -pg 1 -lvl 5 -x 1170 -y -310 -defaultsOSRD
preplace port port-id_mig_ref_clk -pg 1 -lvl 0 -x -150 -y -330 -defaultsOSRD
preplace port port-id_mig_ref_rst_n -pg 1 -lvl 0 -x -150 -y -310 -defaultsOSRD
preplace portBus axi_rst_n -pg 1 -lvl 5 -x 1170 -y -20 -defaultsOSRD
preplace inst axi_ddr3 -pg 1 -lvl 4 -x 1010 -y -340 -defaultsOSRD
preplace inst axi_dma -pg 1 -lvl 1 -x 60 -y -80 -defaultsOSRD
preplace inst inverter -pg 1 -lvl 2 -x 410 -y -10 -defaultsOSRD
preplace inst tmds_cap_mb_cpu -pg 1 -lvl 3 -x 740 -y -80 -defaultsOSRD
preplace netloc axi_ddr3_0_axi_clk 1 0 5 -110 30 230 -70 570 -450 N -450 1150
preplace netloc axi_ddr3_0_clk_200m 1 4 1 NJ -350
preplace netloc axi_ddr3_0_lock 1 2 3 580 -230 NJ -230 1150
preplace netloc axi_ddr3_0_rdy 1 4 1 N -310
preplace netloc axi_ddr3_0_rst 1 1 4 240 -200 NJ -200 NJ -200 1140
preplace netloc mig_ref_clk_0_1 1 0 4 NJ -330 N -330 NJ -330 NJ
preplace netloc mig_ref_rst_n_0_1 1 0 4 NJ -310 N -310 NJ -310 NJ
preplace netloc tmds_cap_mb_0_axi_rst_n 1 0 5 -120 60 NJ 60 NJ 60 880 -20 NJ
preplace netloc util_vector_logic_0_Res 1 2 1 570 -30n
preplace netloc S_AXIS_S2MM_0_1 1 0 1 N -110
preplace netloc axi_ddr3_0_ddr3 1 4 1 N -390
preplace netloc axi_dma_0_M_AXI_S2MM 1 1 2 N -90 N
preplace netloc axi_dma_0_M_AXI_SG 1 1 2 N -110 N
preplace netloc saxi32a_0_1 1 0 3 NJ -190 NJ -190 560J
preplace netloc tmds_cap_mb_cpu_0_gpio 1 3 2 NJ -140 NJ
preplace netloc tmds_cap_mb_cpu_0_maxi128 1 3 1 870 -370n
preplace netloc tmds_cap_mb_cpu_0_maxi32a 1 3 2 NJ -100 NJ
preplace netloc tmds_cap_mb_cpu_0_maxi32b 1 3 2 NJ -80 NJ
preplace netloc tmds_cap_mb_cpu_0_maxi32c 1 0 4 -130 50 N 50 N 50 870
levelinfo -pg 1 -150 60 410 740 1010 1170
pagesize -pg 1 -db -bbox -sgen -290 -720 1310 330
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


