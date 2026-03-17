`timescale 1ns/1ps

module mac_array_25x3 #(
    parameter int DATA_W = 24,
    parameter int COEFF_W = 16,
    parameter int KSIZE = 5,
    parameter int KERNEL_Q = 4
) (
    input  logic                                clk,
    input  logic                                rst,
    input  logic                                valid_in,
    input  logic [DATA_W*KSIZE*KSIZE-1:0]       window_flat,
    input  logic signed [COEFF_W*KSIZE*KSIZE-1:0] kernel_flat,
    output logic                                valid_out,
    output logic [DATA_W-1:0]                   pixel_out
);
    localparam int TAPS = KSIZE * KSIZE;

    logic signed [47:0] acc_r;
    logic signed [47:0] acc_g;
    logic signed [47:0] acc_b;
    logic [7:0] r8;
    logic [7:0] g8;
    logic [7:0] b8;

    int i;
    logic [7:0] px_r;
    logic [7:0] px_g;
    logic [7:0] px_b;
    logic signed [COEFF_W-1:0] coeff;
    logic signed [47:0] nr;
    logic signed [47:0] ng;
    logic signed [47:0] nb;

    function automatic [7:0] sat_u8(input logic signed [47:0] val);
        if (val < 0) begin
            sat_u8 = 8'd0;
        end else if (val > 255) begin
            sat_u8 = 8'd255;
        end else begin
            sat_u8 = val[7:0];
        end
    endfunction

    always @* begin
        acc_r = '0;
        acc_g = '0;
        acc_b = '0;
        for (i = 0; i < TAPS; i++) begin
            px_r = window_flat[(i*DATA_W) +: 8];
            px_g = window_flat[(i*DATA_W) + 8 +: 8];
            px_b = window_flat[(i*DATA_W) + 16 +: 8];
            coeff = kernel_flat[(i*COEFF_W) +: COEFF_W];

            acc_r = acc_r + ($signed({1'b0, px_r}) * coeff);
            acc_g = acc_g + ($signed({1'b0, px_g}) * coeff);
            acc_b = acc_b + ($signed({1'b0, px_b}) * coeff);
        end

        nr = acc_r >>> KERNEL_Q;
        ng = acc_g >>> KERNEL_Q;
        nb = acc_b >>> KERNEL_Q;

        r8 = sat_u8(nr);
        g8 = sat_u8(ng);
        b8 = sat_u8(nb);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_out <= '0;
        end else begin
            valid_out <= valid_in;
            pixel_out <= {b8, g8, r8};
        end
    end
endmodule
