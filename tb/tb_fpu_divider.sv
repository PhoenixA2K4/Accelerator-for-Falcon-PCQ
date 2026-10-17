// `timescale 1ns/1ps
// `include "falcon_header.svh"

// module tb_fpu_divider;
//     logic clk = 1'b0;
//     always #5 clk = ~clk;

//     logic rst_n, start;
//     logic [`FPU_STAND-1:0] a, b;
//     logic [`FPU_STAND-1:0] result;
//     logic valid, busy;
//     integer pass_count = 0;
//     integer fail_count = 0;
//     integer test_count = 0;

//     fpu_divider dut (
//         .clk(clk), .rst_n(rst_n), .start(start),
//         .a(a), .b(b), .result(result), .valid(valid), .busy(busy)
//     );

//     // Normal finite operands: exact FP64 bit comparison against host real.
//     // Special values: provide expected IEEE-754 encodings explicitly.
//     task automatic run_case (
//         input string name,
//         input logic [63:0] a_bits,
//         input logic [63:0] b_bits,
//         input logic [63:0] expected,
//         input integer expected_latency
//     );
//         integer cycles;
//         logic [63:0] got;
//         bit did_fail;
//         begin
//             test_count++;
//             did_fail = 1'b0;
//             @(negedge clk);
//             if (busy || valid) begin
//                 $display("FAIL [%0d] %s: divider not idle", test_count, name);
//                 fail_count++;
//             end else begin
//                 a = a_bits;
//                 b = b_bits;
//                 start = 1'b1;
//                 @(posedge clk); #1;
//                 start = 1'b0;
//                 if (!busy) begin
//                     $display("FAIL [%0d] %s: busy not asserted", test_count, name);
//                     did_fail = 1'b1;
//                 end
//                 cycles = 0;
//                 while (!valid && cycles < 70) begin
//                     @(posedge clk); #1;
//                     cycles++;
//                     if (!valid && !busy) begin
//                         $display("FAIL [%0d] %s: busy dropped before valid", test_count, name);
//                         did_fail = 1'b1;
//                     end
//                 end
//                 got = result;
//                 if (!valid) begin
//                     $display("FAIL [%0d] %s: timeout after %0d clocks", test_count, name, cycles);
//                     did_fail = 1'b1;
//                 end else begin
//                     if (cycles != expected_latency) begin
//                         $display("FAIL [%0d] %s: latency=%0d expected=%0d", test_count, name, cycles, expected_latency);
//                         did_fail = 1'b1;
//                     end
//                     if (busy) begin
//                         $display("FAIL [%0d] %s: busy still high with valid", test_count, name);
//                         did_fail = 1'b1;
//                     end
//                     if (got !== expected) begin
//                         $display("FAIL [%0d] %s: a=%016h b=%016h got=%016h expected=%016h", test_count, name, a_bits, b_bits, got, expected);
//                         did_fail = 1'b1;
//                     end
//                 end
//                 @(posedge clk); #1;
//                 if (valid) begin
//                     $display("FAIL [%0d] %s: valid was not a one-cycle pulse", test_count, name);
//                     did_fail = 1'b1;
//                 end
//                 if (did_fail) fail_count++;
//                 else begin
//                     pass_count++;
//                     $display("PASS [%0d] %-26s result=%016h latency=%0d", test_count, name, got, cycles);
//                 end
//             end
//         end
//     endtask

//     task automatic run_normal (
//         input string name,
//         input real x,
//         input real y
//     );
//         real golden;
//         begin
//             golden = x / y;
//             run_case(name, $realtobits(x), $realtobits(y), $realtobits(golden), 57);
//         end
//     endtask

//     initial begin : tests
//         rst_n = 0;
//         start = 0;
//         a = 0;
//         b = 0;
//         repeat (3) @(negedge clk);
//         rst_n = 1;

