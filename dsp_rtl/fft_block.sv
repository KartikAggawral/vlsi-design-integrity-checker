module fft_block(
    input logic clk,
    input logic rst_n,
    input logic signed [15:0] in_real,
    input logic signed [15:0] in_imag,
    input logic clk_fast, // Another clock domain
    output logic signed [15:0] out_real,
    output logic signed [15:0] out_imag
);
    // No clock domain synchronization - metastability risk
    logic signed [15:0] temp_real, temp_imag;

    always_ff @(posedge clk_fast) begin // Should have synchronizers between domains
        temp_real <= in_real >> 1; 
        temp_imag <= in_imag >> 1;
    end

    always_ff @(posedge clk) begin
        out_real <= temp_real;  // Potential metastability issue
        out_imag <= temp_imag;
    end
endmodule