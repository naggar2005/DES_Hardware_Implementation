module tb_controller();
    logic clk , arstn;
    logic start;

    logic load , round_en , finalize;
    logic [3:0] round_index;

    logic busy , done;

    /*
        TB must verify this:
        1)Reset enters IDLE.
        2)A start pulse causes LOAD.
        3)LOAD lasts exactly one cycle.
        4)ROUND executes exactly 16 cycles.
        5)round_index follows 0 through 15.
        6)FINAL lasts exactly one cycle.
        7)DONE lasts exactly one cycle
        8)busy is asserted during LOAD, ROUND, and FINAL.
        9)A new transaction can start after returning to IDLE.

    */ 
    controller DUT (
        .clk(clk),
        .arstn(arstn),
        .start(start),
        .load(load),
        .round_en(round_en),
        .finalize(finalize),
        .round_index(round_index),
        .busy(busy),
        .done(done)
    );


     initial begin
        clk = 0;
        forever 
            #5 clk = ~clk;
    end

    //Checker
    task automatic check_outputs(
        input string phase,
        input logic exp_load,
        input logic exp_round_en,
        input logic exp_finalize,
        input logic [3:0] exp_index,
        input logic exp_busy,
        input logic exp_done
    );

        begin

            if ({load, round_en, finalize, round_index, busy, done} 
                !==
                {exp_load, exp_round_en, exp_finalize, exp_index, exp_busy, exp_done}) 
                begin

                    $display("ERROR in phase: %s", phase);

                    $display("Expected: load=%b round_en=%b finalize=%b index=%d busy=%b done=%b",
                        exp_load, exp_round_en, exp_finalize,
                        exp_index, exp_busy, exp_done);

                    $display("Actual  : load=%b round_en=%b finalize=%b index=%d busy=%b done=%b",
                        load, round_en, finalize,
                        round_index, busy, done);

                    $fatal(1, "TEST FAILED");

                end

            else begin
                $display("[PASS] %s", phase);
            end

        end

    endtask


    integer i;
    // Drive Transaction
    task automatic run_transaction();

        begin

            $display("******Starting Transaction******");
            $display("******Starting Transaction******");

            // Send start pulse
            @(negedge clk);
            start = 1'b1;

            // LOAD state
            @(posedge clk);
            #1;

            check_outputs(
                "LOAD",
                1'b1, 1'b0, 1'b0,
                4'd0, 1'b1, 1'b0
            );

            // Remove start pulse
            @(negedge clk);
            start = 1'b0;

            // Enter ROUND state
            @(posedge clk);
            #1;

            // Check all 16 rounds
            for (i = 0; i < 16; i = i + 1) begin

                check_outputs(
                    $sformatf("ROUND %0d", i),
                    1'b0, 1'b1, 1'b0,
                    i, 1'b1, 1'b0
                );

                @(posedge clk);
                #1;

            end

            // FINAL state
            check_outputs(
                "FINAL",
                1'b0, 1'b0, 1'b1,
                4'd0, 1'b1, 1'b0
            );

            // DONE state
            @(posedge clk);
            #1;

            check_outputs(
                "DONE",
                1'b0, 1'b0, 1'b0,
                4'd0, 1'b0, 1'b1
            );

            // Return to IDLE
            @(posedge clk);
            #1;

            check_outputs(
                "IDLE",
                1'b0, 1'b0, 1'b0,
                4'd0, 1'b0, 1'b0
            );

            $display("******Transaction Passed******");
            $display("******Transaction Passed******");

        end

    endtask


    initial begin

        // Initialize inputs
        arstn = 1'b0;
        start = 1'b0;

        // apply Reset
        repeat(2) @(posedge clk);
        #1;
        //check reset functionality
        check_outputs(
            "RESET / IDLE",
            1'b0, 1'b0, 1'b0,
            4'd0, 1'b0, 1'b0
        );

        @(negedge clk);
        arstn = 1'b1;

        run_transaction();
        run_transaction();

        $display("*********Finish*********");

        $finish;

    end

endmodule
