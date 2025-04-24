module d_flip_flop (
    input wire clk,    // Clock input
    input wire d,      // Data input
    output reg q       // Output
);

    always @(posedge clk) begin
        q <= d;
    end

endmodule
