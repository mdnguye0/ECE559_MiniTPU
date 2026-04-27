import uvm_pkg::*; 
`include "uvm_macros.svh" 

class act_monitor extends uvm_monitor; 
    `uvm_component_utils(act_monitor) 

    virtual tpu_if vif; 
    uvm_analysis_port #(act_item) mon_ap;

    function new(string name, uvm_component parent); 
        super.new(name, parent); 
        mon_ap = new("mon_ap", this); 
    endfunction 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        if (!uvm_config_db#(virtual tpu_if)::get(this, "", "vif", vif)) begin 
            `uvm_fatal("NO_VIF", "Couldn't find the virtual interface")
        end 
    endfunction  

    task run_phase(uvm_phase phase);
        act_item item;
        bit [255:0] captured_acts [16]; 

        forever begin
            @(posedge vif.clk); 
            if (vif.act_sram_wen == 1'b1) begin
                captured_acts[vif.act_sram_waddr] = vif.act_sram_wdata;
            end 

            if (vif.start_exec == 1'b1) begin
                `uvm_info("ACT_MON", "Broadcasting activation matrix to Scoreboard", UVM_LOW)
                item = act_item::type_id::create("item"); 

                foreach(captured_acts[i]) begin
                        item.act_matrix[i] = captured_acts[i];
                end

                mon_ap.write(item); 
            end 
        end 
    endtask 

endclass 