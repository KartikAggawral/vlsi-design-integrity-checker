module improper_reset (
    input logic clk,
    output reg data_out
);
    always_ff @(posedge clk)  // Missing reset
        data_out <= 1;

    reg wrong_name;  // Should be r_<name>
endmodule