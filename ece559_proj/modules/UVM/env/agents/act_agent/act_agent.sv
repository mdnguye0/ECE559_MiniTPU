import uvm_pkg::*; 
`include "uvm_macros.svh" 

class act_agent extends uvm_agent; 
    `uvm_component_utils(act_agent)

    act_sequencer sqr; 
    act_driver drv; 
    act_monitor mon; 

    function new(string name, uvm_component parent); 
        super.new(name, parent); 
    endfunction 

    function void build_phase (uvm_phase phase); 
        super.build_phase(phase); 
        sqr = act_sequencer::type_id::create("sqr", this);
        drv = act_driver::type_id::create("drv", this);
        mon = act_monitor::type_id::create("mon", this); 
    endfunction 

    function void connect_phase(uvm_phase phase); 
        super.connect_phase(phase); 
        drv.seq_item_port.connect(sqr.seq_item_export); 
    endfunction 

endclass 