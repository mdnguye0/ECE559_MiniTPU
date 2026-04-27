import uvm_pkg::*; 
`include "uvm_macros.svh" 

class weight_agent extends uvm_agent; 

    `uvm_component_utils(weight_agent)

    weight_sequencer sqr; 
    weight_driver drv; 
    weight_monitor mon; 

    function new(string name, uvm_component parent); 
        super.new(name, parent); 
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = weight_monitor::type_id::create("monitor", this); 
        sqr = weight_sequencer::type_id::create("sequencer", this); 
        drv = weight_driver::type_id::create("driver", this); 
    endfunction 

    function void connect_phase(uvm_phase phase); 
        super.connect_phase(phase); 
        drv.seq_item_port.connect(sqr.seq_item_export); 
    endfunction 
endclass 

