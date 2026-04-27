import uvm_pkg::*; 
`include "uvm_macros.svh"

class tpu_test extends uvm_test; 
    `uvm_component_utils(tpu_test) 
    tpu_env env; 
    weight_basic_seq w_seq; 
    act_basic_seq a_seq; 

    function new(string name, uvm_component parent); 
        super.new(name, parent); 
    endfunction     

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        env = tpu_env::type_id::create("env", this); 
    endfunction 

    task run_phase(uvm_phase phase); 
        w_seq = weight_basic_seq::type_id::create("w_seq"); 
        a_seq = act_basic_seq :: type_id::create("a_seq"); 

        phase.raise_objection(this); 
        `uvm_info("TEST", "Test started! Objection raised.", UVM_LOW) 
        #50;
        repeat(100) begin 
        w_seq.start(env.w_agent.sqr); 
      #100; 

        a_seq.start(env.a_agent.sqr); 
        #2500;
        end
        `uvm_info("TEST", "Sequence finished! Dropping objection.", UVM_LOW)
        phase.drop_objection(this); 

    endtask 
endclass   