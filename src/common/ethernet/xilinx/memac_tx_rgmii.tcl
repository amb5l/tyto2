# memac_tx_rgmii.tcl

# check that required variables exist:
set check_vars {RGMII_TX_ALIGN rgmii_gtx_clk rgmii_ports_tx_clk rgmii_ports_tx_out}
foreach v $check_vars {
    if {![info exists $v]} {
        error "$v not defined"
    }
}

if {![llength [get_clocks -quiet rgmii_tx_clk]]} {
    create_generated_clock -name rgmii_tx_clk -source $rgmii_tx_clk_src -divide_by 1 $rgmii_ports_tx_clk
}
set rgmii_tx_clk [get_clocks rgmii_tx_clk]

if {$RGMII_TX_ALIGN == {"EDGE"}} {

    # edge aligned

    set_multicycle_path -setup -end 0 -rise_from $rgmii_gtx_clk -rise_to $rgmii_tx_clk
    set_multicycle_path -setup -end 0 -fall_from $rgmii_gtx_clk -fall_to $rgmii_tx_clk
    set_false_path      -setup        -rise_from $rgmii_gtx_clk -fall_to $rgmii_tx_clk
    set_false_path      -setup        -fall_from $rgmii_gtx_clk -rise_to $rgmii_tx_clk
    set_false_path      -hold         -rise_from $rgmii_gtx_clk -rise_to $rgmii_tx_clk
    set_false_path      -hold         -fall_from $rgmii_gtx_clk -fall_to $rgmii_tx_clk

    set Tskew 0.5
    set_output_delay -max -$Tskew -clock $rgmii_tx_clk             $rgmii_ports_tx_out
    set_output_delay -max -$Tskew -clock $rgmii_tx_clk -clock_fall $rgmii_ports_tx_out -add_delay
    set_output_delay -min  $Tskew -clock $rgmii_tx_clk             $rgmii_ports_tx_out
    set_output_delay -min  $Tskew -clock $rgmii_tx_clk -clock_fall $rgmii_ports_tx_out -add_delay

} elseif {$RGMII_TX_ALIGN == {"CENTER"}}  {

    # center aligned

    set Tsu 1.2
    set Th  1.2
    set_output_delay -max  $Tsu -clock $rgmii_tx_clk             $rgmii_ports_tx_out
    set_output_delay -max  $Tsu -clock $rgmii_tx_clk -clock_fall $rgmii_ports_tx_out -add_delay
    set_output_delay -min -$Th  -clock $rgmii_tx_clk             $rgmii_ports_tx_out
    set_output_delay -min -$Th  -clock $rgmii_tx_clk -clock_fall $rgmii_ports_tx_out -add_delay

} else {
  error "RGMII TX alignment should be EDGE or CENTER... got $RGMII_TX_ALIGN instead"
}
