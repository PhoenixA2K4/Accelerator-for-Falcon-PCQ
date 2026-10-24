`timescale 1ns / 1ps

module tb_shake_256;

    // -------------------------------------------------------------------------
    // 1. Tham số & Tín hiệu giao tiếp DUT
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD = 10; // Chu kỳ xung nhịp 10ns (100 MHz)
    localparam TIMEOUT_CYCLES = 1000;

    logic           clk;
    logic           rst_n;
    logic           start;
    logic [383:0]   seed;
    logic [1599:0]  hash;
    logic           done;

    // -------------------------------------------------------------------------
    // 2. Khởi tạo DUT (Device Under Test)
    // -------------------------------------------------------------------------
    shake_256 dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .seed   (seed),
        .hash   (hash),
        .done   (done)
    );

    // -------------------------------------------------------------------------
    // 3. Bộ tạo Clock
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // 4. Tasks hỗ trợ mô phỏng
    // -------------------------------------------------------------------------
    
    // Task reset hệ thống
    task automatic reset_dut();
        rst_n = 1'b0;
        start = 1'b0;
        seed  = '0;
        repeat (5) @(posedge clk);
        #(CLK_PERIOD / 4);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
    endtask

    // Task in giá trị 1088-bit ra định dạng 17 lanes (mỗi lane 64-bit)
    task automatic display_hash(input [1087:0] h);
        $display("------------------- Squeezed 1088-bit Output (17 Lanes) -------------------");
        for (int i = 0; i < 17; i++) begin
            $display("  Lane [%02d] (bits %4d:%4d) = 0x%016h", 
                     i, (i*64 + 63), (i*64), h[i*64 +: 64]);
        end
        $display("  Raw Hex: 0x%0272h", h);
        $display("---------------------------------------------------------------------------\n");
    endtask

    // Task thực thi và giám sát 1 phiên băm SHAKE-256
    task automatic run_testcase(
        input string       tc_name,
        input [383:0]      in_seed
    );
        int cycle_cnt;
        cycle_cnt = 0;

        $display("[INFO] Start testcase: %s", tc_name);
        $display("  Input Seed (384-bit): 0x%096h", in_seed);

        // Đặt dữ liệu và kích hoạt start 1 chu kỳ
        @(posedge clk);
        seed  <= in_seed;
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
        seed  <= '0; // Xóa bus dữ liệu sau khi nạp

        // Chờ cờ done với cơ chế watchdog chống treo mô phỏng
        fork
            begin
                while (!done) begin
                    @(posedge clk);
                    cycle_cnt++;
                    if (cycle_cnt > TIMEOUT_CYCLES) begin
                        $display("[ERROR] TIMEOUT! Module not return done flag after %0d clock.", TIMEOUT_CYCLES);
                        $stop;
                    end
                end
                $display("[SUCCESS] Complete in %0d clock.", cycle_cnt);
                display_hash(hash);
            end
        join

        repeat (3) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // 5. Kịch bản kiểm thử chính (Stimulus)
    // -------------------------------------------------------------------------
    initial begin
        $display("\n================ INIT TESTBENCH SHAKE-256 ================\n");

        reset_dut();

        // Test Case 1: Seed toàn 0 (48 bytes 0x00)
        run_testcase(
            "TC1: Seed All-Zeros",
            384'h0
        );

        // Test Case 2: Seed có quy luật tăng dần từng byte (0x01, 0x02, ..., 0x30)
        run_testcase(
            "TC2: Sequential Pattern Bytes",
            384'h0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f30
        );

        // Test Case 3: Seed mẫu kiểm thử giả ngẫu nhiên
        run_testcase(
            "TC3: Pseudo-random Entropy Seed",
            384'hA5A5A5A5_5A5A5A5A_01234567_89ABCDEF_FEDCBA98_76543210_DEADBEEF_CAFEBABE_11223344_55667788_99AABBCC_DDEEFF00
        );

        $display("================ COMPLETE TESTCASE ================\n");
        $finish;
    end

    // Ghi file waveform VCD để debug đồ họa (nếu dùng Icarus Verilog hoặc GTKWave)
    initial begin
        $dumpfile("tb_shake_256.vcd");
        $dumpvars(0, tb_shake_256);
    end

endmodule