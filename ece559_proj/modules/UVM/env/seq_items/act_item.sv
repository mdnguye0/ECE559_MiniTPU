import uvm_pkg::*;
`include "uvm_macros.svh" 

class act_item extends uvm_sequence_item; 
    rand bit [255:0] act_matrix[16]; 
    `uvm_object_utils_begin(act_item) 
        `uvm_field_sarray_int(act_matrix, UVM_ALL_ON) 
    `uvm_object_utils_end 

    function new (string name = "act_item");
        super.new(name);
    endfunction


endclass 