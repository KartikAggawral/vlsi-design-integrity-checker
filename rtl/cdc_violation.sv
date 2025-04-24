module cdc_violation (
    input logic clk_A,
    input logic clk_B,
    input logic rst,
    input logic data_in,
    output logic data_out
);
    logic stage1;

    always_ff @(posedge clk_A) begin
        stage1 <= data_in;
    end

    always_ff @(posedge clk_B) begin
        data_out <= stage1; // No synchronization → CDC issue!
    end
endmodule