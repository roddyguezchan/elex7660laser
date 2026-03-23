module bin_to_bcd (
    input  logic [11:0] binary,
    output logic [3:0]  thousands,
    output logic [3:0]  hundreds,
    output logic [3:0]  tens,
    output logic [3:0]  ones
);

    integer i;
    logic [27:0] shift_reg; // 12 bits (binary) + 16 bits (BCD)

    always_comb begin
        shift_reg = {16'b0, binary};

        for (i = 0; i < 12; i = i + 1) begin
            // Check each BCD nibble and add 3 if >= 5
            if (shift_reg[15:12] >= 5) shift_reg[15:12] = shift_reg[15:12] + 3;
            if (shift_reg[19:16] >= 5) shift_reg[19:16] = shift_reg[19:16] + 3;
            if (shift_reg[23:20] >= 5) shift_reg[23:20] = shift_reg[23:20] + 3;
            if (shift_reg[27:24] >= 5) shift_reg[27:24] = shift_reg[27:24] + 3;

            // Shift entire register left by 1
            shift_reg = shift_reg << 1;
        end

        // Assign outputs from the BCD parts of the shift register
        ones      = shift_reg[15:12];
        tens      = shift_reg[19:16];
        hundreds  = shift_reg[23:20];
        thousands = shift_reg[27:24];
    end

endmodule