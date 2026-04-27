import uvm_pkg::*; 
`include "uvm_macros.svh" 

class weight_monitor extends uvm_monitor; 

    `uvm_component_utils(weight_monitor) 

    virtual tpu_if vif; 

    uvm_analysis_port #(weight_item) mon_ap; 
    
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
        weight_item item; 
        bit signed [15:0] captured_weights[256]; 

        forever begin 
            @(posedge vif.clk); 
            
            if (vif.wt_sram_wen == 1'b1) begin 
                captured_weights[vif.wt_sram_waddr] = vif.wt_sram_wdata; 
            end 
            
            if (vif.weight_load_done == 1'b1) begin 
                `uvm_info("WT_MON", "Broadcasting matrix", UVM_LOW) 
                item = weight_item::type_id::create("item");     

                foreach(captured_weights[i]) begin 
                    item.weights[i] = captured_weights[i];
                end 

                mon_ap.write(item); 
            end 
        end 
    endtask 
endclass 