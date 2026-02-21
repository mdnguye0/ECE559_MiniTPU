// Final goal is to make a weight-stationary systolic array

module pe #(
// Subject to change
    parameter ACT_WIDTH = 16,
    parameter WT_WIDTH = 16,
    parameter PSUM_WIDTH = 32                       // to prevent overflow.
)(
    input  logic clk,
    input  logic rst_n,
    input  logic en,                                // 1: activates the PE,     0: freezes it
    input  logic load_weight,                       // 1: loads in new weight,  0: latches current weight, compute MAC. 

    // Data Inputs
    input  logic signed [ACT_WIDTH-1:0]  act_in,    // From left PE (or Skew FIFO)
    input  logic signed [WT_WIDTH-1:0]   weight_in, // From top PE (or Weight FIFO)
    input  logic signed [PSUM_WIDTH-1:0] psum_in,   // From top PE (or set to 0 at top row)

    // Data Outputs
    output logic signed [ACT_WIDTH-1:0]  act_out,   // To right PE
    output logic signed [PSUM_WIDTH-1:0] psum_out   // To bottom PE (or ReLU block)
);

    // Internal registers
    logic signed [WT_WIDTH-1:0] weight_reg;
    logic signed [ACT_WIDTH-1:0]  act_reg;
    logic signed [PSUM_WIDTH-1:0] psum_reg;

    assign act_out = act_reg;
    assign psum_out = psum_reg;

    logic signed [ACT_WIDTH+WT_WIDTH-1:0] prod;
    assign prod = act_in * weight_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= '0;
            act_reg    <= '0;
            psum_reg   <= '0;
        end else begin
            if (load_weight) begin
                weight_reg <= weight_in;
            end
            else if (en) begin
                act_reg  <= act_in;
                psum_reg <= psum_in + $signed(prod);
            end
        end
    end
endmodule