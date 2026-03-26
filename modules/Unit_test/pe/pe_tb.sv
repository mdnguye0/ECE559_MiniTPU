`timescale 1ns/1ps

`define ACT_WIDTH 16
`define WT_WIDTH 16
`define PSUM_WIDTH 32

module pe_tb;

  reg clk;
  reg rst_n;
  reg en;
  reg load_weight;

  reg signed [`ACT_WIDTH-1:0]  act_in;
  reg signed [`WT_WIDTH-1:0]   weight_in;
  reg signed [`PSUM_WIDTH-1:0] psum_in;

  wire signed [`ACT_WIDTH-1:0]  act_out;
  wire signed [`PSUM_WIDTH-1:0] psum_out;

  // 20 time-unit clock period (same as mac_tb)
  always #10 clk = ~clk;

  pe #(
    .ACT_WIDTH(`ACT_WIDTH),
    .WT_WIDTH(`WT_WIDTH),
    .PSUM_WIDTH(`PSUM_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .load_weight(load_weight),
    .act_in(act_in),
    .weight_in(weight_in),
    .psum_in(psum_in),
    .act_out(act_out),
    .psum_out(psum_out)
  );

  task automatic check(input string name, input integer got, input integer exp);
    begin
      $display("%s = %0d (exp %0d)", name, got, exp);
      if (got !== exp) begin
        $display("FAIL: %s mismatch", name);
        $fatal(1);
      end
    end
  endtask

  initial begin
    // init
    clk         = 0;
    rst_n       = 1;
    en          = 0;
    load_weight = 0;
    act_in      = 0;
    weight_in   = 0;
    psum_in     = 0;

    // reset pulse (active-low)
    #20 rst_n = 0;
    #20 rst_n = 1;

    // Load weight = -5 (only updates weight_reg)
    load_weight = 1;
    weight_in   = -5;
    #20;

    // MAC cycle 1: act=12, psum=-7 => -7 + 12*(-5) = -67
    load_weight = 0;
    en          = 1;
    act_in      = 12;
    psum_in     = -7;
    #20;
    check("act_out",  act_out,  12);
    check("psum_out", psum_out, -67);

    // MAC cycle 2: act=3, psum=16 => 16 + 3*(-5) = 1
    act_in  = 3;
    psum_in = 16;
    #20;
    check("act_out",  act_out,  3);
    check("psum_out", psum_out, 1);

    // Freeze outputs when en=0
    en      = 0;
    act_in  = 9;
    psum_in = 100;
    #20;
    check("act_out (frozen)",  act_out,  3);
    check("psum_out (frozen)", psum_out, 1);

    // load_weight priority over en (act/psum should not update on this cycle)
    en          = 1;
    load_weight = 1;
    weight_in   = 4;
    act_in      = 7;
    psum_in     = 10;
    #20;
    check("act_out (still frozen by load_weight)",  act_out,  3);
    check("psum_out (still frozen by load_weight)", psum_out, 1);

    // Now compute with new weight=4: 10 + 7*4 = 38
    load_weight = 0;
    act_in      = 7;
    psum_in     = 10;
    #20;
    check("act_out",  act_out,  7);
    check("psum_out", psum_out, 38);

    $display("Test finished!");
    $finish;
  end

  // Icarus/GTKWave VCD dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, pe_tb);
  end

endmodule