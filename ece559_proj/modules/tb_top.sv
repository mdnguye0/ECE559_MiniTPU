import uvm_pkg::*; 
`include "uvm_macros.svh" 

module tb_top; 

    logic tb_clk;
    logic tb_rst_n;

    tpu_if intf (
        .clk(tb_clk),
        .rst_n(tb_rst_n)
    );

    tpu_top dut (
        .clk(tb_clk),
        .rst_n(tb_rst_n),

        // Weight Pins connected to Interface
        .wt_sram_wen(intf.wt_sram_wen),
        .wt_sram_waddr(intf.wt_sram_waddr),
        .wt_sram_wdata(intf.wt_sram_wdata),
        .start_weight_load(intf.start_weight_load),
        .weight_load_done(intf.weight_load_done),

        // Activation Pins connected to Interface
        .act_sram_wen(intf.act_sram_wen),
        .act_sram_waddr(intf.act_sram_waddr),
        .act_sram_wdata(intf.act_sram_wdata),
        .start_exec(intf.start_exec),

        // Output Pins connected to Interface
        .tpu_out(intf.tpu_out)
    ); 


    initial begin
        tb_clk = 1'b0;
        forever #10 tb_clk = ~tb_clk; 
    end

    initial begin
        tb_rst_n = 1'b0; // Start in reset
        #25;             // Wait a few nanoseconds
        tb_rst_n = 1'b1; // Release reset and let the chip turn on
    end
    // Testing if reset during execution 
    // always @(posedge intf.uvm_reset_request) begin
    //     tb_rst_n = 1'b0; // Kill the power
    //     #40;          // Wait 2 clock cycles
    //     tb_rst_n = 1'b1; // Restore the power
    //     intf.uvm_reset_request = 1'b0; // Reset the switch
    // end
    initial begin 
        uvm_config_db#(virtual tpu_if)::set(null, "*", "vif", intf); 
        run_test("tpu_test");
    end 
endmodule 