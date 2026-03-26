`timescale 1ns/1ps

module tb_tpu_top();

    parameter int N = 16;
    parameter int ACT_WIDTH = 16;
    parameter int WT_WIDTH = 16;
    parameter int PSUM_WIDTH = 32;

    logic clk;
    logic rst_n;

    // --- System Interface: Weights ---
    logic wt_sram_wen;
    logic [7:0] wt_sram_waddr;
    logic [WT_WIDTH-1:0] wt_sram_wdata;
    logic start_weight_load;
    logic weight_load_done;

    // --- System Interface: Activations ---
    logic act_sram_wen;
    logic [9:0] act_sram_waddr;
    logic [(N*ACT_WIDTH)-1:0] act_sram_wdata;
    logic start_exec;

    // --- TPU Output ---
    logic signed [PSUM_WIDTH-1:0] tpu_out [N];

    // Instantiate the Top-Level TPU
    tpu_top #(
        .N(N),
        .ACT_WIDTH(ACT_WIDTH),
        .WT_WIDTH(WT_WIDTH),
        .PSUM_WIDTH(PSUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wt_sram_wen(wt_sram_wen),
        .wt_sram_waddr(wt_sram_waddr),
        .wt_sram_wdata(wt_sram_wdata),
        .start_weight_load(start_weight_load),
        .weight_load_done(weight_load_done),
        .act_sram_wen(act_sram_wen),
        .act_sram_waddr(act_sram_waddr),
        .act_sram_wdata(act_sram_wdata),
        .start_exec(start_exec),
        .tpu_out(tpu_out)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Variables for loops
    integer i, r, c;

    initial begin
        // 1. System Reset
        clk = 0;
        rst_n = 0;
        wt_sram_wen = 0;
        wt_sram_waddr = 0;
        wt_sram_wdata = 0;
        start_weight_load = 0;
        
        act_sram_wen = 0;
        act_sram_waddr = 0;
        act_sram_wdata = 0;
        start_exec = 0;

        #20;
        rst_n = 1;
        #10;

        // -----------------------------------------------------------
        // PHASE 1: LOAD WEIGHTS (The Identity Matrix)
        // -----------------------------------------------------------
        $display("[%0t] Starting Weight SRAM Write...", $time);
        for (i = 0; i < 256; i++) begin
            @(negedge clk);
            wt_sram_wen = 1;
            wt_sram_waddr = i;
            
            // Calculate row and col to create the diagonal 1s
            r = i / 16;
            c = i % 16;
            if (r == c) wt_sram_wdata = 16'h0001; // Diagonal gets 1
            else        wt_sram_wdata = 16'h0000; // Everything else gets 0
        end
        @(negedge clk);
        wt_sram_wen = 0;

        // Turn on the "Dealer"
        $display("[%0t] Triggering Weight Controller...", $time);
        @(negedge clk);
        start_weight_load = 1;
        @(negedge clk);
        start_weight_load = 0;

        // Pause the testbench and wait for the hardware to finish dealing
        wait(weight_load_done == 1'b1);
        $display("[%0t] Weight Loading Complete!", $time);
        #50;

     // -----------------------------------------------------------
        // PHASE 2: LOAD ACTIVATIONS 
        // -----------------------------------------------------------
        $display("[%0t] Initializing Activation SRAM to 0...", $time);
        
        // FIX: Scrub the entire 1,024-depth memory to prevent 'X' propagation!
        for (i = 0; i < 1024; i++) begin
            @(negedge clk);
            act_sram_wen = 1;
            act_sram_waddr = i;
            act_sram_wdata = '0;
        end

        $display("[%0t] Writing Image Data...", $time);
        
        // Now push the 3 lines of actual image data into the SRAM
        for (i = 0; i < 3; i++) begin
            @(negedge clk);
            act_sram_wen = 1;
            act_sram_waddr = i;
            act_sram_wdata = '0;
            
            for (int col = 0; col < N; col++) begin
                act_sram_wdata[(col*16) +: 16] = (i * 100) + col + 1; 
            end
        end
        @(negedge clk);
        act_sram_wen = 0;
        // -----------------------------------------------------------
        // PHASE 3: EXECUTE MATRIX MATH
        // -----------------------------------------------------------
        $display("[%0t] Triggering TPU Execution...", $time);
        @(negedge clk);
        start_exec = 1;
        @(negedge clk);
        start_exec = 0; // Turn off the start signal, the pump takes over

        // Let the simulation run long enough for data to skew, travel down 
        // 16 rows of PEs, and drop out the bottom.
        #2500;
        
        $display("[%0t] Simulation Finished. Check Waveforms!", $time);
        $finish;
    end

endmodule