set PNR_DIR ../pnr
set CLK_PER 5.0 
set CLK_SKEW 0.05 
create_clock -name $CLK_NAME -period $CLK_PER -waveform "0 [expr $CLK_PER / 2.0]"  $CLK_NAME 
set_clock_uncertainty $CLK_SKEW $CLK_NAME 

set ip_delay 0.1 
set_input_delay $ip_delay -clock $CLK_NAME  [remove_from_collection [all_inputs] $CLK_NAME] 

set op_delay 0.4 
set_output_delay $op_delay -clock $CLK_NAME [all_outputs] 

set dr_cell_name DFFRX1 
set dr_cell_pin 0 
set_driving_cell -lib_cell $dr_cell_name -pin $dr_cell_pin [remove_from_collection [all_inputs] $CLK_NAME] 

set port_load_cell slow_vdd1v0/DFFRX1/D 
set wire_load_est 0.0
set fanout 1
set port_load [expr $wire_load_est + $fanout * [load_of $port_load_cell]] 
set_load $port_load [all_outputs] 

set max_area 0 
set_fix_multiple_port_nets -all -buffer_constrants [get_designs] 
replace_synthetic -ungroup 

check_design 
link 
write_sdc $PNR_DIR/constraints.sdc 

