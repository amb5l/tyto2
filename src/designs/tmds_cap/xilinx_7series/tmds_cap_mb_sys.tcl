
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

  set emac_maxis [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 emac_maxis ]

  set emac_saxis [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 emac_saxis ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.PHASE {0} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $emac_saxis

  set eth_maxi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 eth_maxi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4} \
   ] $eth_maxi

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

  set uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart ]


  # Create ports
  set axi_clk [ create_bd_port -dir O -type clk axi_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {tmds_maxi:eth_maxi:tmds_saxis:emac_saxis:emac_maxis} \
   CONFIG.ASSOCIATED_RESET {axi_rst_n} \
 ] $axi_clk
  set axi_rst_n [ create_bd_port -dir I -type rst axi_rst_n ]
  set clk_200m [ create_bd_port -dir O -type clk clk_200m ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
 ] $clk_200m
  set cpu_lock [ create_bd_port -dir I cpu_lock ]
  set cpu_rsti_n [ create_bd_port -dir I -type rst cpu_rsti_n ]
  set cpu_rsto_n [ create_bd_port -dir O -from 0 -to 0 -type rst cpu_rsto_n ]
  set mig_clk [ create_bd_port -dir I -type clk mig_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {mig_rsti_n} \
 ] $mig_clk
  set mig_lock [ create_bd_port -dir O mig_lock ]
  set mig_rdyo [ create_bd_port -dir O mig_rdyo ]
  set mig_rst [ create_bd_port -dir O -type rst mig_rst ]
  set mig_rsti_n [ create_bd_port -dir I -type rst mig_rsti_n ]

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


  # Create instance: axi_dma_emac, and set properties
  set axi_dma_emac [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_emac ]
  set_property -dict [list \
    CONFIG.c_enable_multi_channel {0} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_mm2s_burst_size {256} \
    CONFIG.c_s2mm_burst_size {256} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_sg_length_width {16} \
  ] $axi_dma_emac


  # Create instance: axi_dma_tmds, and set properties
  set axi_dma_tmds [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_tmds ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_s2mm_burst_size {256} \
    CONFIG.c_s_axis_s2mm_tdata_width {64} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_sg_length_width {26} \
  ] $axi_dma_tmds


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
  connect_bd_intf_net -intf_net S_AXIS_S2MM_0_1 [get_bd_intf_ports tmds_saxis] [get_bd_intf_pins axi_dma_tmds/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net S_AXIS_S2MM_0_2 [get_bd_intf_ports emac_saxis] [get_bd_intf_pins axi_dma_emac/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net axi_ddr3_0_ddr3 [get_bd_intf_ports ddr3] [get_bd_intf_pins axi_ddr3/ddr3]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_dma_tmds/M_AXI_S2MM] [get_bd_intf_pins tmds_cap_mb_cpu/saxi64]
  connect_bd_intf_net -intf_net axi_dma_enet_M_AXIS_MM2S [get_bd_intf_ports emac_maxis] [get_bd_intf_pins axi_dma_emac/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net axi_dma_enet_M_AXI_MM2S [get_bd_intf_pins axi_dma_emac/M_AXI_MM2S] [get_bd_intf_pins tmds_cap_mb_cpu/saxi32c]
  connect_bd_intf_net -intf_net axi_dma_enet_M_AXI_S2MM [get_bd_intf_pins axi_dma_emac/M_AXI_S2MM] [get_bd_intf_pins tmds_cap_mb_cpu/saxi32d]
  connect_bd_intf_net -intf_net axi_dma_enet_M_AXI_SG [get_bd_intf_pins axi_dma_emac/M_AXI_SG] [get_bd_intf_pins tmds_cap_mb_cpu/saxi32b]
  connect_bd_intf_net -intf_net axi_dma_tmds_M_AXI_SG [get_bd_intf_pins axi_dma_tmds/M_AXI_SG] [get_bd_intf_pins tmds_cap_mb_cpu/saxi32a]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_gpio [get_bd_intf_ports gpio] [get_bd_intf_pins tmds_cap_mb_cpu/gpio]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_maxi128 [get_bd_intf_pins axi_ddr3/axi] [get_bd_intf_pins tmds_cap_mb_cpu/maxi128]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_maxi32a [get_bd_intf_ports tmds_maxi] [get_bd_intf_pins tmds_cap_mb_cpu/maxi32a]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_maxi32b [get_bd_intf_ports eth_maxi] [get_bd_intf_pins tmds_cap_mb_cpu/maxi32b]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_0_maxi32c [get_bd_intf_pins axi_dma_tmds/S_AXI_LITE] [get_bd_intf_pins tmds_cap_mb_cpu/maxi32c]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_maxi32d [get_bd_intf_pins axi_dma_emac/S_AXI_LITE] [get_bd_intf_pins tmds_cap_mb_cpu/maxi32d]
  connect_bd_intf_net -intf_net tmds_cap_mb_cpu_uart [get_bd_intf_ports uart] [get_bd_intf_pins tmds_cap_mb_cpu/uart]

  # Create port connections
  connect_bd_net -net axi_ddr3_0_axi_clk [get_bd_ports axi_clk] [get_bd_pins axi_ddr3/axi_clk] [get_bd_pins axi_dma_emac/m_axi_mm2s_aclk] [get_bd_pins axi_dma_emac/m_axi_s2mm_aclk] [get_bd_pins axi_dma_emac/m_axi_sg_aclk] [get_bd_pins axi_dma_emac/s_axi_lite_aclk] [get_bd_pins axi_dma_tmds/m_axi_s2mm_aclk] [get_bd_pins axi_dma_tmds/m_axi_sg_aclk] [get_bd_pins axi_dma_tmds/s_axi_lite_aclk] [get_bd_pins tmds_cap_mb_cpu/clk]
  connect_bd_net -net axi_ddr3_0_clk_200m [get_bd_ports clk_200m] [get_bd_pins axi_ddr3/clk_200m]
  connect_bd_net -net axi_ddr3_0_rdy [get_bd_ports mig_rdyo] [get_bd_pins axi_ddr3/rdy]
  connect_bd_net -net axi_ddr3_lock [get_bd_ports mig_lock] [get_bd_pins axi_ddr3/lock]
  connect_bd_net -net axi_ddr3_rst [get_bd_ports mig_rst] [get_bd_pins axi_ddr3/rst]
  connect_bd_net -net lock_0_1 [get_bd_ports cpu_lock] [get_bd_pins tmds_cap_mb_cpu/lock]
  connect_bd_net -net mig_ref_clk_0_1 [get_bd_ports mig_clk] [get_bd_pins axi_ddr3/ref_clk]
  connect_bd_net -net mig_ref_rst_n_0_1 [get_bd_ports mig_rsti_n] [get_bd_pins axi_ddr3/ref_rst_n]
  connect_bd_net -net rsti_n_0_1 [get_bd_ports cpu_rsti_n] [get_bd_pins tmds_cap_mb_cpu/rsti_n]
  connect_bd_net -net tmds_cap_mb_0_axi_rst_n [get_bd_ports axi_rst_n] [get_bd_pins axi_ddr3/axi_rst_n] [get_bd_pins axi_dma_emac/axi_resetn] [get_bd_pins axi_dma_tmds/axi_resetn]
  connect_bd_net -net tmds_cap_mb_cpu_rsto_n [get_bd_ports cpu_rsto_n] [get_bd_pins tmds_cap_mb_cpu/rsto_n]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_MM2S] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_S2MM] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_SG] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_S2MM] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_SG] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs axi_ddr3/mig/memmap/memaddr] -force
  assign_bd_address -offset 0x70000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs tmds_maxi/Reg] -force
  assign_bd_address -offset 0x70010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs eth_maxi/Reg] -force
  assign_bd_address -offset 0x70020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs axi_dma_tmds/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x70030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmds_cap_mb_cpu/cpu/Data] [get_bd_addr_segs axi_dma_emac/S_AXI_LITE/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x70030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_MM2S] [get_bd_addr_segs axi_dma_emac/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_MM2S] [get_bd_addr_segs axi_dma_tmds/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_MM2S] [get_bd_addr_segs eth_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_MM2S] [get_bd_addr_segs tmds_cap_mb_cpu/gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x70000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_MM2S] [get_bd_addr_segs tmds_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_MM2S] [get_bd_addr_segs tmds_cap_mb_cpu/uart/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x41E00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_S2MM] [get_bd_addr_segs axi_dma_emac/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_S2MM] [get_bd_addr_segs axi_dma_tmds/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_S2MM] [get_bd_addr_segs eth_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_S2MM] [get_bd_addr_segs tmds_cap_mb_cpu/gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x70000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_S2MM] [get_bd_addr_segs tmds_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_S2MM] [get_bd_addr_segs tmds_cap_mb_cpu/uart/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x41E00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_SG] [get_bd_addr_segs axi_dma_emac/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_SG] [get_bd_addr_segs axi_dma_tmds/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_SG] [get_bd_addr_segs eth_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_SG] [get_bd_addr_segs tmds_cap_mb_cpu/gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x70000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_SG] [get_bd_addr_segs tmds_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_emac/Data_SG] [get_bd_addr_segs tmds_cap_mb_cpu/uart/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x70030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_S2MM] [get_bd_addr_segs axi_dma_emac/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_S2MM] [get_bd_addr_segs axi_dma_tmds/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_S2MM] [get_bd_addr_segs eth_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_S2MM] [get_bd_addr_segs tmds_cap_mb_cpu/gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x70000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_S2MM] [get_bd_addr_segs tmds_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_S2MM] [get_bd_addr_segs tmds_cap_mb_cpu/uart/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x70030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_SG] [get_bd_addr_segs axi_dma_emac/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_SG] [get_bd_addr_segs axi_dma_tmds/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x70010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_SG] [get_bd_addr_segs eth_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_SG] [get_bd_addr_segs tmds_cap_mb_cpu/gpio/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x70000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_SG] [get_bd_addr_segs tmds_maxi/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_dma_tmds/Data_SG] [get_bd_addr_segs tmds_cap_mb_cpu/uart/S_AXI/Reg]

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"1.0",
   "Default View_TopLeft":"-860,-528",
   "ExpandedHierarchyInLayout":"",
   "PinnedBlocks":"/axi_ddr3|/axi_dma_tmds|/tmds_cap_mb_cpu|/axi_dma_emac|",
   "PinnedPorts":"axi_clk|clk_200m|mig_clk|mig_lock|mig_rst|cpu_rsto_n|cpu_rsti_n|cpu_lock|axi_rst_n|ddr3|eth_maxi|gpio|tmds_maxi|tmds_saxis|emac_saxis|emac_maxis|uart|",
   "guistr":"# # String gsaved with Nlview 7.0r6  2020-01-29 bk=1.5227 VDI=41 GEI=36 GUI=JA:10.0 non-TLS
