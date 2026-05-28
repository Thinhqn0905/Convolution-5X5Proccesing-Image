`timescale 1ns/1ps

// ============================================================================
// arty_top - Board-Level Top Wrapper for Arty A7 100T
// ============================================================================
// This is the ONLY module set as Vivado top.
// Only physical board pins are exposed: clk, rst, uart_rx, uart_tx, led[3:0].
//
// Dataflow:
//   PC → UART RX → uart_frame_parser → axi_stream_conv_wrapper
//                                     → uart_frame_packer → UART TX → PC
//
// UART Protocol (PC → FPGA):
//   'K' (0x4B) : Kernel load  → 50 bytes (25 × 16-bit signed, MSB first)
//   'D' (0x44) : Pixel stream → RGB triplets (R, G, B) until 'S'
//   'S' (0x53) : Stop pixel stream
//   'R' (0x52) : Reset line buffers (between frames)
//
// UART Protocol (FPGA → PC):
//   Each output pixel → 3 bytes (R, G, B)
//
// Default kernel: Gaussian 5x5 loaded at power-on reset.
// ============================================================================

module arty_top #(
    parameter int CLK_FREQ    = 100_000_000,
    parameter int BAUD_RATE   = 115_200,
    parameter int IMAGE_WIDTH = 160       // Match resolution streamed from PC
) (
    input  logic       clk,       // E3  - 100 MHz system clock
    input  logic       rst,       // D9  - BTN0 (active-high)
    input  logic       uart_rx,   // A9  - USB-UART RX (PC → FPGA)
    output logic       uart_tx,   // D10 - USB-UART TX (FPGA → PC)
    output logic [3:0] led        // H5, J5, T9, T10 - Debug LEDs
);

    // ========================================================================
    // Internal wires
    // ========================================================================

    // UART RX output
    logic [7:0] rx_byte;
    logic       rx_valid;

    // Frame parser → convolution wrapper (pixel AXI-Stream)
    logic        parser_tvalid;
    logic [23:0] parser_tdata;

    // Frame parser → convolution wrapper (kernel programming)
    logic                  kern_wr_en;
    logic [4:0]            kern_wr_addr;
    logic signed [15:0]    kern_wr_data;

    // Frame parser → soft reset
    logic parser_soft_rst;

    // Frame parser status
    logic parser_kernel_mode;
    logic parser_pixel_mode;

    // Convolution wrapper → frame packer (output AXI-Stream)
    logic        conv_tvalid;
    logic        conv_tready;
    logic [23:0] conv_tdata;

    // Convolution overflow flag
    logic overflow_flag;

    // Frame packer → UART TX
    logic [7:0]  tx_byte;
    logic        tx_start;
    logic        tx_busy;
    logic        packer_active;

    // Combined reset: hardware button OR parser soft reset
    logic rst_combined;
    assign rst_combined = rst | parser_soft_rst;

    // AXI-Stream active-low reset for wrapper
    logic aresetn;
    assign aresetn = ~rst_combined;

    // Kernel programming: combine init (at boot) and parser (runtime) sources
    logic                  kern_init_wr_en;
    logic [4:0]            kern_init_wr_addr;
    logic signed [15:0]    kern_init_wr_data;
    logic                  kern_init_done;
    logic [4:0]            kern_init_cnt;

    logic                  kern_final_wr_en;
    logic [4:0]            kern_final_wr_addr;
    logic signed [15:0]    kern_final_wr_data;

    // Mux: during init use boot loader, after init use parser
    assign kern_final_wr_en   = kern_init_done ? kern_wr_en   : kern_init_wr_en;
    assign kern_final_wr_addr = kern_init_done ? kern_wr_addr : kern_init_wr_addr;
    assign kern_final_wr_data = kern_init_done ? kern_wr_data : kern_init_wr_data;

    // ========================================================================
    // Default Gaussian 5x5 Kernel (Q8, sum=256)
    // ========================================================================
    //  1  4  6  4  1
    //  4 16 24 16  4
    //  6 24 36 24  6
    //  4 16 24 16  4
    //  1  4  6  4  1
    logic signed [15:0] GAUSS_K [0:24];
    assign GAUSS_K[ 0]=16'sd1;  assign GAUSS_K[ 1]=16'sd4;  assign GAUSS_K[ 2]=16'sd6;
    assign GAUSS_K[ 3]=16'sd4;  assign GAUSS_K[ 4]=16'sd1;
    assign GAUSS_K[ 5]=16'sd4;  assign GAUSS_K[ 6]=16'sd16; assign GAUSS_K[ 7]=16'sd24;
    assign GAUSS_K[ 8]=16'sd16; assign GAUSS_K[ 9]=16'sd4;
    assign GAUSS_K[10]=16'sd6;  assign GAUSS_K[11]=16'sd24; assign GAUSS_K[12]=16'sd36;
    assign GAUSS_K[13]=16'sd24; assign GAUSS_K[14]=16'sd6;
    assign GAUSS_K[15]=16'sd4;  assign GAUSS_K[16]=16'sd16; assign GAUSS_K[17]=16'sd24;
    assign GAUSS_K[18]=16'sd16; assign GAUSS_K[19]=16'sd4;
    assign GAUSS_K[20]=16'sd1;  assign GAUSS_K[21]=16'sd4;  assign GAUSS_K[22]=16'sd6;
    assign GAUSS_K[23]=16'sd4;  assign GAUSS_K[24]=16'sd1;

    // ========================================================================
    // Boot-time kernel initialization (loads Gaussian before any UART data)
    // ========================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            kern_init_cnt     <= 5'd0;
            kern_init_done    <= 1'b0;
            kern_init_wr_en   <= 1'b0;
            kern_init_wr_addr <= 5'd0;
            kern_init_wr_data <= 16'sd0;
        end else if (!kern_init_done) begin
            kern_init_wr_en   <= 1'b1;
            kern_init_wr_addr <= kern_init_cnt;
            kern_init_wr_data <= GAUSS_K[kern_init_cnt];
            if (kern_init_cnt == 5'd24) begin
                kern_init_done <= 1'b1;
            end else begin
                kern_init_cnt <= kern_init_cnt + 5'd1;
            end
        end else begin
            kern_init_wr_en <= 1'b0;
        end
    end

    // ========================================================================
    // UART Receiver
    // ========================================================================
    uart_rx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_uart_rx (
        .clk      (clk),
        .rst      (rst),
        .rx       (uart_rx),
        .rx_data  (rx_byte),
        .rx_valid (rx_valid)
    );

    // ========================================================================
    // Frame Parser (UART bytes → kernel writes + pixel AXI-Stream)
    // ========================================================================
    uart_frame_parser #(
        .COEFF_W (16),
        .KSIZE   (5)
    ) u_parser (
        .clk            (clk),
        .rst            (rst),
        .rx_byte        (rx_byte),
        .rx_valid       (rx_valid),
        .s_axis_tvalid  (parser_tvalid),
        .s_axis_tdata   (parser_tdata),
        .kernel_wr_en   (kern_wr_en),
        .kernel_wr_addr (kern_wr_addr),
        .kernel_wr_data (kern_wr_data),
        .soft_rst       (parser_soft_rst),
        .is_kernel_mode (parser_kernel_mode),
        .is_pixel_mode  (parser_pixel_mode)
    );

    // ========================================================================
    // AXI-Stream Convolution Wrapper (internal - NO external I/O pins)
    // ========================================================================
    axi_stream_conv_wrapper #(
        .DATA_W      (24),
        .COEFF_W     (16),
        .KSIZE       (5),
        .KERNEL_Q    (8),
        .IMAGE_WIDTH (IMAGE_WIDTH)
    ) u_conv (
        .aclk           (clk),
        .aresetn        (aresetn),
        // Pixel input from parser
        .s_axis_tvalid  (parser_tvalid),
        .s_axis_tready  (),   // UART is so slow, core is always ready
        .s_axis_tdata   (parser_tdata),
        // Pixel output to packer
        .m_axis_tvalid  (conv_tvalid),
        .m_axis_tready  (conv_tready),
        .m_axis_tdata   (conv_tdata),
        // Kernel programming (muxed: boot init OR runtime UART)
        .kernel_wr_en   (kern_final_wr_en),
        .kernel_wr_addr (kern_final_wr_addr),
        .kernel_wr_data (kern_final_wr_data),
        .overflow_flag  (overflow_flag)
    );

    // ========================================================================
    // Frame Packer (convolution output → UART TX bytes)
    // ========================================================================
    uart_frame_packer u_packer (
        .clk            (clk),
        .rst            (rst),
        // From convolution output
        .m_axis_tvalid  (conv_tvalid),
        .m_axis_tready  (conv_tready),
        .m_axis_tdata   (conv_tdata),
        // To UART TX
        .tx_byte        (tx_byte),
        .tx_start       (tx_start),
        .tx_busy        (tx_busy),
        .is_transmitting(packer_active)
    );

    // ========================================================================
    // UART Transmitter
    // ========================================================================
    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_uart_tx (
        .clk      (clk),
        .rst      (rst),
        .tx_data  (tx_byte),
        .tx_start (tx_start),
        .tx       (uart_tx),
        .tx_busy  (tx_busy)
    );

    // ========================================================================
    // Debug LEDs
    // ========================================================================
    // led[0] = RX activity      (blinks ~100ms when bytes arrive)
    // led[1] = Kernel init done (solid after boot / after 'K' command)
    // led[2] = TX activity      (blinks ~100ms when sending results)
    // led[3] = Overflow error   (solid if output buffer overflows)

    logic [23:0] rx_blink, tx_blink;

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_blink <= 24'd0;
            tx_blink <= 24'd0;
        end else begin
            if (rx_valid)
                rx_blink <= 24'd10_000_000;  // ~100ms @ 100MHz
            else if (rx_blink > 0)
                rx_blink <= rx_blink - 1;

            if (tx_start)
                tx_blink <= 24'd10_000_000;
            else if (tx_blink > 0)
                tx_blink <= tx_blink - 1;
        end
    end

    assign led[0] = (rx_blink > 0);
    assign led[1] = kern_init_done;
    assign led[2] = (tx_blink > 0);
    assign led[3] = overflow_flag;

endmodule
