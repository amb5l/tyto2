# memac_rx_rgmii.tcl

# check that required variables exist
set check_vars {RGMII_RX_ALIGN rgmii_ports_rx_clk rgmii_ports_rx_in}
foreach v $check_vars {
    if {![info exists $v]} {
        error "$v not defined"
    }
}

create_clock -add -name rgmii_rx_tclk -period 8.00
set rgmii_rx_tclk [get_clocks rgmii_rx_tclk]
create_clock -add -name rgmii_rx_rclk -period 8.00 $rgmii_ports_rx_clk
set rgmii_rx_rclk [get_clocks rgmii_rx_rclk]

# apply constraints according to alignment used in the design
if {$RGMII_RX_ALIGN == {"EDGE"}} {

    # edge aligned

    set_multicycle_path 0 -rise_from $rgmii_rx_tclk -rise_to $rgmii_rx_rclk
    set_multicycle_path 0 -fall_from $rgmii_rx_tclk -fall_to $rgmii_rx_rclk
    set_false_path -setup -rise_from $rgmii_rx_tclk -fall_to $rgmii_rx_rclk
    set_false_path -hold  -rise_from $rgmii_rx_tclk -rise_to $rgmii_rx_rclk
    set_false_path -setup -fall_from $rgmii_rx_tclk -rise_to $rgmii_rx_rclk
    set_false_path -hold  -fall_from $rgmii_rx_tclk -fall_to $rgmii_rx_rclk

    set Tskew 0.5
    set_input_delay -clock $rgmii_rx_tclk             -max  $Tskew $rgmii_ports_rx_in
    set_input_delay -clock $rgmii_rx_tclk -clock_fall -max  $Tskew $rgmii_ports_rx_in -add_delay
    set_input_delay -clock $rgmii_rx_tclk             -min -$Tskew $rgmii_ports_rx_in
    set_input_delay -clock $rgmii_rx_tclk -clock_fall -min -$Tskew $rgmii_ports_rx_in -add_delay

} elseif {$RGMII_RX_ALIGN == {"CENTER"}} {

    # center aligned

    set Tsu 1.0
    set Th  1.0
    set_input_delay -clock $rgmii_rx_tclk             -max [expr 4.0-$Tsu] $rgmii_ports_rx_in
    set_input_delay -clock $rgmii_rx_tclk -clock_fall -max [expr 4.0-$Tsu] $rgmii_ports_rx_in -add_delay
    set_input_delay -clock $rgmii_rx_tclk             -min $Th             $rgmii_ports_rx_in
    set_input_delay -clock $rgmii_rx_tclk -clock_fall -min $Th             $rgmii_ports_rx_in -add_delay

} else {
  error "RGMII RX alignment should be EDGE or CENTER... got $RGMII_RX_ALIGN instead"
}
