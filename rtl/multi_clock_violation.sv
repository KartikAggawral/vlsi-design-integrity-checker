module multi_clock_violation (
    input logic clk1,
    input logic clk2,
    input logic rst,
    output logic q
);
    always_ff @(posedge clk1, posedge clk2) begin
        q <= 1; // Multiple clocks in sensitivity list!
    end
endmodule
