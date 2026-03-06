module weight_load_controller #(
    parameter int N          = 16,
    parameter int WT_WIDTH   = 16,              // weight_width
    parameter int ROW_WIDTH  = N * WT_WIDTH,
    parameter int COUNT_W    = $clog2(N + 1)    // number of bits needed for counters that count up to N
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    // Start loading one N x N weight tile.
    // Assumes the FIFO contains N packed rows in this order: {row 0, row 1, ..., row N-1.}
    input  logic start,

    // FIFO interface
    output logic                 fifo_rd_en,
    input  logic [ROW_WIDTH-1:0] fifo_rd_data,
    input  logic                 fifo_empty,

    // Systolic Array interface
    output logic                       weight_load_en   [N][N],
    output logic signed [WT_WIDTH-1:0] weight_load_data [N][N],

    output logic busy,      // High while the controller is actively loading a tile.
    output logic done       // One-cycle pulse when the tile load finishes.
);

