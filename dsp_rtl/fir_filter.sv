// FIR Filter with multiple integrity issues
module fir_filter #(parameter TAPS = 4)(
    input logic clk,
    input logic rst_n,
    input logic signed [15:0] in_data,
    output logic signed [15:0] out_data
);
    // Missing import of dsp_pkg (should contain data structures & coefficients)
    
    logic signed [15:0] coeffs [TAPS] = '{1, 2, 3, 4}; // Hardcoded values (should be parameters)
    logic signed [15:0] shift_reg [TAPS]; // Unused register (possible waste of area)
    
    integer i;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) shift_reg[i] <= 0; // Redundant reset
        end else begin
            shift_reg[0] <= in_data;
            for (i = 1; i < TAPS; i = i + 1) shift_reg[i] <= shift_reg[i-1];
        end
    end
    
    // Incorrect use of TAPS (indexing could go out of bounds)
    assign out_data = shift_reg[0] * coeffs[0] + shift_reg[1] * coeffs[1] + shift_reg[2] * coeffs[2] + shift_reg[3] * coeffs[3]; 
endmodule