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
    input  logic load_weight,                       // 1: loads in new weight,  0: latches current weight, compute MAC

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
    logic                       weight_valid;

    logic signed [ACT_WIDTH-1:0]  act_reg;
    logic signed [PSUM_WIDTH-1:0] psum_reg;

    logic signed [WT_WIDTH-1:0]   mac_weight;
    logic signed [ACT_WIDTH+WT_WIDTH-1:0] prod;    
    
    assign act_out = act_reg;
    assign psum_out = psum_reg;

    assign mac_weight = load_weight ? weight_in : weight_reg;
    assign prod       = act_in * mac_weight;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg   <= '0;
            weight_valid <= 1'b0;
            act_reg      <= '0;
            psum_reg     <= '0;
        end else begin
            // This lets the PE preload weights even if en = 0.
            if (load_weight) begin
                weight_reg   <= weight_in;
                weight_valid <= 1'b1;
            end

            // Advance activation / psum only when enabled
            if (en) begin
                act_reg <= act_in;

                // Compute only after this PE has a valid local weight,
                // or on the same cycle a new weight is being loaded.
                if (load_weight || weight_valid) begin
                    psum_reg <= psum_in + $signed(prod);
                end else begin
                    // No weight yet: just pass psum through
                    psum_reg <= psum_in;
                end
            end
        end
    end

endmodule