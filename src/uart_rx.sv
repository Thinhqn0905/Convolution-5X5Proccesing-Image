`timescale 1ns/1ps

// UART Receiver with 16x oversampling
// Detect start bit, deserialize 8 data bits (LSB first), verify stop bit.
module uart_rx #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 115_200
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       rx,        // serial input (active-low start bit)
    output logic [7:0] rx_data,   // received byte
    output logic       rx_valid   // pulse high for 1 cycle when byte ready
);
    localparam int CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE;
    localparam int HALF_BIT      = CLKS_PER_BIT / 2;

    // State machine
    typedef enum logic [2:0] {
        S_IDLE,
        S_START,
        S_DATA,
        S_STOP
    } state_t;

    state_t state;
    int unsigned clk_cnt;
    int unsigned bit_idx;
    logic [7:0]  shift_reg;

    // Double-register the async rx input to avoid metastability
    logic rx_meta, rx_sync;
    always_ff @(posedge clk) begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'h00;
            rx_data   <= 8'h00;
            rx_valid  <= 1'b0;
        end else begin
            rx_valid <= 1'b0;  // default: deassert

            case (state)
                S_IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_sync == 1'b0) begin
                        // Possible start bit detected
                        state <= S_START;
                    end
                end

                S_START: begin
                    // Wait until middle of start bit to verify it's still low
                    if (clk_cnt == HALF_BIT - 1) begin
                        if (rx_sync == 1'b0) begin
                            // Valid start bit confirmed
                            clk_cnt <= 0;
                            state   <= S_DATA;
                        end else begin
                            // Glitch, go back to idle
                            state <= S_IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        shift_reg[bit_idx] <= rx_sync;  // LSB first
                        if (bit_idx == 7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_STOP: begin
                    // Wait for middle of stop bit
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        rx_data  <= shift_reg;
                        rx_valid <= 1'b1;
                        state    <= S_IDLE;
                        clk_cnt  <= 0;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
