`timescale 1ns/1ps 

module tb_act_skew_buffer(); 

    parameter int N = 16; 
    parameter int ACT_WIDTH = 16; 

    logic clk; 
    logic rst_n; 
    logic en; 
    logic signed [ACT_WIDTH-1:0] act_in [N]; 
    logic signed [ACT_WIDTH-1:0] act_out [N]; 

    act_skew_buffer #(.N(N), 
        .ACT_WIDTH(ACT_WIDTH)) dut (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en), 
        .act_in(act_in), 
        .act_out(act_out)
        ); 
    
    always #5 clk = ~clk; 
    integer i; 
    initial begin 
        clk = 0; 
        rst_n = 0; 
        en = 0; 
        for (i =0; i<N;i++) begin 
            act_in[i] = 0; 
        end 

        #20 
        rst_n = 1; 
        en = 1; 

        @(negedge clk); 

        for (i = 0; i<N; i++) begin 
            act_in[i] = 16'h0100 + i; 
        end 

        @(negedge clk); 
        for (int i = 0; i < N; i++) begin
            act_in[i] = 0; 
        end 

        #200; 
        $display("Simulation Complete.");
        $finish;
    end

endmodule
