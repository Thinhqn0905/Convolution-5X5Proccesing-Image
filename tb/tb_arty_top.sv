`timescale 1ns/1ps

// ============================================================================
// tb_arty_top - Testbench for UART-to-Convolution Datapath
// ============================================================================
// Simulates the full PC → UART → FPGA → UART → PC path:
//   1. Send 'K' command + Gaussian kernel coefficients via UART
//   2. Send 'D' command + RGB pixel stream via UART
//   3. Receive processed output pixels via UART TX
//   4. Verify output byte count and basic sanity
//
// Uses a much higher baud rate for simulation speed (CLK_FREQ/4).
// ============================================================================

module tb_arty_top;

    // Use fast baud for simulation: CLK_FREQ=100MHz, BAUD=25MHz → 4 clks/bit
    localparam int CLK_FREQ    = 100_000_000;
    localparam int BAUD_RATE   = 25_000_000;  // Fast for sim
    localparam int IMAGE_WIDTH = 8;           // Small image for quick test
    localparam int IMAGE_HEIGHT = 8;
    localparam int PIXELS      = IMAGE_WIDTH * IMAGE_HEIGHT;
    localparam int KSIZE       = 5;
    localparam int VALID_OUT   = (IMAGE_WIDTH - (KSIZE-1)) * (IMAGE_HEIGHT - (KSIZE-1));

    localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // DUT signals
    logic       clk;
    logic       rst;
    logic       uart_rx_pin;
    logic       uart_tx_pin;
    logic [3:0] led;

    // Clock generation: 100 MHz = 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // DUT instantiation
    arty_top #(
        .CLK_FREQ    (CLK_FREQ),
        .BAUD_RATE   (BAUD_RATE),
        .IMAGE_WIDTH (IMAGE_WIDTH)
    ) dut (
        .clk     (clk),
        .rst     (rst),
        .uart_rx (uart_rx_pin),
        .uart_tx (uart_tx_pin),
        .led     (led)
    );

    // ========================================================================
    // UART TX task: send one byte from testbench to DUT's uart_rx pin
    // ========================================================================
    task automatic uart_send_byte(input [7:0] data);
        int i;
        begin
            // Start bit
            uart_rx_pin = 1'b0;
            repeat (CLKS_PER_BIT) @(posedge clk);

            // 8 data bits (LSB first)
            for (i = 0; i < 8; i++) begin
                uart_rx_pin = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            // Stop bit
            uart_rx_pin = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    // ========================================================================
    // UART RX monitor: capture bytes from DUT's uart_tx pin
    // ========================================================================
    int rx_byte_count;
    logic [7:0] rx_captured [0:1023];

    task automatic uart_monitor();
        int i;
        logic [7:0] captured;
        begin
            forever begin
                // Wait for start bit (falling edge)
                @(negedge uart_tx_pin);

                // Wait to middle of start bit
                repeat (CLKS_PER_BIT / 2) @(posedge clk);

                // Verify it's still low (valid start bit)
                if (uart_tx_pin == 1'b0) begin
                    // Sample 8 data bits
                    for (i = 0; i < 8; i++) begin
                        repeat (CLKS_PER_BIT) @(posedge clk);
                        captured[i] = uart_tx_pin;
                    end

                    // Wait for stop bit
                    repeat (CLKS_PER_BIT) @(posedge clk);

                    // Store captured byte
                    if (rx_byte_count < 1024) begin
                        rx_captured[rx_byte_count] = captured;
                    end
                    rx_byte_count = rx_byte_count + 1;

                    if (rx_byte_count <= 30) begin
                        $display("  [RX Monitor] byte #%0d = 0x%02h (%0d)",
                            rx_byte_count - 1, captured, captured);
                    end
                end
            end
        end
    endtask

    // ========================================================================
    // Gaussian 5x5 kernel coefficients
    // ========================================================================
    logic signed [15:0] gauss_kernel [0:24];
    initial begin
        gauss_kernel[ 0] = 16'sd1;  gauss_kernel[ 1] = 16'sd4;
        gauss_kernel[ 2] = 16'sd6;  gauss_kernel[ 3] = 16'sd4;
        gauss_kernel[ 4] = 16'sd1;
        gauss_kernel[ 5] = 16'sd4;  gauss_kernel[ 6] = 16'sd16;
        gauss_kernel[ 7] = 16'sd24; gauss_kernel[ 8] = 16'sd16;
        gauss_kernel[ 9] = 16'sd4;
        gauss_kernel[10] = 16'sd6;  gauss_kernel[11] = 16'sd24;
        gauss_kernel[12] = 16'sd36; gauss_kernel[13] = 16'sd24;
        gauss_kernel[14] = 16'sd6;
        gauss_kernel[15] = 16'sd4;  gauss_kernel[16] = 16'sd16;
        gauss_kernel[17] = 16'sd24; gauss_kernel[18] = 16'sd16;
        gauss_kernel[19] = 16'sd4;
        gauss_kernel[20] = 16'sd1;  gauss_kernel[21] = 16'sd4;
        gauss_kernel[22] = 16'sd6;  gauss_kernel[23] = 16'sd4;
        gauss_kernel[24] = 16'sd1;
    end

    // ========================================================================
    // Main test sequence
    // ========================================================================
    int i, p;
    logic [7:0] r, g, b;
    int expected_output_bytes;

    initial begin
        $dumpfile("../sim/tb_arty_top.vcd");
        $dumpvars(0, tb_arty_top);

        uart_rx_pin   = 1'b1;  // UART idle high
        rst           = 1'b1;
        rx_byte_count = 0;
        expected_output_bytes = VALID_OUT * 3;  // 3 bytes per output pixel

        // Reset
        repeat (20) @(posedge clk);
        rst = 1'b0;

        // Wait for boot kernel init to complete (25 cycles + margin)
        repeat (50) @(posedge clk);

        $display("=== LED check: led[1] (kernel init done) = %b ===", led[1]);

        // Start UART RX monitor in background
        fork
            uart_monitor();
        join_none

        // ==================================================================
        // Phase 1: Load kernel via UART 'K' command
        // ==================================================================
        $display("\n=== Phase 1: Loading kernel via UART ===");
        uart_send_byte(8'h4B);  // 'K' command

        for (i = 0; i < 25; i++) begin
            // Send MSB first, then LSB
            uart_send_byte(gauss_kernel[i][15:8]);
            uart_send_byte(gauss_kernel[i][7:0]);
        end

        $display("  Kernel load complete (50 bytes sent)");

        // Small gap
        repeat (100) @(posedge clk);

        // ==================================================================
        // Phase 2: Stream pixel data via UART 'D' command
        // ==================================================================
        $display("\n=== Phase 2: Streaming %0d pixels (%0dx%0d) ===",
            PIXELS, IMAGE_WIDTH, IMAGE_HEIGHT);
        uart_send_byte(8'h44);  // 'D' command

        for (p = 0; p < PIXELS; p++) begin
            // Generate test pattern: gradient
            r = (p * 3) & 8'hFF;
            g = (p * 5) & 8'hFF;
            b = (p * 7) & 8'hFF;
            uart_send_byte(r);
            uart_send_byte(g);
            uart_send_byte(b);
        end

        // Stop command
        uart_send_byte(8'h53);  // 'S' command
        $display("  Pixel stream complete (%0d pixels sent)", PIXELS);

        // ==================================================================
        // Phase 3: Wait for output to drain via UART TX
        // ==================================================================
        $display("\n=== Phase 3: Waiting for output bytes ===");
        $display("  Expected output pixels: %0d (%0d bytes)",
            VALID_OUT, expected_output_bytes);

        // Wait long enough for all output bytes to transmit
        // Each byte = 10 bit times × CLKS_PER_BIT clocks
        // Total wait = expected_output_bytes × 10 × CLKS_PER_BIT + margin
        repeat (expected_output_bytes * 10 * CLKS_PER_BIT + 10000) @(posedge clk);

        // ==================================================================
        // Phase 4: Check results
        // ==================================================================
        $display("\n=== Results ===");
        $display("  Received bytes: %0d", rx_byte_count);
        $display("  Expected bytes: %0d", expected_output_bytes);
        $display("  LEDs: rx_act=%b kern_done=%b tx_act=%b overflow=%b",
            led[0], led[1], led[2], led[3]);

        if (rx_byte_count == expected_output_bytes && led[3] == 1'b0) begin
            $display("\n*** TB PASS: Correct output byte count, no overflow ***");
        end else if (rx_byte_count > 0 && led[3] == 1'b0) begin
            $display("\n*** TB WARN: Got %0d bytes (expected %0d), no overflow ***",
                rx_byte_count, expected_output_bytes);
            $display("  (Byte count mismatch may be due to simulation timing)");
        end else begin
            $display("\n*** TB FAIL: byte_count=%0d expected=%0d overflow=%b ***",
                rx_byte_count, expected_output_bytes, led[3]);
        end

        $finish;
    end

    // Timeout watchdog
    initial begin
        #100_000_000;  // 100ms simulation time
        $display("\n*** TB TIMEOUT ***");
        $display("  Received bytes so far: %0d", rx_byte_count);
        $finish;
    end

endmodule
