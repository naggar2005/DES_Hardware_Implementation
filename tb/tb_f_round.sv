module tb_f_round();

/*
    small test for fiestel round
    plain text: 0123456789ABCDEF
    sub-Key: 1B02EFFC7072
    expected output: 89ABCDEFAFAAF76A

*/

logic clk;
logic [63:0] in;
logic [47:0] subkey;
logic [63:0] f_out;

f_round small_dut(in , subkey , f_out);

initial begin
    clk = 0;
    in  = 0;
    subkey = 0;
    forever
        #2 clk = ~clk;
end

initial begin
    @(negedge clk);
    in      = 64'h0123456789ABCDEF;
    subkey  = 48'h1B02EFFC7072;

    @(posedge clk);
    if (f_out == 64'h89ABCDEFAFAAF76A)
        $display("[TB_Fiestel_Round] , Test passed succesfully");
    
    else begin
        $display("[TB_Feistel_Round] Test FAILED!");
        $display("Expected = %h", 64'h89ABCDEFAFAAF76A);
        $display("Actual   = %h", f_out);
    end

    $finish;
end

endmodule
