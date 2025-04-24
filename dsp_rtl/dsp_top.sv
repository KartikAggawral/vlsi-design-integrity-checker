// Top-level module integrating FIR filter (Fixed Version)
module dsp_top(
    input logic clk,
    input logic rst_n,
    input logic signed [15:0] input_signal,
    output logic signed [15:0] filtered_signal
);
    import dsp_pkg::*; // Fixed typo in package name
    
    fir_filter #(.TAPS(4)) fir_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(input_signal), // Fixed missing input connection
        .out_data(filtered_signal)
    );
endmodule
