import uvm_pkg::*; 
`include "uvm_macros.svh" 

class weight_sequencer extends uvm_sequencer #(weight_item); 
    `uvm_component_utils(weight_sequencer) 
    function new(string name, uvm_component parent);
        super.new(name, parent); 
    endfunction 

endclass