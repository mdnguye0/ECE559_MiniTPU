import uvm_pkg::*; 
`include "uvm_macros.svh" 

class tpu_scoreboard extends uvm_scoreboard; 
    `uvm_component_utils(tpu_scoreboard) 

    uvm_tlm_analysis_fifo #(weight_item) wt_fifo; 
    uvm_tlm_analysis_fifo #(act_item) act_fifo; 
    uvm_tlm_analysis_fifo #(out_item) out_fifo; 

    function new (string name, uvm_component parent); 
        super.new(name, parent); 
    endfunction 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        wt_fifo = new("wt_fifo", this);
        act_fifo = new("act_fifo", this); 
        out_fifo = new("out_fifo", this); 
    endfunction 

    task run_phase(uvm_phase phase); 
        weight_item w_item; 
        act_item a_item; 
        out_item o_item; 

        bit match; 
        int W[16][16];
        int A[16][16];
        int Expected[16][16];
        

        forever begin 
            `uvm_info("SCOREBOARD", "Waiting data from 3 monitors", UVM_LOW) 

            wt_fifo.get(w_item); 
            act_fifo.get(a_item); 
            // out_fifo.get(o_item); 

            `uvm_info("SCOREBOARD", "Data received", UVM_LOW) 
            
            
            match = 1'b1; 

            for (int r = 0; r < 16; r++) begin
                for (int c = 0; c < 16; c++) begin
                    W[r][c] = w_item.weights[r * 16 + c];
                end
            end 

            for (int t = 0; t < 16; t++) begin
                for (int y = 0; y < 16; y++) begin
                    // Extract a 16-bit slice and explicitly cast it to a signed integer!
                    A[t][y] = $signed(a_item.act_matrix[t][y*16 +: 16]);
                end
            end 

            for (int t = 0; t < 16; t++) begin
                for (int x = 0; x < 16; x++) begin
                    Expected[t][x] = 0; // Initialize sum
                    for (int y = 0; y < 16; y++) begin
                        Expected[t][x] += A[t][y] * W[y][x];
                    end
                end
            end

            // `uvm_info("SCOREBOARD", "--- Comparing Row 0 ---", UVM_NONE)
            
            // for (int x = 0; x < 16; x++) begin
            //     `uvm_info("SCOREBOARD", $sformatf("Col %0d | HW: %0d | Golden: %0d", x, o_item.tpu_results[x], Expected[0][x]), UVM_NONE)
                
            //     if (o_item.tpu_results[x] !== Expected[0][x]) begin
            //         match = 1'b0; // We found a bug!
            //     end
            // end

            // if (match) begin
            //     `uvm_info("SCOREBOARD", "========================================", UVM_NONE)
            //     `uvm_info("SCOREBOARD", " [PASS] HW MATCHES GOLDEN MODEL! ", UVM_NONE)
            //     `uvm_info("SCOREBOARD", "========================================", UVM_NONE)
            // end else begin
            //     `uvm_error("SCOREBOARD", "========================================")
            //     `uvm_error("SCOREBOARD", " [FAIL] HW MISMATCH DETECTED! ")
            //     `uvm_error("SCOREBOARD", "========================================")
            // end
            for (int r = 0; r < 16; r++) begin
                // Grab the next row out of the 16 that the monitor just sent!
                out_fifo.get(o_item);
                
                `uvm_info("SCOREBOARD", $sformatf("--- Comparing Row %0d ---", r), UVM_NONE)
                
                for (int c = 0; c < 16; c++) begin
                    // Print only if it fails to keep the terminal clean, or print all if you want!
                    if (o_item.tpu_results[c] !== Expected[r][c]) begin
                        `uvm_error("SCOREBOARD", $sformatf("MISMATCH! Row %0d, Col %0d | HW: %0d | Golden: %0d", r, c, o_item.tpu_results[c], Expected[r][c]))
                        match = 1'b0; 
                    end
                end
            end

            if (match) begin
                `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
                `uvm_info("SCOREBOARD", " [PASS] ALL 256 OUTPUTS MATCH THE GOLDEN MODEL! ", UVM_NONE)
                `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
            end else begin
                `uvm_error("SCOREBOARD", "==================================================")
                `uvm_error("SCOREBOARD", " [FAIL] HARDWARE MISMATCH DETECTED IN MATRIX! ")
                `uvm_error("SCOREBOARD", "==================================================")
            end
        end
    endtask

endclass 