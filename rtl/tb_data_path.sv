module tb_data_path();

    logic clk;
    logic arstn;

    logic [63:0] data_in;
    logic [63:0] key;
    logic mode;

    logic load , round_en , finalize;
    logic [3:0] round_index;

    logic [63:0] data_out;

    /*
        Plaintext       : 64'h0123456789ABCDEF
        Key             : 64'h133457799BBCDFF1
        Mode            : 0(Encryption)
        Expected output : 64'h85E813540F0AB405
    */


    data_path DUT(
        .clk(clk),
        .arstn(arstn),
        .data_in(data_in),
        .key(key),
        .mode(mode),
        .load(load),
        .round_en(round_en),
        .finalize(finalize),
        .round_index(round_index),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever
            #2 clk = ~clk;
    end

    integer i;
    initial begin
        // Initialize inputs
        arstn      = 1'b0;
        data_in    = '0;
        key        = '0;
        mode       = 1'b0;
        load       = 1'b0;
        round_en   = 1'b0;
        finalize   = 1'b0;
        round_index = 4'd0;

        // Reset
        repeat(2) @(negedge clk);
        arstn = 1'b1;

        // Load data and key
        @(negedge clk);
        data_in = 64'h0123456789ABCDEF;
        key     = 64'h133457799BBCDFF1;
        mode    = 1'b0;
        
        load = 1'b1;

        @(negedge clk);
        load = 1'b0;
        round_en = 1'b1;
        for(i = 0; i < 16; i++) begin
            round_index = i;
            @(negedge clk);
        end
        
        round_en = 1'b0;
        round_index = 'b0;
        finalize = 1'b1;
        @(negedge clk);
        finalize = 1'b0;

        @(negedge clk);
        if(data_out === 64'h85E813540F0AB405)
            $display("[tb_data_path] , test passed succesfully");
        else
            $display("[tb_data_path] , test failed data_out = %h",data_out);

        $finish;
    end
endmodule