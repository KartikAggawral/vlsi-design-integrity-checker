module multi_clock (
    input logic clk_a,
    input logic clk_b,
    input logic rst,
    output logic q
);
    always_ff @(posedge clk_a or posedge clk_b) begin
        q <= 1; // Multiple clocks in sensitivity list!
    end
endmodule