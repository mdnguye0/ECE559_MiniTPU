`timescale 1ns/1ps

module tb_weight_path(); 
    parameter int N = 16; 
    parameter int WT_WIDTH = 16; 
    parameter int FIFO_DEPTH = 256; 

    logic clk; 
    logic rst_n; 

    logic wr_en; 
    logic [WT_WIDTH-1:0] wr_data; 
    logic fifo_full; 

    logic start_load; 
    logic load_done; 

    logic weight_load; 
    logic [$clog2(N)-1:0] weight_row;
    logic [$clog2(N)-1:0] weight_col;
    logic [WT_WIDTH-1:0] weight_out; 

    logic fifo_empty;
    logic fifo_rd_en;
    logic [WT_WIDTH-1:0] fifo_data; 

    weight_fifo #(
        .DATA_WIDTH(WT_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(fifo_full),
        .rd_en(fifo_rd_en),
        .rd_data(fifo_data),
        .empty(fifo_empty)
    ); 

    weight_controller #(
        .N(N),
        .WT_WIDTH(WT_WIDTH)
    ) ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_load(start_load),
        .load_done(load_done),
        .fifo_empty(fifo_empty),
        .fifo_data(fifo_data),
        .fifo_rd_en(fifo_rd_en),
        .weight_load(weight_load),
        .weight_row(weight_row),
        .weight_col(weight_col),
        .weight_out(weight_out)
    );

    always #5 clk = ~clk; 

    initial begin 
        clk = 0; 
        rst_n = 0; 
        wr_en = 0; 
        wr_data = 0; 
        start_load = 0; 

        #20; 
        rst_n = 1; 
        @(negedge clk); 
        for (int i = 0; i <256; i++) begin 
            wr_en = 1; 
            wr_data = i+1; 
            @(negedge clk); 
        end 
        wr_en = 0; 

        #30; 

        @(negedge clk); 
        start_load = 1; 

        @(negedge clk); 
        start_load = 0; 
        
        wait(load_done == 1'b1);
        #50;
        $display("Weight Loading Complete!");
        $finish;
    end
endmodule 
