module tpu_top #( 
    parameter int N = 16, 
    parameter int ACT_WIDTH = 16, 
    parameter int WT_WIDTH = 16, 
    parameter int PSUM_WIDTH = 32
) (
    input logic clk, 
    input logic rst_n, 

    input logic wt_sram_wen, 
    input logic [7:0] wt_sram_waddr, 
    input logic [WT_WIDTH-1:0] wt_sram_wdata, 
    input logic start_weight_load, 
    output logic weight_load_done, 

    input logic act_sram_wen, 
    input logic [9:0] act_sram_waddr, 
    input logic [(N*ACT_WIDTH)-1: 0] act_sram_wdata, 
    input logic start_exec, 

    output logic signed [PSUM_WIDTH-1:0] tpu_out [N]
); 

    logic [7:0] wt_sram_raddr;
    logic wt_sram_ren;
    logic [WT_WIDTH-1:0] wt_sram_rdata;

    logic wt_fifo_wr_en;
    logic wt_fifo_full;
    logic wt_fifo_empty;
    logic wt_fifo_rd_en;
    logic [WT_WIDTH-1:0] wt_fifo_rdata;

    logic wt_pump_active; 

    logic weight_load_pulse;
    logic [3:0] weight_row; // $clog2(16)-1 = 3
    logic [3:0] weight_col;
    logic [WT_WIDTH-1:0] weight_out_1d; 

    weight_sram #(
        .WORD_WIDTH(WT_WIDTH), 
        .DEPTH(256)
    ) w_sram_inst (
        .clk(clk),
        .wen(wt_sram_wen),
        .waddr(wt_sram_waddr),
        .wdata(wt_sram_wdata),
        .ren(wt_sram_ren),
        .raddr(wt_sram_raddr),
        .rdata(wt_sram_rdata)
    ); 

    weight_fifo #(
        .DATA_WIDTH(WT_WIDTH),
        .DEPTH(16)
    ) w_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wt_fifo_wr_en),
        .wr_data(wt_sram_rdata),
        .full(wt_fifo_full),
        .rd_en(wt_fifo_rd_en),
        .rd_data(wt_fifo_rdata),
        .empty(wt_fifo_empty)
    ); 

    weight_controller #(
        .N(N),
        .WT_WIDTH(WT_WIDTH)
    ) w_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_load(start_weight_load),
        .load_done(weight_load_done),
        .fifo_empty(wt_fifo_empty),
        .fifo_data(wt_fifo_rdata),
        .fifo_rd_en(wt_fifo_rd_en),
        .weight_load(weight_load_pulse),
        .weight_row(weight_row),
        .weight_col(weight_col),
        .weight_out(weight_out_1d)
    ); 

    always_ff @(posedge clk or negedge rst_n) begin 
        if(!rst_n) begin 
            wt_sram_raddr <= '0; 
            wt_sram_ren <= 1'b0; 
            wt_fifo_wr_en <= 1'b0; 
            wt_pump_active <= 1'b0; 
        end else begin 
            if (start_weight_load) wt_pump_active <=1'b1; 
            if (wt_sram_raddr == 8'd255 && wt_sram_ren) wt_pump_active <= 1'b0; 
            if (wt_pump_active && !wt_fifo_full && !wt_sram_ren) begin 
                wt_sram_ren <=1'b1; 
            end else begin 
                wt_sram_ren <= 1'b0; 
            end 
            if (wt_sram_ren) wt_sram_raddr <= wt_sram_raddr + 1'b1; 
            wt_fifo_wr_en <= wt_sram_ren; 
        end 
    end  

    logic [9:0] act_sram_raddr;
    logic act_sram_ren;
    logic [(N*ACT_WIDTH)-1:0] act_sram_rdata;

    logic act_fifo_wr_en;
    logic act_fifo_full;
    logic act_fifo_empty;
    logic act_fifo_rd_en;
    logic [(N*ACT_WIDTH)-1:0] act_fifo_rdata;

    logic act_pump_active;
    logic skew_buffer_en;
    
    logic signed [ACT_WIDTH-1:0] act_skew_in [N];
    logic signed [ACT_WIDTH-1:0] act_skew_out [N]; 

    act_sram #(
        .WORD_WIDTH(N * ACT_WIDTH), 
        .DEPTH(1024)
    ) a_sram_inst (
        .clk(clk),
        .w_en(act_sram_wen),
        .waddr(act_sram_waddr),
        .wdata(act_sram_wdata),
        .r_en(act_sram_ren),
        .raddr(act_sram_raddr),
        .rdata(act_sram_rdata)
    ); 

    input_fifo #(
        .DATA_WIDTH(N * ACT_WIDTH),
        .DEPTH(16)
    ) a_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(act_fifo_wr_en),
        .wr_data(act_sram_rdata),
        .full(act_fifo_full),
        .rd_en(act_fifo_rd_en),
        .rd_data(act_fifo_rdata),
        .empty(act_fifo_empty)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_sram_raddr <= '0;
            act_sram_ren <= 1'b0;
            act_fifo_wr_en <= 1'b0;
            act_pump_active <= 1'b0;
        end else begin
            if (start_exec) act_pump_active <= 1'b1;

            if (act_pump_active && !act_fifo_full && !act_sram_ren) begin
                act_sram_ren <= 1'b1;
            end else begin
                act_sram_ren <= 1'b0;
            end

            if (act_sram_ren) act_sram_raddr <= act_sram_raddr + 1'b1;
            act_fifo_wr_en <= act_sram_ren; 
        end
    end 

    assign act_fifo_rd_en = !act_fifo_empty; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) skew_buffer_en <= 1'b0;
        else skew_buffer_en <= act_fifo_rd_en;
    end 

    genvar i; 
    generate 
        for (int i = 0; i< N; i++) begin: UNPACK_ACT
            assign act_skew_in[i] = act_fifo_rdata[(i*ACT_WIDTH) +: ACT_WIDTH];
        end
    endgenerate 

    act_skew_buffer #(
        .N(N),
        .ACT_WIDTH(ACT_WIDTH)
    ) skew_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(skew_buffer_en),
        .act_in(act_skew_in),
        .act_out(act_skew_out)
    ); 

    logic weight_load_en_2d [N][N];
    logic signed [WT_WIDTH-1:0] weight_load_data_2d [N][N];

    always_comb begin
        for (int row = 0; row < N; row++) begin
            for (int col = 0; col < N; col++) begin
                if (weight_load_pulse && (weight_row == row) && (weight_col == col)) begin
                    weight_load_en_2d[row][col] = 1'b1;
                    weight_load_data_2d[row][col] = weight_out_1d;
                end else begin
                    weight_load_en_2d[row][col] = 1'b0;
                    weight_load_data_2d[row][col] = '0;
                end
            end
        end
    end 

    logic signed [PSUM_WIDTH-1:0] zero_psums [N];
    always_comb begin
        for (int j = 0; j < N; j++) begin
            zero_psums[j] = '0;
        end
    end 

    systolic_array #(
        .N(N),
        .ACT_WIDTH(ACT_WIDTH),
        .WT_WIDTH(WT_WIDTH),
        .PSUM_WIDTH(PSUM_WIDTH)
    ) core_array_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(skew_buffer_en),
        
        .act_in(act_skew_out),
        .psum_in(zero_psums), 
        .psum_out(tpu_out),
        
        .weight_load_en(weight_load_en_2d),
        .weight_load_data(weight_load_data_2d)
    );

endmodule



