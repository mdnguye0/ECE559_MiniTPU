interface tpu_if #( 
    parameter int N = 16, 
    parameter int ACT_WIDTH = 16, 
    parameter int WT_WIDTH = 16, 
    parameter int PSUM_WIDTH = 32    
)(input logic clk, input logic rst_n); 
    logic wt_sram_wen; 
    logic [7:0] wt_sram_waddr; 
    logic [WT_WIDTH-1:0] wt_sram_wdata; 
    logic start_weight_load; 
    logic weight_load_done; 

    logic act_sram_wen; 
    logic [9:0] act_sram_waddr; 
    logic [(N*ACT_WIDTH)-1:0] act_sram_wdata; 
    logic start_exec; 

    logic signed [PSUM_WIDTH-1:0] tpu_out [N]; 
    bit uvm_reset_request = 1'b0;
endinterface 