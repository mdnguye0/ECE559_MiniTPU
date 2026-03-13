module weight_sram #(parameter int WORD_WIDTH = 16, 
                    parameter int DEPTH = 256, 
                    parameter int ADDR_WIDTH = $clog2(DEPTH) 
)(
    input logic clk, 
    
    input logic wen, 
    input logic [ADDR_WIDTH -1:0] waddr, 
    input logic [WORD_WIDTH-1:0] wdata, 

    input logic ren, 
    input logic [ADDR_WIDTH-1:0] raddr, 
    output logic [WORD_WIDTH-1:0] rdata 
); 
    logic [WORD_WIDTH-1:0] ram[0:DEPTH-1]; 

    always_ff @(posedge clk) begin 
        if(wen) begin 
            ram[waddr] <= wdata; 
        end 
    end 
    
    always_ff @(posedge clk) begin 
        if (ren) begin 
            rdata <= ram[raddr]; 
        end 
    end     
endmodule