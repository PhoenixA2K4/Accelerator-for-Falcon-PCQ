/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : tb_falcon_samplerZ.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: tb_falcon_samplerZ
 *    Create Date : Sep 1st 2026
 *    Last Update : Sep 1st 2026
 *    Description : Testbench for samplerZ
 ******************************************************************************
  History:

 ******************************************************************************/

`timescale 1ns/1ps
`include "falcon_header.svh"

module tb_falcon_samplerZ;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic rst_n, start;
    logic [`FPU_STAND-1:0] o_dot, mu;
    logic [`FALCON_UNIFORM_BITS_BASE_SAMPLER-1:0] unif_base;
    logic [`FALCON_UNIFORM_BITS_SAMPLERZ-1:0] unif_samp;
    logic [`FALCON_UNIFORM_BITS_BER_EXP-1:0] unif_ber;
    logic unif_req, unif_req_ber, valid_o;
    logic signed [`FALCON_Z-1:0] z_o;

    int test_count = 0, pass_count = 0, fail_count = 0;
    byte unsigned rand_mem [0:255];
    int rand_ptr = 0, total_bytes = 0;
    int sample_requests = 0, ber_requests = 0;
    bit stream_error = 0;

    falcon_samplerZ dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .unif_base(unif_base), .unif_samp(unif_samp), .unif_ber(unif_ber),
        .o_dot(o_dot), .mu(mu),
        .unif_req(unif_req), .unif_req_ber(unif_req_ber),
        .valid_o(valid_o), .z_o(z_o)
    );

    // PRNG model: request sampled at posedge N; new random data is
    // registered with nonblocking assignments at that edge and is
    // available for DUT sampling at posedge N+1.
    // unif_req supplies ONLY unif_base (9 bytes) and unif_samp (1 byte).
    // unif_req_ber supplies ONLY unif_ber (1 byte per request).
    // One sampler request consumes 10 bytes (9 BaseSampler + 1 b).
    // One BerExp request consumes 1 byte; repeated BerExp requests consume
    // consecutive bytes, including Test 9's second BerExp byte.
    always @(posedge clk) begin : prng_model
        int next_ptr;
        if (!rst_n) begin
            unif_base <= '0;
            unif_samp <= '0;
            unif_ber  <= '0;
        end else begin
            next_ptr = rand_ptr;
            if (unif_req === 1'b1) begin
                sample_requests++;
                if (next_ptr + 10 > total_bytes) begin
                    $error("Sampler request exceeds random stream: ptr=%0d total=%0d", next_ptr, total_bytes);
                    stream_error = 1;
                end else begin
                    for (int k=0; k<9; k++)
                        unif_base[(8-k)*8 +: 8] <= rand_mem[next_ptr+k];
                    unif_samp <= rand_mem[next_ptr+9];
                    $display("  [PRNG] sampler req #%0d, bytes [%0d..%0d]", sample_requests, next_ptr, next_ptr+9);
                    next_ptr += 10;
                end
            end
            if (unif_req_ber === 1'b1) begin
                ber_requests++;
                if (next_ptr >= total_bytes) begin
                    $error("BerExp request exceeds random stream: ptr=%0d total=%0d", next_ptr, total_bytes);
                    stream_error = 1;
                end else begin
                    unif_ber <= rand_mem[next_ptr];
                    $display("  [PRNG] BerExp req #%0d, byte [%0d] = %02h", ber_requests, next_ptr, rand_mem[next_ptr]);
                    next_ptr++;
                end
            end
            rand_ptr = next_ptr;
        end
    end

    task automatic run_kat(
        input string test_id,
        input logic [63:0] in_mu_fp64,
        input logic [63:0] in_sigma_fp64,
        input byte unsigned stream[],
        input int expected_z
    );
        int timeout;
        bit got_result;
        test_count++;
        @(negedge clk);
        rand_ptr = 0;
        total_bytes = stream.size();
        sample_requests = 0;
        ber_requests = 0;
        stream_error = 0;
        for (int i=0; i<stream.size(); i++) rand_mem[i] = stream[i];
        mu = in_mu_fp64;
        o_dot = in_sigma_fp64;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        timeout = 0;
        got_result = 0;
        while (timeout < 50000 && !stream_error && !got_result) begin
            @(negedge clk);
            timeout++;
            if (valid_o === 1'b1) got_result = 1;
        end
        if (!got_result) begin
            $display("[FAIL] %s TIMEOUT/stream error, sampler_req=%0d ber_req=%0d ptr=%0d/%0d",
                     test_id, sample_requests, ber_requests, rand_ptr, total_bytes);
            fail_count++;
        end else if ($signed(z_o) === expected_z && rand_ptr == total_bytes) begin
            $display("[PASS] %s z=%0d, sampler_req=%0d ber_req=%0d, bytes=%0d",
                     test_id, $signed(z_o), sample_requests, ber_requests, rand_ptr);
            pass_count++;
        end else begin
            $display("[FAIL] %s z=%0d expected=%0d, sampler_req=%0d ber_req=%0d, bytes=%0d/%0d",
                     test_id, $signed(z_o), expected_z, sample_requests, ber_requests, rand_ptr, total_bytes);
            fail_count++;
        end
        repeat (5) @(negedge clk);
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        mu    = '0;
        o_dot = '0;

        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);

        $display("=================================================");
        $display("   VERIFY DU 16 TEST VECTOR FALCON SAMPLERZ      ");
        $display("=================================================");

        // Test 1: mu = -91.90471153063714 | sigma' = 1.7037990414754918 (2 iterations)
        run_kat("Test 1", 64'hC056F9E6CB3119A4, 64'h3FFB42C2C8A17E81,
            '{8'h0f, 8'hc5, 8'h44, 8'h2f, 8'hf0, 8'h43, 8'hd6, 8'h6e, 8'h91, 8'hd1, 8'hea,
              8'hca, 8'hc6, 8'h4e, 8'ha5, 8'h45, 8'h0a, 8'h22, 8'h94, 8'h1e, 8'hdc, 8'h6c},
            -92
        );

        // Test 2: mu = -8.322564895434937 | sigma' = 1.7037990414754918 (2 iterations)
        run_kat("Test 2", 64'hc020a52796443c7b, 64'h3FFB42C2C8A17E81,
            '{8'hf4, 8'hda, 8'h0f, 8'h8d, 8'h84, 8'h44, 8'hd1, 8'ha7, 8'h72, 8'h65, 8'hc2,
              8'hef, 8'h6f, 8'h98, 8'hbb, 8'hbb, 8'h4b, 8'hee, 8'h7d, 8'hb8, 8'hd9, 8'hb3},
            -8
        );

        // Test 3: mu = -19.096516109216804 | sigma' = 1.7035823083824078 (2 iterations)
        run_kat("Test 3", 64'hC03318B5479C9F93, 64'h3FFB41DF85C8BEFD,
            '{8'hdb, 8'h47, 8'hf6, 8'hd7, 8'hfb, 8'h9b, 8'h19, 8'hf2, 8'h5c, 8'h36, 8'hd6,
              8'hb9, 8'h33, 8'h4d, 8'h47, 8'h7a, 8'h8b, 8'hc0, 8'hbe, 8'h68, 8'h14, 8'h5d},
            -20
        );

        // Test 4: mu = -11.335543982423326 | sigma' = 1.7035823083824078 -> z = -12
        run_kat("Test 4", 64'hC026ABCC6BBDC16D, 64'h3FFB41DF85C8BEFD,
            '{8'hae, 8'h41, 8'hb4, 8'hf5, 8'h20, 8'h96, 8'h65, 8'hc7, 8'h4d, 8'h00, 8'hdc,
              8'hc1, 8'ha8, 8'h16, 8'h8a, 8'h7b, 8'hb5, 8'h16, 8'hb3, 8'h19, 8'h0c, 8'hb4,
              8'h2c, 8'h1d, 8'hed, 8'h26, 8'hcd, 8'h52, 8'hae, 8'hd7, 8'h70, 8'hec, 8'ha7,
              8'hdd, 8'h33, 8'h4e, 8'h05, 8'h47, 8'hbc, 8'hc3, 8'hc1, 8'h63, 8'hce, 8'h0b},
            -12
        );

        // Test 5: mu = 7.9386734193997555 | sigma' = 1.6984647769450156 -> z = 8
        run_kat("Test 5", 64'h401FC1339AD7C928, 64'h3FFB2CE966E6303D,
            '{8'h31, 8'h05, 8'h41, 8'h66, 8'hc1, 8'h01, 8'h27, 8'h80, 8'hc6, 8'h03, 8'hae,
              8'h9b, 8'h83, 8'h3c, 8'hec, 8'h73, 8'hf2, 8'hf4, 8'h1c, 8'ha5, 8'h80, 8'h7c,
              8'hc8, 8'h9c, 8'h92, 8'h15, 8'h88, 8'h34, 8'h63, 8'h2f, 8'h9b, 8'h15, 8'h55},
            8
        );

        // Test 6: mu = -28.990850086867255 | sigma' = 1.6984647769450156 (1 iteration)
        run_kat("Test 6", 64'hC03CFDA859EE5568, 64'h3FFB2CE966E6303D,
            '{8'h73, 8'h7e, 8'h9d, 8'h68, 8'ha5, 8'h0a, 8'h06, 8'hdb, 8'hbc, 8'h64, 8'h77},
            -30
        );

        // Test 7: mu = -9.071257914091655 | sigma' = 1.6980782114808988 (1 iteration)
        run_kat("Test 7", 64'hC022247BEAD535AD, 64'h3FFB2B540F05C526,
            '{8'ha9, 8'h8d, 8'hdd, 8'h14, 8'hbf, 8'h0b, 8'hf2, 8'h20, 8'h61, 8'hd6, 8'h32},
            -10
        );

        // Test 8: mu = -43.88754568839566 | sigma' = 1.6980782114808988 (1 iteration)
        run_kat("Test 8", 64'hC045F19B18DCAEBE, 64'h3FFB2B540F05C526,
            '{8'h3c, 8'hbf, 8'h68, 8'h18, 8'ha6, 8'h8f, 8'h7a, 8'hb9, 8'h99, 8'h15, 8'h14},
            -41
        );

        // Test 9: mu = -58.17435547946095 | sigma' = 1.7010983419195522 -> z = -61
        // Iteration 1 dung 11 byte; Iteration 2 dung 12 byte (BerExp dung 2 byte: 58 7c)
        run_kat("Test 9", 64'hC04D165147C514E3, 64'h3FFB37B2E51D3058,
            '{8'h6f, 8'h86, 8'h33, 8'hf5, 8'hbf, 8'ha5, 8'hd2, 8'h68, 8'h48, 8'h66, 8'h8e,
              8'h3d, 8'h5d, 8'hdd, 8'h46, 8'h95, 8'h8e, 8'h97, 8'h63, 8'h04, 8'h10, 8'h58, 8'h7c},
            -61
        );

        // Test 10: mu = -43.58664906684732 | sigma' = 1.7010983419195522 -> z = -46
        run_kat("Test 10", 64'hC045CB17510E2B49, 64'h3FFB37B2E51D3058,
            '{8'h27, 8'h2b, 8'hc6, 8'hc2, 8'h5f, 8'h5c, 8'h5e, 8'he5, 8'h3f, 8'h83, 8'hc4,
              8'h3a, 8'h36, 8'h1f, 8'hbc, 8'h7c, 8'hc9, 8'h1d, 8'hc7, 8'h83, 8'he2, 8'h0a},
            -46
        );

        // Test 11: mu = -34.70565203313315 | sigma' = 1.7009387219711465 -> z = -34
        run_kat("Test 11", 64'hC0415A52CE4A54D6, 64'h3FFB370B8575DB97,
            '{8'h45, 8'h44, 8'h3c, 8'h59, 8'h57, 8'h4c, 8'h2c, 8'h3b, 8'h07, 8'he2, 8'he1,
              8'hd9, 8'h07, 8'h1e, 8'h6d, 8'h13, 8'h3d, 8'hbe, 8'h32, 8'h75, 8'h4b, 8'h0a},
            -34
        );

        // Test 12: mu = -44.36009577368896 | sigma' = 1.7009387219711465 -> z = -44
        run_kat("Test 12", 64'hC0462E179E49B601, 64'h3FFB370B8575DB97,
            '{8'h6a, 8'hc1, 8'h16, 8'hed, 8'h60, 8'hc2, 8'h58, 8'he2, 8'hcb, 8'hae, 8'hab,
              8'h72, 8'h8c, 8'h48, 8'h23, 8'he6, 8'hda, 8'h36, 8'he1, 8'h8d, 8'h08, 8'hda,
              8'h5d, 8'h0c, 8'hc1, 8'h04, 8'he2, 8'h1c, 8'hc7, 8'hfd, 8'h1f, 8'h5c, 8'ha8,
              8'hd9, 8'hdb, 8'hb6, 8'h75, 8'h26, 8'h6c, 8'h92, 8'h84, 8'h48, 8'h05, 8'h9e},
            -44
        );

        // Test 13: mu = -21.783037079346236 | sigma' = 1.6958406126012802 -> z = -23
        run_kat("Test 13", 64'hC035C8751E3758F2, 64'h3FFB2229C4259E1F,
            '{8'h68, 8'h16, 8'h3b, 8'hc1, 8'he2, 8'hcb, 8'hf3, 8'he1, 8'h8e, 8'h74, 8'h26},
            -23
        );

        // Test 14: mu = -39.68827784633828 | sigma' = 1.6958406126012802 -> z = -40
        run_kat("Test 14", 64'hC043D8197D0C4AC8, 64'h3FFB2229C4259E1F,
            '{8'hd6, 8'ha1, 8'hb5, 8'h1d, 8'h76, 8'h22, 8'h2a, 8'h70, 8'h5a, 8'h02, 8'h59},
            -40
        );

        // Test 15: mu = -18.488607061056847 | sigma' = 1.6955259305261838 -> z = -22
        run_kat("Test 15", 64'hC0327D155A33D576, 64'h3FFB20DFCC52142F,
            '{8'hf0, 8'h52, 8'h3b, 8'hfa, 8'ha8, 8'ha3, 8'h94, 8'hbf, 8'h4e, 8'ha5, 8'hc1,
              8'h0f, 8'h84, 8'h23, 8'h66, 8'hfd, 8'he2, 8'h86, 8'hd6, 8'ha3, 8'h08, 8'h03},
            -22
        );

        // Test 16: mu = -48.39610939101591 | sigma' = 1.6955259305261838 -> z = -50
        run_kat("Test 16", 64'hC04832B3B66806A2, 64'h3FFB20DFCC52142F,
            '{8'h87, 8'hbd, 8'h87, 8'he6, 8'h33, 8'h74, 8'hce, 8'he6, 8'h21, 8'h27, 8'hfc,
              8'h69, 8'h31, 8'h10, 8'h4a, 8'hab, 8'h64, 8'hf1, 8'h36, 8'ha0, 8'h48, 8'h5b},
            -50
        );

        $display("\n=================================================");
        $display(" KET QUA TESTBENCH: PASS = %0d / %0d | FAIL = %0d", pass_count, test_count, fail_count);
        $display("=================================================");

        $finish;
    end

endmodule