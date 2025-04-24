module missing_default_case (
    input logic [1:0] sel,
    output logic y
);
    always_comb begin
        case (sel)
            2'b00: y = 1;
            2'b01: y = 0;
            2'b10: y = 1;
            // Missing default case
        endcase
    end
endmodule