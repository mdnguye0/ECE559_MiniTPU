import uvm_pkg::*; 
`include "uvm_macros.svh" 

class out_monitor extends uvm_monitor; 
    `uvm_component_utils(out_monitor) 

    virtual tpu_if vif; 
    uvm_analysis_port #(out_item) mon_ap; 

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
        out_item item; 
        int systolic_latency = 21; 

        int raw_capture [16][31];

        forever begin 
            @(posedge vif.clk);
            if (vif.start_exec == 1'b1) begin 
                `uvm_info ("OUT_MON", "Execution started", UVM_LOW) 

                repeat(systolic_latency) @(posedge vif.clk); 
                `uvm_info ("OUT_MON", "Timer finish", UVM_LOW) 

                for (int cycle = 0; cycle < 31; cycle++) begin
                    for (int pin = 0; pin < 16; pin++) begin
                        raw_capture[pin][cycle] = vif.tpu_out[pin];
                    end
                    @(posedge vif.clk);
                end

                // item = out_item::type_id::create("item"); 

                // foreach(item.tpu_results[i]) begin 
                //     item.tpu_results[i] = vif.tpu_out[i]; 
                //     if (i < 15) begin
                //         @(posedge vif.clk); 
                //     end
                // end 

                for (int row = 0; row < 16; row++) begin
                    item = out_item::type_id::create("item");

                    for (int col = 0; col < 16; col++) begin
                        // Row R, Col C dropped at exact cycle (R + C)
                        item.tpu_results[col] = raw_capture[col][row + col];
                    end

                mon_ap.write(item); 
            end 
        end 
        end 
    endtask 
endclass