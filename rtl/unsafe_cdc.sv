module unsafe_cdc (
    input logic clk1,
    input logic clk2,
    input logic rst,
    input logic data_in,
    output logic data_out
);
    logic stage1;

    always_ff @(posedge clk1) begin
        stage1 <= data_in;
    end

    always_ff @(posedge clk2) begin
        data_out <= stage1; // No synchronization → CDC issue!
    end
endmodule