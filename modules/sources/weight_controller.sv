module weight_controller #(parameter int N = 16, 
                           parameter int WT_WIDTH = 16)
(
    input logic clk,
    input logic rst_n, 

    input logic start_load, 
    output logic load_done, 

    input logic fifo_empty, 
    input logic [WT_WIDTH-1:0] fifo_data, 
    output logic fifo_rd_en, 

    output logic weight_load, 
    output logic [$clog2(N)-1:0] weight_row, 
    output logic [$clog2(N)-1:0] weight_col, 
    output logic [WT_WIDTH-1:0] weight_out
); 

    typedef enum logic [1:0] {
        IDLE = 2'b00, 
        LOADING = 2'b01, 
        DONE = 2'b10
    } state_t; 

    state_t current, next; 

    logic [7:0] count; 
    logic increment_count; 

    logic data_pending; 
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            current <= IDLE; 
        end else begin 
            current <= next; 
        end 
    end 

    always_comb begin 
        next = current; 
        fifo_rd_en = 1'b0; 

        case (current)
            IDLE: begin 
                if(start_load) next = LOADING; 
            end 

            LOADING: begin 
                if(!fifo_empty) begin 
                    fifo_rd_en = 1'b1; 
                end 

                if (count == 8'd255 && data_pending) begin 
                    next = DONE;  
                end 
            end 

            DONE: begin 
                if (!start_load) next = IDLE; 
            end 

            default: next = IDLE; 
        endcase 
    end 

    always_ff @(posedge clk or negedge rst_n) begin 
        if(!rst_n) begin 
            data_pending <= 1'b0; 
            count <= 8'd0; 
        end else begin 
            data_pending <= fifo_rd_en; 
            if (data_pending) begin 
                count <= count + 1'b1; 
            end 

            if(current == IDLE) begin 
                count <= 8'd0; 
            end 
        end 
    end 

    assign weight_load = data_pending; 
    assign weight_out = fifo_data; 

    assign weight_row = count[7:4]; 
    assign weight_col = count[3:0]; 

    assign load_done = (current == DONE); 

endmodule