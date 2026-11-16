module key_schedule (
    input  logic [63:0]  key,
    output logic [767:0] round_keys
);

    import des_pkg::*;

    logic [55:0] perm_choice_1_out;
    logic [55:0] shifted_key;
    logic [1:0] shift_amount;

    integer i;

    assign perm_choice_1_out = permutation_choice_1(key);

    always_comb begin

        shifted_key = perm_choice_1_out;
        round_keys  = '0;

        for (i = 0; i < 16; i = i + 1) begin

            // DES shift schedule
            case (i)
                0, 1, 8, 15: shift_amount = 2'd1;
                default:     shift_amount = 2'd2;
            endcase

            // Circular left shift
            shifted_key = circular_left_shift(
                shifted_key,
                shift_amount
            );

            // Generate round subkey
            round_keys[i*48 +: 48] = permutation_choice_2(shifted_key);

        end
    end

endmodule