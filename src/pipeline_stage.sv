`timescale 1ns/1ps

module pipeline_stage #(
    parameter int DATA_W = 24,
    parameter int STAGES = 1
) (
    input  logic              clk,
    input  logic              rst,
    input  logic              valid_in,
    input  logic [DATA_W-1:0] data_in,
    output logic              valid_out,
    output logic [DATA_W-1:0] data_out
);
    logic [DATA_W-1:0] data_pipe [0:STAGES-1];
    logic              valid_pipe[0:STAGES-1];
    int i;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < STAGES; i++) begin
                data_pipe[i]  <= '0;
                valid_pipe[i] <= 1'b0;
            end
        end else begin
            data_pipe[0]  <= data_in;
            valid_pipe[0] <= valid_in;
            for (i = 1; i < STAGES; i++) begin
                data_pipe[i]  <= data_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end
        end
    end

    assign data_out  = data_pipe[STAGES-1];
    assign valid_out = valid_pipe[STAGES-1];
endmodule
