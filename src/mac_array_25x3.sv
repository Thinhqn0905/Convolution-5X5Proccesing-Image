`timescale 1ns/1ps

module mac_array_25x3 #(
    parameter int DATA_W = 24,
    parameter int COEFF_W = 16,
    parameter int KSIZE = 5,
    parameter int KERNEL_Q = 8
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
    localparam int CH_W = DATA_W / 3;
    localparam int PROD_W = CH_W + 1 + COEFF_W;
    localparam int ACC_W = PROD_W + $clog2(TAPS) + 1;

    // =========================================================================
    //  Pipeline overview (6-stage, unchanged latency)
    //
    //  Stage 1 (S1): 25 multiplies per channel  -> register products
    //  Stage 2 (S2): 8 sub-group partial sums   -> register sub-group accumulators
    //  Stage 3 (S3): 4 group merges             -> register group accumulators
    //  Stage 4 (S4): 2-way merge                -> register merged accumulators
    //  Stage 5 (S5): final merge + normalize    -> register final accumulators
    //  Stage 6 (S6): saturate + pack            -> register output pixel
    // =========================================================================

    // ---- Per-tap products (combinational) ----
    (* use_dsp = "yes" *) logic signed [PROD_W-1:0] mul_r [0:TAPS-1];
    (* use_dsp = "yes" *) logic signed [PROD_W-1:0] mul_g [0:TAPS-1];
    (* use_dsp = "yes" *) logic signed [PROD_W-1:0] mul_b [0:TAPS-1];

    // ---- S1 registered products ----
    logic signed [PROD_W-1:0] mul_r_q [0:TAPS-1];
    logic signed [PROD_W-1:0] mul_g_q [0:TAPS-1];
    logic signed [PROD_W-1:0] mul_b_q [0:TAPS-1];

    // Runtime coefficient shadow bank. This is not a pixel pipeline stage:
    // it only shortens the coefficient-to-DSP timing path.
    logic signed [COEFF_W-1:0] coeff_q [0:TAPS-1];

    // ---- S2 sub-group partial sums ----
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] sub_r [0:7];
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] sub_g [0:7];
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] sub_b [0:7];
    logic signed [ACC_W-1:0] sub_r_q [0:7];
    logic signed [ACC_W-1:0] sub_g_q [0:7];
    logic signed [ACC_W-1:0] sub_b_q [0:7];

    // ---- S3 group sums ----
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] grp_r [0:3];
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] grp_g [0:3];
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] grp_b [0:3];
    logic signed [ACC_W-1:0] grp_r_q [0:3];
    logic signed [ACC_W-1:0] grp_g_q [0:3];
    logic signed [ACC_W-1:0] grp_b_q [0:3];

    // ---- S4 lo/hi merge ----
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] half_r [0:1];
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] half_g [0:1];
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] half_b [0:1];
    logic signed [ACC_W-1:0] half_r_q [0:1];
    logic signed [ACC_W-1:0] half_g_q [0:1];
    logic signed [ACC_W-1:0] half_b_q [0:1];

    // ---- S5 final accumulator + normalize ----
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] acc_r;
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] acc_g;
    (* use_dsp = "no" *) logic signed [ACC_W-1:0] acc_b;
    logic signed [ACC_W-1:0] nr;
    logic signed [ACC_W-1:0] ng;
    logic signed [ACC_W-1:0] nb;
    logic signed [ACC_W-1:0] nr_q;
    logic signed [ACC_W-1:0] ng_q;
    logic signed [ACC_W-1:0] nb_q;

    // ---- S6 saturate + output ----
    logic [7:0] r8_c;
    logic [7:0] g8_c;
    logic [7:0] b8_c;

    // ---- Valid pipeline ----
    logic valid_s1;
    logic valid_s2;
    logic valid_s3;
    logic valid_s4;
    logic valid_s5;

    // ---- Temporary extraction ----
    logic [CH_W-1:0] px_r;
    logic [CH_W-1:0] px_g;
    logic [CH_W-1:0] px_b;
    logic signed [COEFF_W-1:0] coeff;

    function automatic [7:0] sat_u8(input logic signed [ACC_W-1:0] val);
        if (val < 0) begin
            sat_u8 = 8'd0;
        end else if (val > 255) begin
            sat_u8 = 8'd255;
        end else begin
            sat_u8 = val[7:0];
        end
    endfunction

    // =====================================================================
    //  STAGE 0 (combinational): 25 multiplies per channel
    // =====================================================================
    always_comb begin
        for (int i = 0; i < TAPS; i++) begin
            px_r = window_flat[(i*DATA_W) +: CH_W];
            px_g = window_flat[(i*DATA_W) + CH_W +: CH_W];
            px_b = window_flat[(i*DATA_W) + (2*CH_W) +: CH_W];
            coeff = coeff_q[i];

            mul_r[i] = coeff * $signed({1'b0, px_r});
            mul_g[i] = coeff * $signed({1'b0, px_g});
            mul_b[i] = coeff * $signed({1'b0, px_b});
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < TAPS; i++) begin
                coeff_q[i] <= '0;
            end
            coeff_q[TAPS/2] <= (1 <<< KERNEL_Q);
        end else if (!valid_in) begin
            for (int i = 0; i < TAPS; i++) begin
                coeff_q[i] <= kernel_flat[(i*COEFF_W) +: COEFF_W];
            end
        end
    end

    // =====================================================================
    //  STAGE 1 (registered): capture multiply products
    // =====================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            valid_s1 <= 1'b0;
            for (int i = 0; i < TAPS; i++) begin
                mul_r_q[i] <= '0;
                mul_g_q[i] <= '0;
                mul_b_q[i] <= '0;
            end
        end else begin
            valid_s1 <= valid_in;
            if (valid_in) begin
                for (int i = 0; i < TAPS; i++) begin
                    mul_r_q[i] <= mul_r[i];
                    mul_g_q[i] <= mul_g[i];
                    mul_b_q[i] <= mul_b[i];
                end
            end
        end
    end

    // =====================================================================
    //  STAGE 2 (combinational -> registered): 8 sub-group partial sums
    //  Balanced tree: at most two adder levels in this stage.
    // =====================================================================
    always_comb begin
        sub_r[0] = (mul_r_q[0] + mul_r_q[1]) + (mul_r_q[2] + mul_r_q[3]);
        sub_g[0] = (mul_g_q[0] + mul_g_q[1]) + (mul_g_q[2] + mul_g_q[3]);
        sub_b[0] = (mul_b_q[0] + mul_b_q[1]) + (mul_b_q[2] + mul_b_q[3]);

        sub_r[1] = (mul_r_q[4] + mul_r_q[5]) + mul_r_q[6];
        sub_g[1] = (mul_g_q[4] + mul_g_q[5]) + mul_g_q[6];
        sub_b[1] = (mul_b_q[4] + mul_b_q[5]) + mul_b_q[6];

        sub_r[2] = (mul_r_q[7] + mul_r_q[8]) + mul_r_q[9];
        sub_g[2] = (mul_g_q[7] + mul_g_q[8]) + mul_g_q[9];
        sub_b[2] = (mul_b_q[7] + mul_b_q[8]) + mul_b_q[9];

        sub_r[3] = (mul_r_q[10] + mul_r_q[11]) + mul_r_q[12];
        sub_g[3] = (mul_g_q[10] + mul_g_q[11]) + mul_g_q[12];
        sub_b[3] = (mul_b_q[10] + mul_b_q[11]) + mul_b_q[12];

        sub_r[4] = (mul_r_q[13] + mul_r_q[14]) + mul_r_q[15];
        sub_g[4] = (mul_g_q[13] + mul_g_q[14]) + mul_g_q[15];
        sub_b[4] = (mul_b_q[13] + mul_b_q[14]) + mul_b_q[15];

        sub_r[5] = (mul_r_q[16] + mul_r_q[17]) + mul_r_q[18];
        sub_g[5] = (mul_g_q[16] + mul_g_q[17]) + mul_g_q[18];
        sub_b[5] = (mul_b_q[16] + mul_b_q[17]) + mul_b_q[18];

        sub_r[6] = (mul_r_q[19] + mul_r_q[20]) + mul_r_q[21];
        sub_g[6] = (mul_g_q[19] + mul_g_q[20]) + mul_g_q[21];
        sub_b[6] = (mul_b_q[19] + mul_b_q[20]) + mul_b_q[21];

        sub_r[7] = (mul_r_q[22] + mul_r_q[23]) + mul_r_q[24];
        sub_g[7] = (mul_g_q[22] + mul_g_q[23]) + mul_g_q[24];
        sub_b[7] = (mul_b_q[22] + mul_b_q[23]) + mul_b_q[24];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_s2 <= 1'b0;
            for (int i = 0; i < 8; i++) begin
                sub_r_q[i] <= '0;
                sub_g_q[i] <= '0;
                sub_b_q[i] <= '0;
            end
        end else begin
            valid_s2 <= valid_s1;
            if (valid_s1) begin
                for (int i = 0; i < 8; i++) begin
                    sub_r_q[i] <= sub_r[i];
                    sub_g_q[i] <= sub_g[i];
                    sub_b_q[i] <= sub_b[i];
                end
            end
        end
    end

    // =====================================================================
    //  STAGE 3 (combinational -> registered): merge sub-group pairs
    // =====================================================================
    always_comb begin
        grp_r[0] = sub_r_q[0] + sub_r_q[1];
        grp_g[0] = sub_g_q[0] + sub_g_q[1];
        grp_b[0] = sub_b_q[0] + sub_b_q[1];

        grp_r[1] = sub_r_q[2] + sub_r_q[3];
        grp_g[1] = sub_g_q[2] + sub_g_q[3];
        grp_b[1] = sub_b_q[2] + sub_b_q[3];

        grp_r[2] = sub_r_q[4] + sub_r_q[5];
        grp_g[2] = sub_g_q[4] + sub_g_q[5];
        grp_b[2] = sub_b_q[4] + sub_b_q[5];

        grp_r[3] = sub_r_q[6] + sub_r_q[7];
        grp_g[3] = sub_g_q[6] + sub_g_q[7];
        grp_b[3] = sub_b_q[6] + sub_b_q[7];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_s3 <= 1'b0;
            for (int i = 0; i < 4; i++) begin
                grp_r_q[i] <= '0;
                grp_g_q[i] <= '0;
                grp_b_q[i] <= '0;
            end
        end else begin
            valid_s3 <= valid_s2;
            if (valid_s2) begin
                for (int i = 0; i < 4; i++) begin
                    grp_r_q[i] <= grp_r[i];
                    grp_g_q[i] <= grp_g[i];
                    grp_b_q[i] <= grp_b[i];
                end
            end
        end
    end

    // =====================================================================
    //  STAGE 4 (combinational -> registered): 2-way merge
    // =====================================================================
    always_comb begin
        half_r[0] = grp_r_q[0] + grp_r_q[1];
        half_g[0] = grp_g_q[0] + grp_g_q[1];
        half_b[0] = grp_b_q[0] + grp_b_q[1];

        half_r[1] = grp_r_q[2] + grp_r_q[3];
        half_g[1] = grp_g_q[2] + grp_g_q[3];
        half_b[1] = grp_b_q[2] + grp_b_q[3];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_s4 <= 1'b0;
            half_r_q[0] <= '0; half_r_q[1] <= '0;
            half_g_q[0] <= '0; half_g_q[1] <= '0;
            half_b_q[0] <= '0; half_b_q[1] <= '0;
        end else begin
            valid_s4 <= valid_s3;
            if (valid_s3) begin
                half_r_q[0] <= half_r[0]; half_r_q[1] <= half_r[1];
                half_g_q[0] <= half_g[0]; half_g_q[1] <= half_g[1];
                half_b_q[0] <= half_b[0]; half_b_q[1] <= half_b[1];
            end
        end
    end

    // =====================================================================
    //  STAGE 5 (combinational -> registered): final merge + normalize
    // =====================================================================
    always_comb begin
        acc_r = half_r_q[0] + half_r_q[1];
        acc_g = half_g_q[0] + half_g_q[1];
        acc_b = half_b_q[0] + half_b_q[1];

        nr = acc_r >>> KERNEL_Q;
        ng = acc_g >>> KERNEL_Q;
        nb = acc_b >>> KERNEL_Q;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_s5 <= 1'b0;
            nr_q <= '0;
            ng_q <= '0;
            nb_q <= '0;
        end else begin
            valid_s5 <= valid_s4;
            if (valid_s4) begin
                nr_q <= nr;
                ng_q <= ng;
                nb_q <= nb;
            end
        end
    end

    // =====================================================================
    //  STAGE 6 (combinational -> registered): saturate + pack output
    // =====================================================================
    always_comb begin
        r8_c = sat_u8(nr_q);
        g8_c = sat_u8(ng_q);
        b8_c = sat_u8(nb_q);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            pixel_out <= '0;
        end else begin
            valid_out <= valid_s5;
            if (valid_s5) begin
                pixel_out <= {b8_c, g8_c, r8_c};
            end
        end
    end
endmodule
