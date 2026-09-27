/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : radix_4_16d
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: radix_4_16d.sv
 *    Create Date : Aug 28th 2026
 *    Last Update : Aug 28th 2026
 *    Description : Testbench for Multiplier with 16 latency
 ******************************************************************************
  History:

 ******************************************************************************/

module tb_radix_4_16d;

    localparam int N           = 64;           
    localparam int LATENCY     = N / 4; // 16 chu kỳ
    localparam int CLK_PERIOD  = 10;
    localparam int TOTAL_TESTS = 500;

    logic             clk;
    logic             rst_n;
    logic [N-1:0]     a;
    logic [N-1:0]     b;
    logic [2*N-1:0]   p;

    logic [2*N-1:0]   expected_q[$];
    int               pass_cnt = 0;
    int               err_cnt  = 0;
    bit               stim_done = 0;

    // DUT
    radix_4_16d #(.N(N)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    // Clock: posedge tại 5ns, 15ns, 25ns, 35ns...
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // 1. Luồng cấp dữ liệu: Bơm trực tiếp tại đúng sườn dương (posedge clk)
    initial begin
        rst_n = 0;
        a     = '0;
        b     = '0;
        #(CLK_PERIOD * 2);

        // Nhả reset ở sườn âm để mạch sẵn sàng trước posedge
        @(negedge clk);
        rst_n = 1;

        // Cập nhật a, b đúng tại từng posedge clk
        repeat (TOTAL_TESTS) begin
            logic [N-1:0] rand_a, rand_b;
            if (N == 8) begin
                rand_a = $urandom_range(0, 255);
                rand_b = $urandom_range(0, 255);
            end else begin
                rand_a = {$urandom(), $urandom()};
                rand_b = {$urandom(), $urandom()};
            end

            @(posedge clk);
            a <= rand_a;
            b <= rand_b;
            expected_q.push_back((2*N)'(rand_a) * (2*N)'(rand_b));
        end

        // Xả pipeline
        repeat (LATENCY + 2) begin
            @(posedge clk);
            a <= '0;
            b <= '0;
        end

        stim_done = 1;
    end

    // 2. Luồng kiểm tra: So sánh kết quả tại sườn dương sau đúng LATENCY chu kỳ
    initial begin
        wait(rst_n == 1'b1);
        repeat (LATENCY) @(posedge clk);

        while (!stim_done || expected_q.size() > 0) begin
            @(posedge clk);
            #1; // Delay 1ns sau posedge để DUT chốt và đẩy ngõ ra p ổn định
            if (expected_q.size() > 0) begin
                logic [2*N-1:0] exp;
                exp = expected_q.pop_front();

                if (p === exp) begin
                    pass_cnt++;
                end else begin
                    err_cnt++;
                    $display("[ERROR] Time=%0t ps | Actual=0x%032h != Expected=0x%032h", $time, p, exp);
                end
            end
        end

        $display("-------------------------------------------");
        $display("[SUMMARY] Tested: %0d | Passed: %0d | Errors: %0d", pass_cnt + err_cnt, pass_cnt, err_cnt);
        if (err_cnt == 0)
            $display("[STATUS] >>> ALL TEST VECTORS MATCHED 100%%! <<<");
        else
            $display("[STATUS] >>> TEST FAILED! <<<");
        $display("-------------------------------------------");
        $finish;
    end

endmodule