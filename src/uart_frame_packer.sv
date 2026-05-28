`timescale 1ns/1ps

// ============================================================================
// uart_frame_packer - Convolution Output AXI-Stream → UART Byte Stream
// ============================================================================
// Accepts 24-bit RGB pixels from the convolution engine via AXI-Stream
// and serializes each pixel into 3 UART bytes (R, G, B order).
//
// Provides m_axis_tready backpressure: holds off the convolution output
// until the current pixel's 3 bytes are fully transmitted via UART TX.
//
// UART Protocol (FPGA → PC):
//   For each output pixel, sends 3 bytes:
//     Byte 0: R channel [23:16]
//     Byte 1: G channel [15:8]
//     Byte 2: B channel [7:0]
// ============================================================================

module uart_frame_packer (
    input  logic        clk,
    input  logic        rst,

    // From axi_stream_conv_wrapper (convolution output)
    input  logic        m_axis_tvalid,
    output logic        m_axis_tready,
    input  logic [23:0] m_axis_tdata,

    // To uart_tx
    output logic [7:0]  tx_byte,
    output logic        tx_start,
    input  logic        tx_busy,

    // Status for debug
    output logic        is_transmitting
);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_SEND_R,
        ST_WAIT_R,
        ST_SEND_G,
        ST_WAIT_G,
        ST_SEND_B,
        ST_WAIT_B
    } state_t;

    state_t state;
    logic [23:0] pixel_buf;

    assign is_transmitting = (state != ST_IDLE);

    // Accept new pixel only when idle
    assign m_axis_tready = (state == ST_IDLE);

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= ST_IDLE;
            pixel_buf <= 24'd0;
            tx_byte   <= 8'd0;
            tx_start  <= 1'b0;
        end else begin
            tx_start <= 1'b0;  // default deassert

            case (state)
                ST_IDLE: begin
                    if (m_axis_tvalid) begin
                        // Latch the output pixel
                        pixel_buf <= m_axis_tdata;
                        state     <= ST_SEND_R;
                    end
                end

                // --- Send R byte ---
                ST_SEND_R: begin
                    if (!tx_busy) begin
                        tx_byte  <= pixel_buf[23:16];
                        tx_start <= 1'b1;
                        state    <= ST_WAIT_R;
                    end
                end

                ST_WAIT_R: begin
                    // Wait for UART TX to finish R byte
                    if (!tx_busy) begin
                        state <= ST_SEND_G;
                    end
                end

                // --- Send G byte ---
                ST_SEND_G: begin
                    if (!tx_busy) begin
                        tx_byte  <= pixel_buf[15:8];
                        tx_start <= 1'b1;
                        state    <= ST_WAIT_G;
                    end
                end

                ST_WAIT_G: begin
                    if (!tx_busy) begin
                        state <= ST_SEND_B;
                    end
                end

                // --- Send B byte ---
                ST_SEND_B: begin
                    if (!tx_busy) begin
                        tx_byte  <= pixel_buf[7:0];
                        tx_start <= 1'b1;
                        state    <= ST_WAIT_B;
                    end
                end

                ST_WAIT_B: begin
                    if (!tx_busy) begin
                        state <= ST_IDLE;  // Done, ready for next pixel
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
