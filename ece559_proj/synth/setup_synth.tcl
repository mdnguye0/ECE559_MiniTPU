#####################################################################
# setup_synth.tcl
#####################################################################

set CLK_NAME clk 
set MOD_NAME tpu_top 

set RPT_DIR rpt 
file mkdir $RPT_DIR 
set PNR_DIR ../pnr 
file mkdir $PNR_DIR 

set synthetic_library [list dw_foundation.sldb] 
set link_library [list gpdk045_slow.db] 
set target_library gpdk045_slow.db

set RTL_DIR ../modules/sources/ 

analyze -format sverilog [list \
    $RTL_DIR/pe.sv \
    $RTL_DIR/systolic_array.sv \
    $RTL_DIR/input_fifo.sv \
    $RTL_DIR/act_sram.sv \
    $RTL_DIR/act_skew_buffer.sv \
    $RTL_DIR/weight_fifo.sv \
    $RTL_DIR/weight_sram.sv \
    $RTL_DIR/weight_controller.sv \
    $RTL_DIR/tpu_top.sv \
] 
elaborate $MOD_NAME
current design $MOD_NAME 
set report_default_significant_digits 4 

