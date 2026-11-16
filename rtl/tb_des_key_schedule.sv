
module tb_des_key_schedule();

    logic [63:0]  key;
    logic [767:0] round_keys;

    // DUT
    des_key_schedule dut (
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
/*
Round

Expected key

K1

1B02EFFC7072

K2

79AED9DBC9E5

K3

55FC8A42CF99

K4

72ADD6DB351D

K5

7CEC07EB53A8

K6

63A53E507B2F

K7

EC84B7F618BC

K8

F78A3AC13BFB

K9

E0DBEBEDE781

K10

B1F347BA464F

K11

215FD3DED386

K12

7571F59467E9

K13

97C5D1FABA41

K14

5F43B7F2E73A

K15

BF918D3D3F0A

K16

CB3D8B0E17F5
*/