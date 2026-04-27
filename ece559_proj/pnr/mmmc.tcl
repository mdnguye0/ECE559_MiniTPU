create_library_set -name lib_slow_1v0 -timing [list lib/slow_vdd1v0_basicCells.lib]
create_library_set -name lib_fast_1v0 -timing [list lib/fast_vdd1v0_basicCells.lib]

create_constraint_mode -name mode_default -sdc_files constraints.sdc

set QRC_PATH /opt/cadence/gpdk045/gpdk045_v_6_0/qrc
create_rc_corner -name rc_slow -qx_tech_file $QRC_PATH/rcworst/qrcTechFile
create_rc_corner -name rc_fast -qx_tech_file $QRC_PATH/rcbest/qrcTechFile

create_delay_corner -name dc_slow_1v0 -library_set {lib_slow_1v0} -rc_corner {rc_slow}
create_delay_corner -name dc_fast_1v0 -library_set {lib_fast_1v0} -rc_corner {rc_fast}

create_analysis_view -name worst_1v0 -constraint_mode {mode_default} -delay_corner {dc_slow_1v0}
create_analysis_view -name best_1v0 -constraint_mode {mode_default} -delay_corner {dc_fast_1v0}

set_analysis_view -setup {worst_1v0} -hold {best_1v0}