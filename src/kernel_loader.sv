`timescale 1ns/1ps

module kernel_loader #(
    parameter int COEFF_W = 16,
    parameter int KSIZE = 5,
    parameter int KERNEL_Q = 4
) (
    input  logic                          clk,
    input  logic                          rst,
    input  logic                          wr_en,
    input  logic [$clog2(KSIZE*KSIZE)-1:0] wr_addr,
    input  logic signed [COEFF_W-1:0]     wr_data,
    output logic signed [COEFF_W*KSIZE*KSIZE-1:0] kernel_flat
);
    localparam int TAPS = KSIZE * KSIZE;
    logic signed [COEFF_W-1:0] coeff_mem [0:TAPS-1];
    int i;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS; i++) begin
                coeff_mem[i] <= '0;
            end
            coeff_mem[TAPS/2] <= (1 <<< KERNEL_Q);
        end else if (wr_en) begin
            coeff_mem[wr_addr] <= wr_data;
        end
    end

    always_comb begin
        for (i = 0; i < TAPS; i++) begin
            kernel_flat[(i*COEFF_W) +: COEFF_W] = coeff_mem[i];
        end
    end
endmodule
