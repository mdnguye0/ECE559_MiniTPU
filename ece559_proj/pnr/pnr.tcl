set aspect_ratio 1.0
set core_utilization 0.25
set core_to_io_spacing 10 



floorPlan -r $aspect_ratio $core_utilization $core_to_io_spacing $core_to_io_spacing $core_to_io_spacing $core_to_io_spacing 
# set_interactive_constraint_modes [all_constraint_modes -active]
# set_output_delay 0.400 -clock clk [all_outputs]
# set_input_delay 0.100 -clock clk [remove_from_collection [all_inputs] clk]
# set_interactive_constraint_modes {}
addRing -nets {VDD VSS} -type core_rings -follow core -layer {top Metal9 bottom Metal9 left Metal8 right Metal8} \
                        -width 1.25 -spacing 1.25 -offset 1.25 -center 1 


globalNetConnect VDD -type pgpin -pin VDD -instanceBasename *
globalNetConnect VSS -type pgpin -pin VSS -instanceBasename *
setSrouteMode -viaConnectToShape stripe
sroute 

setPlaceMode -place_global_place_io_pins true
placeDesign
optDesign -preCTS 

routeDesign -globalDetail
optDesign -postRoute