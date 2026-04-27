import uvm_pkg::*;
`include "uvm_macros.svh" 

class weight_driver extends uvm_driver #(weight_item); 
    
    `uvm_component_utils(weight_driver) 

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
        vif.wt_sram_wen = 1'b0; 
        vif.start_weight_load = 1'b0; 

        forever begin 
            seq_item_port.get_next_item(req); 
            `uvm_info("WT_DRV", "Starting SRAM writing phase...", UVM_LOW) 
            for (int i = 0; i<256; i++) begin 
                @(posedge vif.clk); 
                vif.wt_sram_wen = 1'b1; 
                vif.wt_sram_waddr = i; 
                vif.wt_sram_wdata = req.weights[i]; 
            end

            @(posedge vif.clk); 
            vif.wt_sram_wen = 1'b0; 

            @(posedge vif.clk); 
            vif.start_weight_load = 1'b0; 
            @(posedge vif.clk); 
            vif.start_weight_load = 1'b1; 
            @(posedge vif.clk); 
            vif.start_weight_load = 1'b0;
            `uvm_info("WT_DRV", "Waiting for controller to finish ...", UVM_LOW)
            wait(vif.weight_load_done == 1'b1); 
            // begin
            //     int wait_cycles = 0;
            //     // Wait for the done signal, but give up after 2000 clock cycles
            //     while(vif.weight_load_done == 1'b0 && wait_cycles < 2000) begin
            //         @(posedge vif.clk);
            //         wait_cycles++;
            //     end
                
            //     if (wait_cycles >= 2000) begin
            //         `uvm_fatal("WT_DRV", "TIMEOUT: Hardware never asserted weight_load_done! Check SRAM-to-FIFO logic.")
            //     end
            // end

            `uvm_info("WT_DRV", "Matrix successfully loaded into PEs!", UVM_LOW) 
            seq_item_port.item_done(); 
        end 
    endtask
endclass 