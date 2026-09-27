/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : radix_4_8d
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: radix_4_8d.sv
 *    Create Date : Aug 28th 2026
 *    Last Update : Aug 28th 2026
 *    Description : Testbench for Multiplier with 8 latency
 ******************************************************************************
  History:

 ******************************************************************************/

module tb_radix_4_8d;

    localparam int N          = 64;
    localparam int LATENCY    = N / 8; 
    localparam int CLK_PERIOD = 10;

    logic             clk;
    logic             rst_n;
    logic [N-1:0]     a;
    logic [N-1:0]     b;
    logic [2*N-1:0]   p;

    logic [2*N-1:0]   expected_q[$];
    int               pass_cnt = 0;
    int               err_cnt  = 0;
    int               stim_cnt = 0;
    bit               sim_done = 0;

    radix_4_8d #(.N(N)) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Reset
    initial begin
        rst_n = 0;
        #25;
        rst_n = 1;
    end


    always @(negedge clk) begin
        if (!rst_n) begin
            a <= '0;
            b <= '0;
        end else if (stim_cnt < 500) begin
            logic [N-1:0] rand_a, rand_b;
            rand_a = {$urandom(), $urandom()};
            rand_b = {$urandom(), $urandom()};

            a <= rand_a;
            b <= rand_b;
            expected_q.push_back((2*N)'(rand_a) * (2*N)'(rand_b));
            stim_cnt <= stim_cnt + 1;
        end else begin
            a <= '0;
            b <= '0;
            if (expected_q.size() == 0) sim_done <= 1'b1;
        end
    end


    initial begin
        wait(rst_n == 1'b1);
        repeat (LATENCY) @(negedge clk);

        while (!sim_done) begin
            @(negedge clk);
            if (expected_q.size() > 0) begin
                logic [2*N-1:0] exp;
                exp = expected_q.pop_front();

                if (p === exp) begin
                    pass_cnt++;
                end else begin
                    err_cnt++;
                    $display("[ERROR] Time=%0t | Actual=0x%032h != Expected=0x%032h", $time, p, exp);
                end
            end
        end

        $display("-------------------------------------------");
        $display("[SUMMARY] Tested: %0d | Passed: %0d | Errors: %0d", pass_cnt + err_cnt, pass_cnt, err_cnt);
        if (err_cnt == 0)
            $display("[STATUS] >>> PASSED: 8-CYCLE MULTIPLIER 100%% CORRECT! <<<");
        $display("-------------------------------------------");
        $finish;
    end

endmodule