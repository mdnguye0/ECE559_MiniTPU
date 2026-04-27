import uvm_pkg::*;
`include "uvm_macros.svh" 

class act_driver extends uvm_driver #(act_item); 
    
    `uvm_component_utils(act_driver) 

    virtual tpu_if vif; 
    function new (string name, uvm_component parent); 
        super.new(name, parent); 
    endfunction 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        if(!uvm_config_db#(virtual tpu_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Could not find Virtual Interface for weight agent") 
        end
    endfunction 

    task run_phase(uvm_phase phase); 

        forever begin 
            seq_item_port.get_next_item(req); 
            `uvm_info("ACT_DRV", "Starting SRAM writing phase...", UVM_LOW) 
            for (int i = 0; i<16; i++) begin 
                @(posedge vif.clk); 
                vif.act_sram_wen = 1'b1; 
                vif.act_sram_waddr = i; 
                vif.act_sram_wdata = req.act_matrix[i]; 
            end

            @(posedge vif.clk); 
            vif.act_sram_wen = 1'b0; 

            @(posedge vif.clk); 
            vif.start_exec = 1'b1; 
            @(posedge vif.clk); 
            vif.start_exec = 1'b0; 

            `uvm_info("ACT_DRV", "Activations loaded and start_exec pulsed!", UVM_LOW)
            seq_item_port.item_done(); 
        end 
    endtask
endclass 