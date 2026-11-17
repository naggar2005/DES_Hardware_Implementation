module tb_des_key_schedule();

    logic [63:0]  key;
    logic [767:0] round_keys;

    // DUT
    key_schedule dut (
        .key(key),
        .round_keys(round_keys)
    );

    initial begin

        // Initialize
        key = 64'h0;

        #5;
        key = 64'h133457799BBCDFF1;

        #5;

        // Check K1
        if (round_keys[47:0] === 48'h1B02EFFC7072)
            $display("[TB_DES_KEY_SCHEDULE] K1 PASSED");
        else
            $display("[TB_DES_KEY_SCHEDULE] K1 FAILED: %h",
                     round_keys[47:0]);

        // Check K16
        if (round_keys[767:720] === 48'hCB3D8B0E17F5)
            $display("[TB_DES_KEY_SCHEDULE] K16 PASSED");
        else
            $display("[TB_DES_KEY_SCHEDULE] K16 FAILED: %h",
                     round_keys[767:720]);

        // Display all round keys
        $display("\n========== ROUND KEYS ==========");

        for (int i = 0; i < 16; i++) begin
            $display("K%0d = %h",
                     i+1,
                     round_keys[i*48 +: 48]);
        end

        $display("================================");

        $finish;

    end

endmodule
