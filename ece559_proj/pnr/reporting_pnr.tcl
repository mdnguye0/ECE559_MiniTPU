verify_drc > $RPT_DIR/drc.rpt
verifyConnectivity -type all > $RPT_DIR/connectivity.rpt
setAnalysisMode -analysisType onChipVariation
timeDesign -postRoute > $RPT_DIR/timeDesign_summary.rpt
report_timing > $RPT_DIR/timing.rpt
reportPower > $RPT_DIR/power.rpt 