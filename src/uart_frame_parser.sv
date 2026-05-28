`timescale 1ns/1ps

// ============================================================================
// uart_frame_parser - UART Byte Stream → Kernel Write + Pixel AXI-Stream
// ============================================================================
// Converts incoming UART bytes into two types of commands:
//   1. Kernel write: Program 25 coefficients (16-bit signed) into the core
//   2. Pixel stream: Assemble RGB triplets and push to AXI-Stream interface
//
// UART Protocol (PC → FPGA):
//   0x4B ('K') : Kernel load command
//                Next 50 bytes = 25 × 16-bit signed coefficients (MSB first)
//                After all 50 bytes, auto-returns to IDLE.
//
//   0x44 ('D') : Data (pixel) stream command
//                Following bytes are RGB triplets (R, G, B order)
//                Continues until 0x53 ('S') stop command received.
//
//   0x53 ('S') : Stop command - return to IDLE from any state.
//
//   0x52 ('R') : Reset line buffer - asserts soft_rst for 1 cycle, then IDLE.
//
// ============================================================================

module uart_frame_parser #(
    parameter int COEFF_W = 16,
    parameter int KSIZE   = 5
) (
    input  logic                            clk,
    input  logic                            rst,

    // From uart_rx
    input  logic [7:0]                      rx_byte,
    input  logic                            rx_valid,

    // To axi_stream_conv_wrapper (pixel data path)
    output logic                            s_axis_tvalid,
    output logic [23:0]                     s_axis_tdata,

    // To axi_stream_conv_wrapper (kernel programming)
    output logic                            kernel_wr_en,
    output logic [$clog2(KSIZE*KSIZE)-1:0]  kernel_wr_addr,
    output logic signed [COEFF_W-1:0]       kernel_wr_data,

    // Soft reset output (to reset line buffers between frames)
    output logic                            soft_rst,

    // Status outputs for debug LEDs
    output logic                            is_kernel_mode,
    output logic                            is_pixel_mode
);

    localparam int TAPS = KSIZE * KSIZE;   // 25

    // Command bytes
    localparam logic [7:0] CMD_KERNEL = 8'h4B;  // 'K'
    localparam logic [7:0] CMD_DATA   = 8'h44;  // 'D'
    localparam logic [7:0] CMD_STOP   = 8'h53;  // 'S'
    localparam logic [7:0] CMD_RESET  = 8'h52;  // 'R'

    // FSM states
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_KERNEL_MSB,     // waiting for coefficient MSB
        ST_KERNEL_LSB,     // waiting for coefficient LSB
        ST_PIXEL_R,        // waiting for R byte
        ST_PIXEL_G,        // waiting for G byte
        ST_PIXEL_B         // waiting for B byte
    } state_t;

    state_t state;

    // Kernel loading
    logic [$clog2(TAPS)-1:0] kern_idx;     // 0..24
    logic [7:0]              kern_msb;      // buffered MSB

    // Pixel assembly
    logic [7:0] pix_r, pix_g;

    always_ff @(posedge clk) begin
        if (rst) begin
            state          <= ST_IDLE;
            s_axis_tvalid  <= 1'b0;
            s_axis_tdata   <= 24'd0;
            kernel_wr_en   <= 1'b0;
            kernel_wr_addr <= '0;
            kernel_wr_data <= '0;
            soft_rst       <= 1'b0;
            is_kernel_mode <= 1'b0;
            is_pixel_mode  <= 1'b0;
            kern_idx       <= '0;
            kern_msb       <= 8'd0;
            pix_r          <= 8'd0;
            pix_g          <= 8'd0;
        end else begin
            // Default: deassert single-cycle pulses
            s_axis_tvalid  <= 1'b0;
            kernel_wr_en   <= 1'b0;
            soft_rst       <= 1'b0;

            if (rx_valid) begin
                case (state)
                    // --------------------------------------------------------
                    ST_IDLE: begin
                        is_kernel_mode <= 1'b0;
                        is_pixel_mode  <= 1'b0;
                        case (rx_byte)
                            CMD_KERNEL: begin
                                state          <= ST_KERNEL_MSB;
                                kern_idx       <= '0;
                                is_kernel_mode <= 1'b1;
                            end
                            CMD_DATA: begin
                                state         <= ST_PIXEL_R;
                                is_pixel_mode <= 1'b1;
                            end
                            CMD_RESET: begin
                                soft_rst <= 1'b1;
                            end
                            default: ; // ignore unknown commands
                        endcase
                    end

                    // --------------------------------------------------------
                    // Kernel loading: 2 bytes per coefficient (MSB first)
                    // --------------------------------------------------------
                    ST_KERNEL_MSB: begin
                        if (rx_byte == CMD_STOP) begin
                            state          <= ST_IDLE;
                            is_kernel_mode <= 1'b0;
                        end else begin
                            kern_msb <= rx_byte;
                            state    <= ST_KERNEL_LSB;
                        end
                    end

                    ST_KERNEL_LSB: begin
                        // Commit the coefficient
                        kernel_wr_en   <= 1'b1;
                        kernel_wr_addr <= kern_idx;
                        kernel_wr_data <= $signed({kern_msb, rx_byte});

                        if (kern_idx == TAPS - 1) begin
                            // All 25 coefficients loaded
                            state          <= ST_IDLE;
                            is_kernel_mode <= 1'b0;
                            kern_idx       <= '0;
                        end else begin
                            kern_idx <= kern_idx + 1;
                            state    <= ST_KERNEL_MSB;
                        end
                    end

                    // --------------------------------------------------------
                    // Pixel streaming: 3 bytes per pixel (R, G, B)
                    // --------------------------------------------------------
                    ST_PIXEL_R: begin
                        if (rx_byte == CMD_STOP) begin
                            state         <= ST_IDLE;
                            is_pixel_mode <= 1'b0;
                        end else begin
                            pix_r <= rx_byte;
                            state <= ST_PIXEL_G;
                        end
                    end

                    ST_PIXEL_G: begin
                        pix_g <= rx_byte;
                        state <= ST_PIXEL_B;
                    end

                    ST_PIXEL_B: begin
                        // Complete pixel assembled → push to AXI-Stream
                        s_axis_tvalid <= 1'b1;
                        s_axis_tdata  <= {pix_r, pix_g, rx_byte};
                        state         <= ST_PIXEL_R;
                    end

                    default: state <= ST_IDLE;
                endcase
            end
        end
    end

endmodule
