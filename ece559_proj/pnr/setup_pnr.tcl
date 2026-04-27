set init_lef_file [list lib/gsclib045.lef]
set init_verilog netlist.v
set init_top_cell tpu_top
set init_mmmc_file mmmc.tcl 

set init_pwr_net VDD
set init_gnd_net VSS 

setDesignMode -process 45
set RPT_DIR rpt
file mkdir $RPT_DIR