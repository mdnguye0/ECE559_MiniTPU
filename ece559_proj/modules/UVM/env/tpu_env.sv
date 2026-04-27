import uvm_pkg::*; 
`include"uvm_macros.svh" 

class tpu_env extends uvm_env; 
    `uvm_component_utils(tpu_env) 

    weight_agent w_agent;
    act_agent a_agent; 
    out_agent  o_agent;
    tpu_scoreboard sb;

    function new(string name, uvm_component parent);
        super.new(name, parent); 
    endfunction

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        `uvm_info("TPU_ENV", "Build agents", UVM_LOW) 
        w_agent = weight_agent::type_id::create("w_agent", this); 
        a_agent = act_agent::type_id::create("a_agent", this); 
        o_agent = out_agent::type_id::create("o_agent", this);
        sb = tpu_scoreboard::type_id::create("sb", this);
    endfunction 

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        w_agent.mon.mon_ap.connect(sb.wt_fifo.analysis_export);
        a_agent.mon.mon_ap.connect(sb.act_fifo.analysis_export);
        o_agent.mon.mon_ap.connect(sb.out_fifo.analysis_export);
    endfunction

endclass 