#  -string -flagsOSRD
preplace port ddr3 -pg 1 -lvl 4 -x 1220 -y -390 -defaultsOSRD
preplace port eth_maxi -pg 1 -lvl 4 -x 1220 -y -90 -defaultsOSRD
preplace port gpio -pg 1 -lvl 4 -x 1220 -y -150 -defaultsOSRD
preplace port tmds_maxi -pg 1 -lvl 4 -x 1220 -y -110 -defaultsOSRD
preplace port tmds_saxis -pg 1 -lvl 0 -x -220 -y -150 -defaultsOSRD
preplace port emac_saxis -pg 1 -lvl 0 -x -220 -y 80 -defaultsOSRD
preplace port emac_maxis -pg 1 -lvl 4 -x 1220 -y 110 -defaultsOSRD
preplace port uart -pg 1 -lvl 4 -x 1220 -y -70 -defaultsOSRD
preplace port port-id_axi_clk -pg 1 -lvl 4 -x 1220 -y -370 -defaultsOSRD
preplace port port-id_clk_200m -pg 1 -lvl 4 -x 1220 -y -350 -defaultsOSRD
preplace port port-id_mig_rdyo -pg 1 -lvl 4 -x 1220 -y -310 -defaultsOSRD
preplace port port-id_mig_clk -pg 1 -lvl 0 -x -220 -y -330 -defaultsOSRD
preplace port port-id_mig_rsti_n -pg 1 -lvl 0 -x -220 -y -310 -defaultsOSRD
preplace port port-id_mig_lock -pg 1 -lvl 4 -x 1220 -y -330 -defaultsOSRD
preplace port port-id_mig_rst -pg 1 -lvl 4 -x 1220 -y -290 -defaultsOSRD
preplace port port-id_cpu_rsti_n -pg 1 -lvl 0 -x -220 -y -10 -defaultsOSRD
preplace port port-id_cpu_lock -pg 1 -lvl 0 -x -220 -y -250 -defaultsOSRD
preplace port port-id_axi_rst_n -pg 1 -lvl 0 -x -220 -y -350 -defaultsOSRD
preplace portBus cpu_rsto_n -pg 1 -lvl 4 -x 1220 -y -10 -defaultsOSRD
preplace inst axi_ddr3 -pg 1 -lvl 3 -x 1080 -y -340 -defaultsOSRD
preplace inst axi_dma_tmds -pg 1 -lvl 1 -x 0 -y -120 -defaultsOSRD
preplace inst tmds_cap_mb_cpu -pg 1 -lvl 2 -x 700 -y -80 -defaultsOSRD
preplace inst axi_dma_emac -pg 1 -lvl 1 -x 0 -y 120 -defaultsOSRD
preplace netloc axi_ddr3_0_axi_clk 1 0 4 -180 -240 180 -220 N -220 1200
preplace netloc axi_ddr3_0_clk_200m 1 3 1 NJ -350
preplace netloc axi_ddr3_0_rdy 1 3 1 N -310
preplace netloc mig_ref_clk_0_1 1 0 3 NJ -330 N -330 N
preplace netloc mig_ref_rst_n_0_1 1 0 3 NJ -310 N -310 N
preplace netloc tmds_cap_mb_0_axi_rst_n 1 0 3 -200 -350 N -350 N
preplace netloc axi_ddr3_lock 1 3 1 N -330
preplace netloc axi_ddr3_rst 1 3 1 N -290
preplace netloc tmds_cap_mb_cpu_rsto_n 1 2 2 NJ -10 NJ
preplace netloc rsti_n_0_1 1 0 2 NJ -10 NJ
preplace netloc lock_0_1 1 0 2 NJ -250 190J
preplace netloc S_AXIS_S2MM_0_1 1 0 1 N -150
preplace netloc axi_ddr3_0_ddr3 1 3 1 N -390
preplace netloc axi_dma_0_M_AXI_S2MM 1 1 1 N -130
preplace netloc tmds_cap_mb_cpu_0_gpio 1 2 2 NJ -150 NJ
preplace netloc tmds_cap_mb_cpu_0_maxi128 1 2 1 850 -370n
preplace netloc tmds_cap_mb_cpu_0_maxi32a 1 2 2 NJ -110 NJ
preplace netloc tmds_cap_mb_cpu_0_maxi32b 1 2 2 NJ -90 NJ
preplace netloc tmds_cap_mb_cpu_0_maxi32c 1 0 3 -170 -230 N -230 830
preplace netloc axi_dma_tmds_M_AXI_SG 1 1 1 N -150
preplace netloc axi_dma_enet_M_AXI_SG 1 1 1 170 -110n
preplace netloc axi_dma_enet_M_AXI_MM2S 1 1 1 200 -90n
preplace netloc axi_dma_enet_M_AXI_S2MM 1 1 1 210 -70n
preplace netloc tmds_cap_mb_cpu_maxi32d 1 0 3 -190 -260 N -260 840
preplace netloc S_AXIS_S2MM_0_2 1 0 1 N 80
preplace netloc axi_dma_enet_M_AXIS_MM2S 1 1 3 NJ 110 NJ 110 NJ
preplace netloc tmds_cap_mb_cpu_uart 1 2 2 NJ -70 NJ
levelinfo -pg 1 -220 0 700 1080 1220
pagesize -pg 1 -db -bbox -sgen -350 -720 1370 670
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


