import uvm_pkg::*; 
`include "uvm_macros.svh" 

class weight_item extends uvm_sequence_item; 

rand bit signed [15:0] weights[256]; 

`uvm_object_utils_begin(weight_item) 
    `uvm_field_sarray_int(weights, UVM_ALL_ON) 
`uvm_object_utils_end 

function new (string name = "weight_item"); 
    super.new(name); 
endfunction 

constraint c_basic_load { 
    foreach(weights[i]) { 
        weights[i] inside {[-10:10]}; 
    }
}
endclass