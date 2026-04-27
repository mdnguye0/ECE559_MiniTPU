module systolic_array #(
    parameter int N          = 16,
    parameter int ACT_WIDTH  = 16,
    parameter int WT_WIDTH   = 16,
    parameter int PSUM_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic en,
    
    // --------------------- ACTIVATIONs / PSUMs  -------------------------------------
    // One activation per row enters from the left edge
    input  logic signed [ACT_WIDTH-1:0]  act_in   [N],
    input  logic signed [PSUM_WIDTH-1:0] psum_in  [N],
    output logic signed [PSUM_WIDTH-1:0] psum_out [N],

    // --------------------- WEIGHT LOAD INTERFACE -------------------------------------
    // External logic decides which PE gets loaded each cycle.
    // weight_load_en[row][col] = 1 means PE[row][col] latches weight_load_data[row][col]
    input  logic                          weight_load_en   [N][N],
    input  logic signed [WT_WIDTH-1:0]    weight_load_data [N][N]
);

    // --------------------- INTERCONNECTS -------------------------------------------
    // Internal interconnect:
    // act_pipe[x][y]  : activation entering column x, row y
    // psum_pipe[x][y] : psum entering column x, row y
    logic signed [ACT_WIDTH-1:0]  act_pipe  [0:N][0:N-1];
    logic signed [PSUM_WIDTH-1:0] psum_pipe [0:N-1][0:N];

    // Boundary connections
    genvar y, x;

    // Left boundary (x=0): feed in activations per row
    generate
        for (y = 0; y < N; y++) begin : LEFT_EDGE
            assign act_pipe[0][y] = act_in[y];
        end
    endgenerate

    // Top boundary (y=0): feed in psums per column
    generate
        for (x = 0; x < N; x++) begin : TOP_EDGE
            assign psum_pipe[x][0] = psum_in[x];
        end
    endgenerate
    
    // --------------------- SYSTOLIC ----------------------------------------
    generate
        for (x = 0; x < N; x++) begin : COLS
            for (y = 0; y < N; y++) begin : ROWS
                pe #(
                    .ACT_WIDTH (ACT_WIDTH),
                    .WT_WIDTH  (WT_WIDTH),
                    .PSUM_WIDTH(PSUM_WIDTH)
                ) pe_inst (
                    .clk        (clk),
                    .rst_n      (rst_n),
                    .en         (en),
                    .load_weight(weight_load_en[y][x]),

                    .act_in     (act_pipe[x][y]),
                    .weight_in  (weight_load_data[y][x]),
                    .psum_in    (psum_pipe[x][y]),

                    .act_out    (act_pipe[x+1][y]),   // move right
                    .psum_out   (psum_pipe[x][y+1])   // move down
                );
            end
        end
    endgenerate

    // --------------------- BOTTOM EDGE -------------------------------------
    generate
        for (x = 0; x < N; x++) begin : BOTTOM_EDGE
            assign psum_out[x] = psum_pipe[x][N];
        end
    endgenerate

endmodule