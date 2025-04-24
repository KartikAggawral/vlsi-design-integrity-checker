module safe_cdc (
    input logic clk1,
    input logic clk2,
    input logic rst,
    input logic data_in,
    output logic data_out
);
    logic stage1, stage2;

    always_ff @(posedge clk1) begin
        stage1 <= data_in;
    end

    always_ff @(posedge clk2) begin
        stage2 <= stage1; // Proper double synchronization
        data_out <= stage2;
    end
endmodule