module signal_faulty(
    input logic clk,
    input logic rst_n,
    input logic [3:0] data_in,  // Width < 8
    output logic [2:0] result   // Width < 8
);
    assign result = data_in[3:1];  // Potential truncation error
endmodule
