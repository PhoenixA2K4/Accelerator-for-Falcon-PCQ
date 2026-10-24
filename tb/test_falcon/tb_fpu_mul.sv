`timescale 1ns/1ps
module tb_fpu_mul;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst_n = 0;
    logic start = 0;
    logic [63:0] a = 0, b = 0;
    wire [63:0] result;
    wire valid_o;
    integer pass_count = 0, fail_count = 0;

    fpu_mul dut ( .clk(clk), .rst_n(rst_n), .start(start),
                    .a(a), .b(b), .result(result), .valid_o(valid_o) );

    task automatic check(input string label_s, input real ra, input real rb);
        logic [63:0] expected;
        begin
            expected = $realtobits(ra * rb);
            @(negedge clk);
            start = 1;
            a = $realtobits(ra);
            b = $realtobits(rb);
            @(negedge clk);
            start = 0;
            // The input was accepted at the previous posedge (stage 1).
            // Four more posedges reach stage 5.
            repeat (3) @(negedge clk);
            // Here stage 4 just received the transaction.
            @(posedge clk); #1;
            if (!valid_o || (result !== expected)) begin
                $display("FAIL %-25s a=%h b=%h got=%h exp=%h valid=%b",
                         label_s, $realtobits(ra), $realtobits(rb), result, expected, valid_o);
                fail_count++;
            end else begin
                $display("PASS %-25s result=%h", label_s, result);
                pass_count++;
            end
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        check("1.5 * 2.5", 1.5, 2.5);
        check("-3.0 * 4.5", -3.0, 4.5);
        check("-1.25 * -2.5", -1.25, -2.5);
        check("0.0 * 5.0", 0.0, 5.0);
        check("1.0 * 1.0", 1.0, 1.0);
        check("0.5 * 0.5", 0.5, 0.5);
        check("3.141592653589793 * 2", 3.141592653589793, 2.0);
        check("1e100 * 1e-100", 1.0e100, 1.0e-100);
        check("1.0000000000000002^2", 1.0000000000000002, 1.0000000000000002);
        check("1.23456789012345 * 9.87654321098765", 1.23456789012345, 9.87654321098765);
        check("1234567.25 * -0.03125", 1234567.25, -0.03125);
        $display("SUMMARY PASS=%0d FAIL=%0d", pass_count, fail_count);
        if (fail_count == 0) $display("ALL TESTS PASSED");
        else $fatal(1, "FP64 multiplier failed");
        $finish;
    end
endmodule
