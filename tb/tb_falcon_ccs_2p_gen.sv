/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : tb_falcon_ccs_2p_gen
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: tb_falcon_ccs_2p_gen.sv
 *    Create Date : Aug 28th 2026
 *    Last Update : Aug 28th 2026
 *    Description : Testbench for Calculate ccs and 1 / (2 * o'^2) for step 2 & 7 in SamplerZ
 ******************************************************************************
  History:

 ******************************************************************************/

`include "falcon_header.svh"

module tb_falcon_ccs_2p_gen;

    // -------------------------------------------------------------
    // Khai báo tín hiệu giao tiếp DUT
    // -------------------------------------------------------------
    logic                       clk;
    logic                       rst_n;
    logic                       start;
    logic                       done;
    logic [`FPU_STAND - 1 : 0]  o_dot;
    logic [`FALCON_CCS - 1 : 0] ccs;
    logic [`FALCON_SQR_P - 1 : 0] o_sqr;

    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    localparam logic [63:0] O_MIN_FPU = 64'h3FF47201BF2577E7;

    // -------------------------------------------------------------
    // Hàm tham chiếu chuyển FP64 sang Q1.63
    // -------------------------------------------------------------
    function automatic logic [63:0] ref_fpu_to_q1_63(input logic [63:0] fp_in);
        logic [10:0] exp;
        logic [51:0] frac;
        logic [63:0] res;
        
        exp  = fp_in[62:52];
        frac = fp_in[51:0];
        
        if (exp == 11'd0) begin
            res = 64'd0;
        end else if (exp >= 11'd1023) begin
            res = 64'h8000_0000_0000_0000;
        end else if (exp == 11'd1022) begin
            res = {1'b0, 1'b1, frac, 10'b0};
        end else begin
            res = ({1'b1, frac, 10'b0} >> (11'd1022 - exp));
        end
        return res;
    endfunction

    // -------------------------------------------------------------
    // Hàm kiểm tra dung sai số học
    // -------------------------------------------------------------
    function automatic bit check_diff(input logic [63:0] act, input logic [63:0] exp, input logic [63:0] max_diff);
        logic [63:0] diff;
        diff = (act >= exp) ? (act - exp) : (exp - act);
        return (diff <= max_diff);
    endfunction

    // -------------------------------------------------------------
    // Kết nối DUT
    // -------------------------------------------------------------
    falcon_ccs_2p_gen dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (start),
        .done    (done),
        .o_dot   (o_dot),
        .ccs     (ccs),
        .o_sqr   (o_sqr)
    );

    // -------------------------------------------------------------
    // Clock 100MHz (Chu kỳ 10ns)
    // -------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------
    // Task kiểm thử tự động
    // -------------------------------------------------------------
    task automatic run_test(
        input string       test_name,
        input logic [63:0] o_dot_fpu_bits,
        input logic [63:0] exp_osqr
    );
        logic [63:0] exp_ccs;
        logic [63:0] q_fpu_ref;
        real o_min_real;
        real o_dot_real;
        real q_real;

        test_count++;

        // Tính golden value cho ccs theo đúng chuẩn chia FP64
        o_min_real = $bitstoreal(O_MIN_FPU);
        o_dot_real = $bitstoreal(o_dot_fpu_bits);
        q_real     = o_min_real / o_dot_real;
        q_fpu_ref  = $realtobits(q_real);
        exp_ccs    = ref_fpu_to_q1_63(q_fpu_ref);

        @(posedge clk);
        o_dot <= o_dot_fpu_bits;
        start <= 1'b1;

        @(posedge clk);
        start <= 1'b0;

        // Chờ tín hiệu done
        fork
            begin
                @(posedge done);
            end
            begin
                repeat(300) @(posedge clk);
                if (!done) begin
                    $display("\n[TIMEOUT] %s: Khong nhan duoc tin hieu done!", test_name);
                    fail_count++;
                    disable fork;
                end
            end
        join_any
        disable fork;

        if (done) begin
            #1;
            $display("\n--- %s ---", test_name);
            $display("Input sigma' (real) = %f | FP64 Hex = 16'h%016h", o_dot_real, o_dot_fpu_bits);
            $display("Output ccs   : Actual = 16'h%016h | Expected = 16'h%016h", ccs, exp_ccs);
            $display("Output o_sqr : Actual = 16'h%016h | Expected = 16'h%016h", o_sqr, exp_osqr);

            // ccs cần khớp tuyệt đối hoặc sai số làm tròn tối đa 1 LSB do bộ chia
            // o_sqr trải qua 2 tầng nhân 64-bit nên dung sai cho phép trong khoảng 256 đơn vị (8-bit LSB thấp nhất)
            if (check_diff(ccs, exp_ccs, 64'd1) && check_diff(o_sqr, exp_osqr, 64'h100)) begin
                $display("[STATUS] => PASS");
                pass_count++;
            end else begin
                $display("[STATUS] => FAIL");
                fail_count++;
            end
        end

        repeat(3) @(posedge clk);
    endtask

    // -------------------------------------------------------------
    // Kịch bản kiểm thử
    // -------------------------------------------------------------
    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        o_dot = '0;

        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        $display("=================================================");
        $display("     BAT DAU TESTBENCH FALCON CCS_2P_GEN         ");
        $display("=================================================");

        // Test 1: Điểm cực tiểu sigma' = sigma_min
        run_test(
            "Test 1: sigma' = sigma_min (Boundary min)",
            64'h3FF47201BF2577E7,
            64'h4E63DE84E5EE3645
        );

        // Test 2: Điểm cực đại sigma' = sigma_max = 1.8205
        run_test(
            "Test 2: sigma' = sigma_max (Boundary max)",
            64'h3FFD20C49BA5E354,
            64'h269F178307778416
        );

        // Test 3: Giá trị thông thường ở giữa dải: sigma' = 1.5
        run_test(
            "Test 3: sigma' = 1.5 (Mid-range value)",
            64'h3FF8000000000000,
            64'h38E38E38E38E38E4
        );

        $display("\n=================================================");
        $display(" KET QUA TESTBENCH: PASS = %0d / %0d | FAIL = %0d", pass_count, test_count, fail_count);
        $display("=================================================");

        $finish;
    end

endmodule