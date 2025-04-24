module latch_example (
    input logic clk, en,
    output logic q
);
    logic d;

    always_ff @(posedge clk)
        if (en) 
            q <= d;  // Latch inferred when 'en' is low

    assign d = d; // Combinational loop detected
endmodule