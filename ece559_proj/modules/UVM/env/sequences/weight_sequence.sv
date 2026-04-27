import uvm_pkg::*; 
`include "uvm_macros.svh" 

class weight_basic_seq extends uvm_sequence #(weight_item); 
    `uvm_object_utils(weight_basic_seq) 

    function new (string name = "weight_basic_seq"); 
        super.new(name); 
    endfunction 

    virtual task body(); 
        `uvm_info("WT_SEQ", "Preparing to send matrices",UVM_LOW) 
        repeat(1) begin 
            req = weight_item::type_id::create("req"); 
            start_item(req); 
            assert(req.randomize()); 
            finish_item(req); 
        end 
        `uvm_info("WT_SEQ", "All 3 matrices sent.", UVM_LOW) 
    endtask 
endclass  

