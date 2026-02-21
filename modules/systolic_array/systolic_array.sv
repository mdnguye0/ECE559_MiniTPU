// systolic_array_16x16.sv
module systolic_array #(
    parameter int N          = 16,
    parameter int ACT_WIDTH  = 16,
    parameter int WT_WIDTH   = 16,
    parameter int PSUM_WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic en,
    
    // --------------------- INPUTS -------------------------------------------------
    // Left-edge activations: one per row
    input  logic signed [ACT_WIDTH-1:0]  act_in   [N],

    // Top-edge partial sums: one per column (often all zeros)
    input  logic signed [PSUM_WIDTH-1:0] psum_in  [N],

    // Bottom-edge outputs: one per column
    output logic signed [PSUM_WIDTH-1:0] psum_out [N],
    // ------------------------------------------------------------------------------
    
    // -------------------- WEIGHT CONTROL INTERFACE --------------------------------
    input  logic                          weight_load,  // 1: to start weight loading
    
    // used to indicate which row/col is now being loaded (controlled externally)
    input  logic [$clog2(N)-1:0]          weight_row,    
    input  logic [$clog2(N)-1:0]          weight_col,   
    
    input  logic signed [WT_WIDTH-1:0]    weight_data
    // -------------------------------------------------------------------------------
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
    // -------------------------------------------------------------------------------
    
    // -------------------- SYSTOLIC ARRAY -------------------------------------------
    generate
        for (x = 0; x < N; x++) begin : COLS
            for (y = 0; y < N; y++) begin : ROWS
                logic this_load;

                // Logic for determining which weight is now being loaded.
                assign this_load = weight_load
                                && (weight_row == y[$clog2(N)-1:0]) 
                                && (weight_col == x[$clog2(N)-1:0]);

                pe #(
                    .ACT_WIDTH(ACT_WIDTH),
                    .WT_WIDTH(WT_WIDTH),
                    .PSUM_WIDTH(PSUM_WIDTH)
                ) pe_inst (
                    .clk        (clk),
                    .rst_n      (rst_n),
                    .en         (en),
                    .load_weight(this_load),

                    .act_in     (act_pipe[x][y]),
                    .weight_in  (weight_data),          // broadcast, only selected PE latches
                    .psum_in    (psum_pipe[x][y]),

                    .act_out    (act_pipe[x+1][y]),     // to the right
                    .psum_out   (psum_pipe[x][y+1])     // downward
                );
            end
        end
    endgenerate

    // Bottom boundary (y=N): collect outputs per column
    generate
        for (x = 0; x < N; x++) begin : BOTTOM_EDGE
            assign psum_out[x] = psum_pipe[x][N];
        end
    endgenerate
endmodule