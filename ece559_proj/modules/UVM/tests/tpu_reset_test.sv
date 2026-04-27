import uvm_pkg::*; 
`include "uvm_macros.svh"

class tpu_reset_test extends uvm_test; 
    `uvm_component_utils(tpu_reset_test) 

    tpu_env env; 
    weight_basic_seq w_seq; 
    act_basic_seq a_seq; 

    function new(string name = "tpu_reset_test", uvm_component parent = null); 
        super.new(name, parent); 
    endfunction 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        env = tpu_env::type_id::create("env", this); 
    endfunction 

    task run_phase(uvm_phase phase); 
        virtual tpu_if vif; 
        if (!uvm_config_db#(virtual tpu_if)::get(this, "", "vif", vif))
            `uvm_fatal("TEST", "Could not find virtual interface!")

        w_seq = weight_basic_seq::type_id::create("w_seq"); 
        a_seq = act_basic_seq::type_id::create("a_seq");

        phase.raise_objection(this); 
        `uvm_info("TEST", "Reset Test started! Objection raised.", UVM_LOW) 
        #50;

        fork
            begin : normal_execution_thread
                `uvm_info("TEST", "Starting Victim Matrix...", UVM_LOW) 
                w_seq.start(env.w_agent.sqr); 
                #100;
                a_seq.start(env.a_agent.sqr); 
                #2000; 
            end

            begin : hitman_thread 
            #16500; 
            `uvm_info("TEST", "!!! PULLING THE PLUG (MID-FLIGHT RESET) !!!", UVM_NONE) 
            vif.uvm_reset_request = 1'b1;            
            #50;
            
            `uvm_info("TEST", "!!! POWER RESTORED !!!", UVM_NONE)
            end
        join_any 
        #500;

        env.w_agent.sqr.stop_sequences();
        env.a_agent.sqr.stop_sequences();
        #500;
        `uvm_info("TEST", "Attempting to run a new matrix on recovered hardware...", UVM_NONE)

        w_seq.start(env.w_agent.sqr); 
        #100;
        a_seq.start(env.a_agent.sqr); 
        #2500; 
        `uvm_info("TEST", "Sequence finished! Dropping objection.", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass