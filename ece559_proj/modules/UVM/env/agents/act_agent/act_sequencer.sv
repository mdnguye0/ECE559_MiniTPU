import uvm_pkg::*; 
`include "uvm_macros.svh" 

class act_sequencer extends uvm_sequencer #(act_item); 
    `uvm_component_utils(act_sequencer) 
    function new(string name, uvm_component parent);
        super.new(name, parent); 
    endfunction 
endclass