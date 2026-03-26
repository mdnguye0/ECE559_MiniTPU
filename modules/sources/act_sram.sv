module act_sram #(
    parameter int WORD_WIDTH = 256,
    parameter int DEPTH = 1024, 
    parameter int ADDR_WIDTH = $clog2(DEPTH)
)
(
    input logic clk, 
    // Use to load image data 
    input logic w_en, 
    input logic signed [ADDR_WIDTH -1:0] waddr, 
    input logic signed [WORD_WIDTH-1:0] wdata, 

    // Use by FIFO to fetch data 
    input logic r_en, 
    input logic signed [ADDR_WIDTH-1:0] raddr, 
    output logic signed[WORD_WIDTH-1:0] rdata
); 

    logic [WORD_WIDTH-1:0] ram[0:DEPTH-1]; 
    always_ff @(posedge clk) begin 
        if (w_en) begin 
            ram[waddr] <= wdata; 
        end 
    end 

    always_ff @(posedge clk) begin 
        if (r_en) begin 
            rdata <= ram[raddr]; 
        end 
    end 
endmodule 