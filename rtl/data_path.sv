module data_path(
    input logic clk, 
    input logic arstn,

    input  logic [63:0] data_in,
    input  logic [63:0] key,
    input  logic        mode,

    // Controller commands
    input  logic        load,
    input  logic        round_en,
    input  logic        finalize,
    input  logic [3:0]  round_index,

    output logic [63:0] data_out
);

    import des_pkg::*;

    logic [767:0] gen_keys;
    logic [63 :0] key_in;
    
    key_schedule key_generation( key_in, gen_keys);

    logic [63:0] round_in;
    logic [47:0] sub_key;
    logic [63:0] round_out;
    f_round round(round_in , sub_key , round_out);

    logic mode_in;
    

    // Select round key
    always_comb begin
    if (mode_in == 1'b0)    //Encryption
        sub_key = gen_keys[round_index*48 +: 48];
    else                    //Decryption
        sub_key = gen_keys[767 - round_index*48 -: 48];
    end

    always_ff @(posedge clk or negedge arstn) begin
        if(!arstn) begin
            data_out <= '0;
            round_in <= '0;
            key_in   <= '0;
            mode_in  <= '0; //default: encryption
        end
        else begin
            if(load)
                begin
                    round_in <= initial_permutation(data_in) ;
                    key_in   <= key     ;
                    mode_in  <= mode    ;
                end
            
            else if(round_en)
                begin
                    //apply round according to mode and round index
                    round_in <= round_out;
                end
            
            else if(finalize)
                begin
                    data_out <= final_permutation(swap(round_in));
                end
        end
    end


endmodule




/*
    Datapath responsibilities:
        1) Apply Initial Permutation (IP).
        2) Store and update 64-bit Feistel state.
        3) Select the correct round key for encryption or decryption.
        4) Connect the existing f_round module
        5) Execute 16 rounds under controller control
        6) Apply the final swap {R16,L16}
        7) Apply Final Permutation (FP).
    
    Key Index:
        Encryption: R0;K0  , R1;K1  , ..... , R15;K15   mode=0 => key_index = round_index
        Decription: R0;K15 , R1;K14 , ..... , R15;K0    mode=1 => Key_index = 15 - round_index

*/