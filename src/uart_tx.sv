`timescale 1ns/1ps

// UART Transmitter
// Serialize 1 start bit + 8 data bits (LSB first) + 1 stop bit.
module uart_tx #(
    parameter int CLK_FREQ  = 100_000_000,
    parameter int BAUD_RATE = 115_200
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] tx_data,   // byte to send
    input  logic       tx_start,  // pulse to initiate transmission
    output logic       tx,        // serial output
    output logic       tx_busy    // high while transmitting
);
    localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

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

    assign tx_busy = (state != S_IDLE);

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'hFF;
            tx        <= 1'b1;  // idle high
        end else begin
            case (state)
                S_IDLE: begin
                    tx      <= 1'b1;
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        state     <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0;  // start bit = low
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_DATA: begin
                    tx <= shift_reg[bit_idx];  // LSB first
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
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
                    tx <= 1'b1;  // stop bit = high
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