//         run_normal("6 / 2",           6.0,   2.0);
//         run_normal("7 / 2",           7.0,   2.0);
//         run_normal("1 / 3",           1.0,   3.0);
//         run_normal("2 / 3",           2.0,   3.0);
//         run_normal("1 / 10",          1.0,  10.0);
//         run_normal("-7 / 2",         -7.0,   2.0);
//         run_normal("7 / -2",          7.0,  -2.0);
//         run_normal("-7 / -2",        -7.0,  -2.0);
//         run_normal("1 / 1",           1.0,   1.0);
//         run_normal("1 / 2",           1.0,   2.0);
//         run_normal("1000 / 0.125", 1000.0,   0.125);
//         run_normal("small / large",   1.0e-20, 1.0e20);
//         run_normal("large / small",   1.0e20,  1.0e-20);
//         run_normal("pi / e",          3.141592653589793, 2.718281828459045);
//         run_normal("nontrivial",      12345.6789, 0.987654321);

//         // Special cases: RTL fast path, expected 2 clocks after acceptance.
//         run_case("+0 / 2",       64'h0000000000000000, 64'h4000000000000000, 64'h0000000000000000, 2);
//         run_case("-0 / 2",       64'h8000000000000000, 64'h4000000000000000, 64'h8000000000000000, 2);
//         run_case("1 / +0",       64'h3ff0000000000000, 64'h0000000000000000, 64'h7ff0000000000000, 2);
//         run_case("0 / 0",        64'h0000000000000000, 64'h0000000000000000, 64'h7ff8000000000000, 2);
//         run_case("Inf / Inf",    64'h7ff0000000000000, 64'h7ff0000000000000, 64'h7ff8000000000000, 2);
//         run_case("Inf / 2",      64'h7ff0000000000000, 64'h4000000000000000, 64'h7ff0000000000000, 2);
//         run_case("1 / Inf",      64'h3ff0000000000000, 64'h7ff0000000000000, 64'h0000000000000000, 2);
//         run_case("NaN / 2",      64'h7ff8000000000001, 64'h4000000000000000, 64'h7ff8000000000000, 2);

//         $display("\n========================================");
//         $display("TEST SUMMARY: %0d PASS, %0d FAIL, %0d TOTAL", pass_count, fail_count, test_count);
//         $display("========================================");
//         if (fail_count != 0) $fatal(1, "fpu_divider failed");
//         else $display("ALL TESTS PASSED");
//         $finish;
//     end
// endmodule


`timescale 1ns/1ps
`include "falcon_header.svh"

