module counter (
    input wire clk,     // Clock input
    input wire reset,   // Reset input
    output reg [1:0] count  // 2-bit counter output
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 2'b00;  // Reset to 0
        else
            count <= count + 1;  // Increment counter
    end

endmodule
