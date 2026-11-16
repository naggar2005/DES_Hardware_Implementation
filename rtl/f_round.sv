module f_round (                        //fiestel round
    input  logic [63:0] in,
    input  logic [47:0] subkey,
    output logic [63:0] f_out
);



    import des_pkg::*;
    
    logic [31:0] left_in;
    logic [31:0] right_in;

    logic [31:0] left_out;  
    logic [31:0] right_out;
    logic [47:0] exp_out;
    logic [47:0] first_xor_out;
    logic [31:0] sbox_out;
    logic [31:0] perm_out;
    logic [31:0] second_xor_out;

    //splitting output to right and left input
    assign left_in = in[63:32];
    assign right_in   = in[31:0];
    
    // Feistel round
    assign left_out = right_in;

    assign exp_out = expansion(right_in);

    assign first_xor_out = exp_out ^ subkey;

    assign sbox_out = sbox(first_xor_out);

    assign perm_out = permutation(sbox_out);

    assign second_xor_out = perm_out ^ left_in;

    assign right_out = second_xor_out;

    assign f_out = {left_out , right_out};

endmodule

