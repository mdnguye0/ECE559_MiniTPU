module act_skew_buffer #(
    parameter int N = 16, 
    parameter int ACT_WIDTH = 16
)(
    input logic clk, 
    input logic rst_n, 
    input logic en, 

    input logic signed [ACT_WIDTH-1:0] act_in [N], 
    output logic signed [ACT_WIDTH-1:0] act_out [N] 
); 

    logic signed [ACT_WIDTH-1:0] shift_reg[N][N]; 
    assign act_out[0] = act_in[0]; 

    genvar row; 
    generate 
        for (row = 1; row <N; row ++) begin: SKEW_ROWS 
            always_ff(@posedge clk or negedge rst_n) begin 
                if (!rst_n) begin 
                    for (int i =0; i<row; i++) begin 
                        shift_reg[row][i] <= '0'; 
                    end 

                    for (int i = 1; i<row; i++) begin 
                        shift_reg[row][i] <= shift_reg[row][i-1]; 
                    end 
                end 
            end 
            assign act_out [row] = shift_reg[row][row-1]; 
        end 
    endgenerate 
endmodule 