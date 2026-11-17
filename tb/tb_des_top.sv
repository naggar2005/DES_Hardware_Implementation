`timescale 1ns / 1ps

module tb_des_top();

    // Clock and Reset
    logic clk;
    logic arstn;

    // DUT Control and Data Interface
    logic        start;
    logic        mode;
    logic [63:0] key;
    logic [63:0] data_in;
    logic [63:0] data_out;
    logic        busy;
    logic        done;

    // File Descriptors
    int pt_file;
    int key_file;
    int exp_file;
    int out_file;
    int dec_file;

    // Storage Queues for Test Vectors
    logic [63:0] plaintext_q[$];
    logic [63:0] key_q[$];
    logic [63:0] expected_q[$];
    logic [63:0] ciphertext_q[$];
    logic [63:0] decrypted_q[$];

    // Verification Statistics
    int enc_pass_count = 0;
    int enc_fail_count = 0;
    int dec_pass_count = 0;
    int dec_fail_count = 0;
    int num_vectors    = 0;

    // DUT Instantiation
    des_top DUT (
        .clk(clk),
        .arstn(arstn),
        .start(start),
        .mode(mode),
        .key(key),
        .data_in(data_in),
        .data_out(data_out),
        .busy(busy),
        .done(done)
    );

    // 100 MHz Clock Generator (Period = 10ns)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Helper function: Search and open an input file with fallback paths
    function automatic int open_input_file(input string filename);
        int fd;
        string path;

        // 1. Try exact path / current directory
        fd = $fopen(filename, "r");
        if (fd != 0) begin
            $display("[TB] Found %s in current directory.", filename);
            return fd;
        end

        // 2. Try tb/vectors/ (running from project root)
        path = {"tb/vectors/", filename};
        fd = $fopen(path, "r");
        if (fd != 0) begin
            $display("[TB] Found %s at: %s", filename, path);
            return fd;
        end

        // 3. Try ../tb/vectors/ (running from sim/ or questa/)
        path = {"../tb/vectors/", filename};
        fd = $fopen(path, "r");
        if (fd != 0) begin
            $display("[TB] Found %s at: %s", filename, path);
            return fd;
        end

        // 4. Try ../../tb/vectors/ (running from subdirectories)
        path = {"../../tb/vectors/", filename};
        fd = $fopen(path, "r");
        if (fd != 0) begin
            $display("[TB] Found %s at: %s", filename, path);
            return fd;
        end

        // 5. Try parent directory
        path = {"../", filename};
        fd = $fopen(path, "r");
        if (fd != 0) begin
            $display("[TB] Found %s at: %s", filename, path);
            return fd;
        end

        // 6. Try absolute path
        path = {"E:/DES_Hardware_Implementation/tb/vectors/", filename};
        fd = $fopen(path, "r");
        if (fd != 0) begin
            $display("[TB] Found %s at: %s", filename, path);
            return fd;
        end

        return 0;
    endfunction

    // Helper function: Open an output file for writing
    function automatic int open_output_file(input string filename);
        int fd;
        string path;

        // 1. Current directory
        fd = $fopen(filename, "w");
        if (fd != 0) begin
            $display("[TB] Writing %s to current directory.", filename);
            return fd;
        end

        // 2. sim/ directory
        path = {"sim/", filename};
        fd = $fopen(path, "w");
        if (fd != 0) begin
            $display("[TB] Writing %s to: %s", filename, path);
            return fd;
        end

        // 3. ../sim/ directory
        path = {"../sim/", filename};
        fd = $fopen(path, "w");
        if (fd != 0) begin
            $display("[TB] Writing %s to: %s", filename, path);
            return fd;
        end

        // 4. Project root
        path = {"E:/DES_Hardware_Implementation/", filename};
        fd = $fopen(path, "w");
        if (fd != 0) return fd;

        return 0;
    endfunction

    // Task: Reset the DUT
    task automatic reset_dut();
        begin
            arstn   = 1'b0;
            start   = 1'b0;
            mode    = 1'b0;
            key     = 64'd0;
            data_in = 64'd0;
            repeat (3) @(negedge clk);
            arstn   = 1'b1;
            @(negedge clk);
        end
    endtask

    // Task: Execute a single DES Encryption or Decryption operation
    task automatic run_des_operation(
        input  logic        op_mode,
        input  logic [63:0] op_key,
        input  logic [63:0] op_data_in,
        output logic [63:0] op_data_out
    );
        begin
            // Ensure DUT is not busy
            while (busy) @(negedge clk);

            // Apply inputs and start pulse at negedge
            mode    = op_mode;
            key     = op_key;
            data_in = op_data_in;
            start   = 1'b1;

            // Wait 1 cycle for controller to enter LOAD state
            @(posedge clk);
            @(negedge clk);
            start   = 1'b0; // Deassert start

            // Wait for completion (done asserted in DONE state)
            while (!done) @(posedge clk);

            // Capture output during DONE state
            op_data_out = data_out;

            // Wait for controller to return to IDLE
            @(posedge clk);
        end
    endtask

    // Main Test Sequence
    initial begin
        string line;
        logic [63:0] parsed_val;
        int scan_status;
        logic [63:0] out_val;

        $display("\n================================================================================");
        $display("                   DES TOP-LEVEL HARDWARE VERIFICATION");
        $display("================================================================================");

        // 1. Open Input Files
        pt_file  = open_input_file("plaintext.txt");
        key_file = open_input_file("key.txt");
        exp_file = open_input_file("expected_output.txt");

        if (pt_file == 0)  $fatal(1, "[FATAL] Failed to open plaintext.txt!");
        if (key_file == 0) $fatal(1, "[FATAL] Failed to open key.txt!");
        if (exp_file == 0) $display("[WARN] expected_output.txt not found. Output validation will be skipped.");

        // 2. Open Output Files
        out_file = open_output_file("output.txt");
        dec_file = open_output_file("decrypted_output.txt");

        if (out_file == 0) $fatal(1, "[FATAL] Failed to create output.txt!");
        if (dec_file == 0) $display("[WARN] Could not create decrypted_output.txt");

        // 3. Read Plaintext vectors
        while ($fgets(line, pt_file)) begin
            scan_status = $sscanf(line, "%h", parsed_val);
            if (scan_status == 1) begin
                plaintext_q.push_back(parsed_val);
            end
        end
        $fclose(pt_file);

        // 4. Read Key vectors
        while ($fgets(line, key_file)) begin
            scan_status = $sscanf(line, "%h", parsed_val);
            if (scan_status == 1) begin
                key_q.push_back(parsed_val);
            end
        end
        $fclose(key_file);

        // 5. Read Expected Output vectors (if file exists)
        if (exp_file != 0) begin
            while ($fgets(line, exp_file)) begin
                scan_status = $sscanf(line, "%h", parsed_val);
                if (scan_status == 1) begin
                    expected_q.push_back(parsed_val);
                end
            end
            $fclose(exp_file);
        end

        // Check vector count
        num_vectors = plaintext_q.size();
        if (num_vectors == 0 || key_q.size() == 0) begin
            $fatal(1, "[FATAL] No valid test vectors found in input files!");
        end
        if (key_q.size() < num_vectors) begin
            num_vectors = key_q.size();
        end

        $display("[TB] Loaded %0d test vector(s) successfully.\n", num_vectors);

        // 6. Apply Reset
        reset_dut();

        // -------------------------------------------------------------------------
        // PHASE 1: ENCRYPTION (mode = 0)
        // -------------------------------------------------------------------------
        $display("--------------------------------------------------------------------------------");
        $display(" [PHASE 1] ENCRYPTION TESTS (Plaintext + Key -> Ciphertext)");
        $display("--------------------------------------------------------------------------------");

        for (int i = 0; i < num_vectors; i++) begin
            run_des_operation(
                .op_mode(1'b0), // Encryption
                .op_key(key_q[i]),
                .op_data_in(plaintext_q[i]),
                .op_data_out(out_val)
            );

            ciphertext_q.push_back(out_val);

            // Write ciphertext hex to output.txt
            $fdisplay(out_file, "%016H", out_val);

            // Validate against expected output if available
            if (i < expected_q.size()) begin
                if (out_val === expected_q[i]) begin
                    $display("  Vector %0d [PASS] | KEY: %016H | PT: %016H | CT: %016H",
                             i, key_q[i], plaintext_q[i], out_val);
                    enc_pass_count++;
                end else begin
                    $display("  Vector %0d [FAIL] | KEY: %016H | PT: %016H", i, key_q[i], plaintext_q[i]);
                    $display("            Expected : %016H", expected_q[i]);
                    $display("            Actual   : %016H", out_val);
                    enc_fail_count++;
                end
            end else begin
                $display("  Vector %0d [DONE] | KEY: %016H | PT: %016H | CT: %016H",
                         i, key_q[i], plaintext_q[i], out_val);
                enc_pass_count++;
            end
        end

        $fclose(out_file);
        $display("[TB] Encryption ciphertexts written to output.txt\n");

        // -------------------------------------------------------------------------
        // PHASE 2: DECRYPTION & REVERSIBILITY (mode = 1)
        // -------------------------------------------------------------------------
        $display("--------------------------------------------------------------------------------");
        $display(" [PHASE 2] DECRYPTION & REVERSIBILITY (Ciphertext + Key -> Decrypted Text)");
        $display("--------------------------------------------------------------------------------");

        for (int i = 0; i < num_vectors; i++) begin
            run_des_operation(
                .op_mode(1'b1), // Decryption
                .op_key(key_q[i]),
                .op_data_in(ciphertext_q[i]),
                .op_data_out(out_val)
            );

            decrypted_q.push_back(out_val);

            // Write decrypted plaintext hex to decrypted_output.txt if open
            if (dec_file != 0) begin
                $fdisplay(dec_file, "%016H", out_val);
            end

            // Compare decrypted output with original plaintext
            if (out_val === plaintext_q[i]) begin
                $display("  Vector %0d [PASS] | KEY: %016H | CT: %016H | Decrypted: %016H",
                         i, key_q[i], ciphertext_q[i], out_val);
                dec_pass_count++;
            end else begin
                $display("  Vector %0d [FAIL] | KEY: %016H | CT: %016H", i, key_q[i], ciphertext_q[i]);
                $display("            Expected Original PT: %016H", plaintext_q[i]);
                $display("            Actual Decrypted    : %016H", out_val);
                dec_fail_count++;
            end
        end

        if (dec_file != 0) $fclose(dec_file);
        $display("[TB] Decrypted outputs written to decrypted_output.txt\n");

        // -------------------------------------------------------------------------
        // FINAL SUMMARY REPORT
        // -------------------------------------------------------------------------
        $display("================================================================================");
        $display("                              VERIFICATION SUMMARY");
        $display("================================================================================");
        $display("  Total Test Vectors Processed : %0d", num_vectors);
        $display("  Encryption Passed            : %0d / %0d", enc_pass_count, num_vectors);
        $display("  Encryption Failed            : %0d / %0d", enc_fail_count, num_vectors);
        $display("  Decryption Passed            : %0d / %0d", dec_pass_count, num_vectors);
        $display("  Decryption Failed            : %0d / %0d", dec_fail_count, num_vectors);
        $display("--------------------------------------------------------------------------------");

        if (enc_fail_count == 0 && dec_fail_count == 0) begin
            $display("  >>> OVERALL RESULT: ALL TESTS PASSED SUCCESSFULLY! <<<");
        end else begin
            $display("  >>> OVERALL RESULT: %0d TEST FAILURE(S) DETECTED! <<<",
                     (enc_fail_count + dec_fail_count));
        end
        $display("================================================================================\n");

        $finish;
    end

endmodule
