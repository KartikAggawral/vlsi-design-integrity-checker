module iir_filter(
    input logic clk,
    input logic rst_n,
    input logic signed [15:0] in_data,
    output logic signed [15:0] out_data
);
    logic signed [15:0] feedback;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            feedback <= 16'h0000;
        else
            feedback <= (in_data >>> 2) + (feedback >>> 1); // Incorrect arithmetic shift
    end
    
    assign out_data = in_data + feedback * 2; // Hardcoded gain factor
endmodule