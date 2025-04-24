module latch_faulty(
    input logic clk,
    input logic enable,
    output logic q
);
    logic temp;

    always_latch begin
        if (enable)
            temp = clk;  // Latch inferred
    end

    always_comb
        q = temp;  // No begin-end block, creating a potential combinational loop

endmodule