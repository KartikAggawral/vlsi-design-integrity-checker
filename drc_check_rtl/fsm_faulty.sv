module fsm_faulty(
    input logic clk,
    input logic rst_n,
    input logic start,
    output logic done
);
    typedef enum logic [1:0] {IDLE = 2'b00, LOAD = 2'b10, PROCESS = 2'b11} state_t;
    state_t current_state, next_state; // Non-One-Hot, Non-Gray encoding

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always_comb begin
        case (current_state)
            IDLE: next_state = start ? LOAD : IDLE;
            LOAD: next_state = PROCESS;
            PROCESS: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    assign done = (current_state == PROCESS);
endmodule
