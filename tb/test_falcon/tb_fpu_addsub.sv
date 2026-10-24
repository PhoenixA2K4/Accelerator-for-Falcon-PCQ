`timescale 1ns/1ps

module tb_fpu_addsub;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic rst_n, start, sub;
    logic [63:0] a, b;
    logic [63:0] result;
    logic valid_o;
    int pass_count = 0;
    int fail_count = 0;

    fpu_addsub dut (
        .clk(clk), .rst_n(rst_n), .start(start), .sub(sub),
        .a(a), .b(b), .result(result), .valid_o(valid_o)
    );

    task automatic check_case(
        input string name,
        input real x,
        input real y,
        input logic do_sub
    );
        logic [63:0] expected;
        real golden;
        begin
            golden   = do_sub ? (x - y) : (x + y);
            expected = $realtobits(golden);
            @(negedge clk);
            a     = $realtobits(x);
            b     = $realtobits(y);
            sub   = do_sub;
            start = 1'b1;

            // The fourth sampling edge after start is asserted produces valid_o.
            for (int cycle = 1; cycle <= 4; cycle++) begin
                @(posedge clk);
                #1;
                if (cycle < 4 && valid_o !== 1'b0) begin
                    $display("FAIL %-28s unexpected valid at cycle %0d", name, cycle);
                    fail_count++;
                end
                if (cycle == 4) begin
                    if (valid_o !== 1'b1 || result !== expected) begin
                        $display("FAIL %-28s got=%016h expected=%016h valid=%b", name, result, expected, valid_o);
                        fail_count++;
                    end else begin
                        $display("PASS %-28s result=%016h (%f)", name, result, golden);
                        pass_count++;
                    end
                end
                if (cycle == 1) begin
                    @(negedge clk);
                    start = 1'b0;
                end
            end
            @(posedge clk);
            #1;
            if (valid_o !== 1'b0) begin
                $display("FAIL %-28s valid_o not cleared", name);
                fail_count++;
            end
        end
    endtask

    initial begin
        rst_n = 0;
        start = 0;
        sub = 0;
        a = '0;
        b = '0;
        repeat (3) @(negedge clk);
        rst_n = 1;

        check_case("1.5 + 2.5",          1.5,          2.5,          1'b0);
        check_case("5.75 - 2.25",        5.75,         2.25,         1'b1);
        check_case("-1.0 + 1.0",        -1.0,          1.0,          1'b0);
        check_case("-3.25 + -2.5",      -3.25,        -2.5,          1'b0);
        check_case("2.25 - 5.75",        2.25,         5.75,         1'b1);
        check_case("0.0 + 7.0",          0.0,          7.0,          1'b0);
        check_case("7.0 - 0.0",          7.0,          0.0,          1'b1);
        check_case("1.0 + 1.0",          1.0,          1.0,          1'b0);
        check_case("1.0 + 2^-52",        1.0,          2.220446049250313e-16, 1'b0);
        check_case("1.0 + 2^-53 tie",    1.0,          1.1102230246251565e-16,1'b0);
        check_case("1e20 + 1.0",         1.0e20,       1.0,          1'b0);
        check_case("1000.0 - 999.875",  1000.0,       999.875,      1'b1);

        $display("\nSUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
        if (fail_count != 0) $fatal(1, "FP64 ADD/SUB tests failed");
        else $display("ALL SUPPORTED TESTS PASSED");
        $finish;
    end
endmodule
