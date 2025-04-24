module missing_semicolon (
    input logic clk,
    output logic q
)
    logic d = 1 // Missing semicolon

    always_ff @(posedge clk)
        q <= d;
endmodule