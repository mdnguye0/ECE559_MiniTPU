import uvm_pkg::*; 
`include "uvm_macros.svh" 

class out_item extends uvm_sequence_item; 
    bit signed [31:0] tpu_results [16]; 
    `uvm_object_utils_begin(out_item) 
        `uvm_field_sarray_int(tpu_results, UVM_ALL_ON) 
    `uvm_object_utils_end 

    function new(string name = "out_item"); 
        super.new(name); 
    endfunction 
endclass 