module tb_fpu_divider;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic rst_n, start;
    logic [`FPU_STAND-1:0] a, b;
    logic [`FPU_STAND-1:0] result;
    logic valid, busy;
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count = 0;

    fpu_divider dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a(a), .b(b), .result(result), .valid(valid), .busy(busy)
    );

    // Normal finite operands: exact FP64 bit comparison against host real.
    // Special values: provide expected IEEE-754 encodings explicitly.
    task automatic run_case (
        input string name,
        input logic [63:0] a_bits,
        input logic [63:0] b_bits,
        input logic [63:0] expected,
        input integer expected_latency
    );
        integer cycles;
        logic [63:0] got;
        bit did_fail;
        begin
            test_count++;
            did_fail = 1'b0;
            @(negedge clk);
            if (busy || valid) begin
                $display("FAIL [%0d] %s: divider not idle", test_count, name);
                fail_count++;
            end else begin
                a = a_bits;
                b = b_bits;
                start = 1'b1;
                @(posedge clk); #1;
                start = 1'b0;
                if (!busy) begin
                    $display("FAIL [%0d] %s: busy not asserted", test_count, name);
                    did_fail = 1'b1;
                end
                cycles = 0;
                while (!valid && cycles < 45) begin
                    @(posedge clk); #1;
                    cycles++;
                    if (!valid && !busy) begin
                        $display("FAIL [%0d] %s: busy dropped before valid", test_count, name);
                        did_fail = 1'b1;
                    end
                end
                got = result;
                if (!valid) begin
                    $display("FAIL [%0d] %s: timeout after %0d clocks", test_count, name, cycles);
                    did_fail = 1'b1;
                end else begin
                    if (cycles != expected_latency) begin
                        $display("FAIL [%0d] %s: latency=%0d expected=%0d", test_count, name, cycles, expected_latency);
                        did_fail = 1'b1;
                    end
                    if (busy) begin
                        $display("FAIL [%0d] %s: busy still high with valid", test_count, name);
                        did_fail = 1'b1;
                    end
                    if (got !== expected) begin
                        $display("FAIL [%0d] %s: a=%016h b=%016h got=%016h expected=%016h", test_count, name, a_bits, b_bits, got, expected);
                        did_fail = 1'b1;
                    end
                end
                @(posedge clk); #1;
                if (valid) begin
                    $display("FAIL [%0d] %s: valid was not a one-cycle pulse", test_count, name);
                    did_fail = 1'b1;
                end
                if (did_fail) fail_count++;
                else begin
                    pass_count++;
                    $display("PASS [%0d] %-26s result=%016h latency=%0d", test_count, name, got, cycles);
                end
            end
        end
    endtask

    task automatic run_normal (
        input string name,
        input real x,
        input real y
    );
        real golden;
        begin
            golden = x / y;
            run_case(name, $realtobits(x), $realtobits(y), $realtobits(golden), 29);
        end
    endtask

    initial begin : tests
        rst_n = 0;
        start = 0;
        a = 0;
        b = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;

        run_normal("6 / 2",           6.0,   2.0);
        run_normal("7 / 2",           7.0,   2.0);
        run_normal("1 / 3",           1.0,   3.0);
        run_normal("2 / 3",           2.0,   3.0);
        run_normal("1 / 10",          1.0,  10.0);
        run_normal("-7 / 2",         -7.0,   2.0);
        run_normal("7 / -2",          7.0,  -2.0);
        run_normal("-7 / -2",        -7.0,  -2.0);
        run_normal("1 / 1",           1.0,   1.0);
        run_normal("1 / 2",           1.0,   2.0);
        run_normal("1000 / 0.125", 1000.0,   0.125);
        run_normal("small / large",   1.0e-20, 1.0e20);
        run_normal("large / small",   1.0e20,  1.0e-20);
        run_normal("pi / e",          3.141592653589793, 2.718281828459045);
        run_normal("nontrivial",      12345.6789, 0.987654321);

        // Special cases: RTL fast path, expected 2 clocks after acceptance.
        run_case("+0 / 2",       64'h0000000000000000, 64'h4000000000000000, 64'h0000000000000000, 2);
        run_case("-0 / 2",       64'h8000000000000000, 64'h4000000000000000, 64'h8000000000000000, 2);
        run_case("1 / +0",       64'h3ff0000000000000, 64'h0000000000000000, 64'h7ff0000000000000, 2);
        run_case("0 / 0",        64'h0000000000000000, 64'h0000000000000000, 64'h7ff8000000000000, 2);
        run_case("Inf / Inf",    64'h7ff0000000000000, 64'h7ff0000000000000, 64'h7ff8000000000000, 2);
        run_case("Inf / 2",      64'h7ff0000000000000, 64'h4000000000000000, 64'h7ff0000000000000, 2);
        run_case("1 / Inf",      64'h3ff0000000000000, 64'h7ff0000000000000, 64'h0000000000000000, 2);
        run_case("NaN / 2",      64'h7ff8000000000001, 64'h4000000000000000, 64'h7ff8000000000000, 2);

        $display("\n========================================");
        $display("TEST SUMMARY: %0d PASS, %0d FAIL, %0d TOTAL", pass_count, fail_count, test_count);
        $display("========================================");
        if (fail_count != 0) $fatal(1, "fpu_divider failed");
        else $display("ALL TESTS PASSED");
        $finish;
    end
endmodule
