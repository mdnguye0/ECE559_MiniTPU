import uvm_pkg::*; 
`include "uvm_macros.svh" 

class act_basic_seq extends uvm_sequence #(act_item); 
    `uvm_object_utils (act_basic_seq) 

    function new(string name = "act_basic_seq"); 
        super.new(name); 
    endfunction 

    virtual task body(); 
        `uvm_info("ACT_SEQ", "Starting", UVM_LOW) 
        repeat(1) begin 
            req = act_item::type_id::create("req"); 
            start_item(req); 
            assert(req.randomize()); 
            finish_item(req); 
        end 
            `uvm_info("ACT_SEQ", "All done", UVM_LOW) 
    endtask
endclass