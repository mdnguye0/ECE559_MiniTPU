module weight_fifo #(
    parameter int DATA_WIDTH = 256;
    parameter int DEPTH = 16;
    parameter int ADDR_WIDTH = $clog2(DEPTH);
)(
    input logic clk, 
    input logic rst_n, 

// write
    input logic wr_en, 
    input logic [DATA_WIDTH-1:0] wr_data, 
    output logic full, 

// read
    input logic rd_en, 
    output logic [DATA_WIDTH-1:0] rd_data, 
    output logic empty
); 
    logic [DATA_WIDTH-1:0] mem[0:DEPTH-1]; 
    logic [ADDR_WIDTH -1:0] wr_ptr;         //write pointer
    logic [ADDR_WIDTH-1:0] rd_ptr;          //read pointer
    logic [ADDR_WIDTH:0] count;             //count of elements in FIFO

// flags
    assign full = (count == DEPTH); 
    assign empty = (count == 0); 

// write logic
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            wr_ptr <= 0; 
        end else if (wr_en && !full) begin      // if write enable && not full
            mem [wr_ptr] <= wr_data;            // put write data at write pointer
            wr_ptr <= wr_ptr + 1;               // increment
        end 
    end 

    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            rd_ptr <= 0; 
            rd_data <= 0; 
        end else if (rd_en && !empty) begin     // if read enable && not empty
            rd_data <= mem[rd_ptr];             // put read data at read pointer
            rd_ptr <= rd_ptr + 1;               // increment
        end
    end  

    always_ff @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        count <= 0; 
    end else begin 
        case ({wr_en && !full, rd_en && !empty})
            2'b10: count <= count + 1; 
            2'b01: count <= count -1; 
            default: count <= count; 
        endcase 
        end
    end
endmodule