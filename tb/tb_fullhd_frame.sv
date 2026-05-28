`timescale 1ns/1ps

module tb_fullhd_frame;
`ifndef TB_IMAGE_W
    localparam int IMAGE_W = 1920;
`else
    localparam int IMAGE_W = `TB_IMAGE_W;
`endif

`ifndef TB_IMAGE_H
    localparam int IMAGE_H = 1080;
`else
    localparam int IMAGE_H = `TB_IMAGE_H;
`endif

    localparam int KSIZE = 5;
    localparam int PIXELS = IMAGE_W * IMAGE_H;
    localparam int EXPECT_VALID = (IMAGE_W - (KSIZE - 1)) * (IMAGE_H - (KSIZE - 1));

    logic clk;
    logic rst;
    logic in_valid;
    logic [23:0] in_pixel;
    logic kernel_wr_en;
    logic [4:0] kernel_wr_addr;
    logic signed [15:0] kernel_wr_data;
    logic out_valid;
    logic [23:0] out_pixel;

    int x;
    int y;
    int idx;
    int valid_count;
    int unknown_count;
    int out_file;

    logic [23:0] frame_mem [0:PIXELS-1];
    logic signed [15:0] kernel_mem [0:KSIZE*KSIZE-1];

    top_convolution #(
        .IMAGE_WIDTH(IMAGE_W)
    ) dut (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_pixel(in_pixel),
        .kernel_wr_en(kernel_wr_en),
        .kernel_wr_addr(kernel_wr_addr),
        .kernel_wr_data(kernel_wr_data),
        .out_valid(out_valid),
        .out_pixel(out_pixel)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task write_kernel(input [4:0] addr, input signed [15:0] data);
        begin
            @(negedge clk);
            kernel_wr_en = 1'b1;
            kernel_wr_addr = addr;
            kernel_wr_data = data;
            @(posedge clk);
            @(negedge clk);
            kernel_wr_en = 1'b0;
            kernel_wr_addr = '0;
            kernel_wr_data = '0;
        end
    endtask

    initial begin
        $readmemh("sim/fullhd_frame_in.hex", frame_mem);
        $readmemh("sim/fullhd_kernel.hex", kernel_mem);

        rst = 1'b1;
        in_valid = 1'b0;
        in_pixel = '0;
        kernel_wr_en = 1'b0;
        kernel_wr_addr = '0;
        kernel_wr_data = '0;
        valid_count = 0;
        unknown_count = 0;

        out_file = $fopen("sim/fullhd_frame_out.hex", "w");
        if (out_file == 0) begin
            $display("TB FAIL: cannot open sim/fullhd_frame_out.hex");
            $fatal;
        end

        repeat (4) @(posedge clk);
        rst = 1'b0;

        for (idx = 0; idx < KSIZE*KSIZE; idx++) begin
            write_kernel(idx[4:0], kernel_mem[idx]);
        end

        for (y = 0; y < IMAGE_H; y++) begin
            for (x = 0; x < IMAGE_W; x++) begin
                idx = (y * IMAGE_W) + x;
                @(negedge clk);
                in_valid = 1'b1;
                in_pixel = frame_mem[idx];
                @(posedge clk);
            end
        end

        @(negedge clk);
        in_valid = 1'b0;
        in_pixel = '0;

        repeat (256) @(posedge clk);
        $fclose(out_file);

        if ((valid_count == EXPECT_VALID) && (unknown_count == 0)) begin
            $display("TB PASS: valid_count=%0d expected=%0d", valid_count, EXPECT_VALID);
        end else begin
            $display("TB FAIL: valid_count=%0d expected=%0d unknown=%0d",
                valid_count, EXPECT_VALID, unknown_count);
            $fatal;
        end

        $finish;
    end

    always @(posedge clk) begin
        if (out_valid) begin
            valid_count = valid_count + 1;
            $fwrite(out_file, "%06h\n", out_pixel);

            if (^out_pixel === 1'bx) begin
                unknown_count = unknown_count + 1;
            end
        end
    end
endmodule
