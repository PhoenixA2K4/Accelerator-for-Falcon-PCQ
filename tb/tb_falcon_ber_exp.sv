`timescale 1ns / 1ps
`include "falcon_header.svh"

module tb_falcon_ber_exp;

    // -------------------------------------------------------------
    // Tín hiệu giao tiếp DUT
    // -------------------------------------------------------------
    logic                       clk;
    logic                       rst_n;
    logic                       start;
    logic [`FALCON_X - 1 : 0]   x;
    logic [`FALCON_CCS - 1 : 0] ccs;
    logic [7 : 0]               uniform_bits;
    logic                       check_bit;
    logic                       done;

    // Biến thống kê testbench
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    // -------------------------------------------------------------
    // Khởi tạo DUT (Device Under Test)
    // -------------------------------------------------------------
    falcon_ber_exp dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .x              (x),
        .ccs            (ccs),
        .uniform_bits   (uniform_bits),
        .check_bit      (check_bit),
        .done           (done)
    );
    // -------------------------------------------------------------
    // Bộ tạo xung Clock (100 MHz -> Chu kỳ 10ns)
    // -------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------
    // Task thực thi từng Test Case
    // -------------------------------------------------------------
    task automatic run_ber_test(
        input string                test_name,
        input logic [`FALCON_X-1:0]   in_x,
        input logic [`FALCON_CCS-1:0] in_ccs,
        input logic [7 : 0]         in_rand,
        input logic                 expected_bit
    );
        test_count++;
        @(posedge clk);
        x            <= in_x;
        ccs          <= in_ccs;
        uniform_bits <= in_rand;
        start        <= 1'b1;

        @(posedge clk);
        start        <= 1'b0;

        // Chờ cờ done bật lên
        fork
            begin
                @(posedge done);
            end
            begin
                // Timeout phòng ngừa FSM bị treo (1000 chu kỳ clock)
                repeat(1000) @(posedge clk);
                if (!done) begin
                    $display("[TIMEOUT] %s: DUT khong tra done!", test_name);
                    fail_count++;
                    disable fork;
                end
            end
        join_any
        disable fork;

        // Kiểm tra kết quả tại thời điểm done = 1
        if (done) begin
            #1; // Trễ nhẹ để tín hiệu chốt ổn định
            if (check_bit === expected_bit) begin
                $display("[PASS] %s | check_bit = %0b (Mong doi: %0b)", 
                         test_name, check_bit, expected_bit);
                pass_count++;
            end else begin
                $display("[FAIL] %s | check_bit = %0b (Mong doi: %0b)", 
                         test_name, check_bit, expected_bit);
                fail_count++;
            end
        end

        // Nghỉ 2 chu kỳ trước test tiếp theo
        repeat(2) @(posedge clk);
    endtask

    // -------------------------------------------------------------
    // Kịch bản kiểm thử (Stimulus)
    // -------------------------------------------------------------
    initial begin
        // Reset ban đầu
        rst_n        = 1'b0;
        start        = 1'b0;
        x            = '0;
        ccs          = '0;
        uniform_bits = '0;

        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        $display("=================================================");
        $display("       BAT DAU TESTBENCH FALCON BER_EXP          ");
        $display("=================================================");

        // Test 1: Điểm biên x = 0, ccs = 1.0 (s = 0, r = 0, ApproxExp ra y = 2^63)
        // z = 2y - 1 = 64'hFFFF_FFFF_FFFF_FFFF => z[63:56] = 8'hFF
        // uniform_bits = 8'h80 < 8'hFF => Mong đợi: 1
        run_ber_test(
            "Test 1: x = 0, ccs = 1.0, rand < z_byte",
            64'h0000_0000_0000_0000,
            64'h8000_0000_0000_0000,
            8'h80,
            1'b1
        );

        // Test 2: x = 0.5 (Q8.56 = 64'h0080_0000_0000_0000), ccs = 1.0
        // s = 0, r = 0.5 => z[63:56] = 8'h9B
        // 2a. uniform_bits = 8'h50 (< 8'h9B) => Mong đợi: 1
        run_ber_test(
            "Test 2a: x = 0.5, rand < z_byte",
            64'h0080_0000_0000_0000,
            64'h8000_0000_0000_0000,
            8'h50,
            1'b1
        );

        // 2b. uniform_bits = 8'hC0 (> 8'h9B) => Mong đợi: 0
        run_ber_test(
            "Test 2b: x = 0.5, rand > z_byte",
            64'h0080_0000_0000_0000,
            64'h8000_0000_0000_0000,
            8'hC0,
            1'b0
        );

        // Test 3: x = 1.0 (Q8.56 = 64'h0100_0000_0000_0000), ccs = 1.0
        // s = 1, r = 1.0 - ln(2) = 0.30685 => z = (2y - 1) >> 1 => z[63:56] = 8'h5E
        // 3a. uniform_bits = 8'h30 (< 8'h5E) => Mong đợi: 1
        run_ber_test(
            "Test 3a: x = 1.0, s = 1, rand < z_byte",
            64'h0100_0000_0000_0000,
            64'h8000_0000_0000_0000,
            8'h30,
            1'b1
        );

        // 3b. uniform_bits = 8'h70 (> 8'h5E) => Mong đợi: 0
        run_ber_test(
            "Test 3b: x = 1.0, s = 1, rand > z_byte",
            64'h0100_0000_0000_0000,
            64'h8000_0000_0000_0000,
            8'h70,
            1'b0
        );

        // Test 4: Điểm biên x rất lớn (x = 44.0 >= 63*ln2 -> s >= 63)
        // z bị dịch phải 63 bit => z[63:56] = 8'h00
        // Mọi uniform_bits > 0 đều trả về 0
        run_ber_test(
            "Test 4: x = 44 (s >= 63, z ~ 0), rand = 0x05",
            64'h2C00_0000_0000_0000, // 44 ở dạng Q8.56
            64'h8000_0000_0000_0000,
            8'h05,
            1'b0
        );

        $display("=================================================");
        $display(" KET QUA: PASS = %0d / %0d | FAIL = %0d", pass_count, test_count, fail_count);
        $display("=================================================");

        $finish;
    end

endmodule