set PNR_DIR ../pnr
set RPT_DIR rpt

check_timing 
report_timing -delay_type max > $RPT_DIR/timing_max.rpt
report_timing -delay_type min > $RPT_DIR/timing_min.rpt
report_cell                   > $RPT_DIR/cell_report.rpt 
report_power                  > $RPT_DIR/power_report.rpt 

write_file -hierarchy -f verilog -o $RPT_DIR/netlist.v 
write_file -hierarchy -f verilog -o $PNR_DIR/netlist.v 

