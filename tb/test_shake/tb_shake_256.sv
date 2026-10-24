`timescale 1ns / 1ps

module tb_shake_256;

    // -------------------------------------------------------------------------
    // 1. Tham số & Tín hiệu kết nối DUT
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD     = 10;   // 10ns = 100 MHz
    localparam TIMEOUT_CYCLES = 2000; // Ngưỡng timeout tối đa

    logic           clk;
    logic           rst_n;
    logic           start;
    logic [383:0]   seed;
    logic [1087:0]  hash;
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
    // 3. Tạo Clock
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // 4. Tasks hỗ trợ
    // -------------------------------------------------------------------------

    // Task Reset DUT: Kéo rst_n xuống 0 trong 5 chu kỳ rồi nhả về 1
    task automatic apply_reset();
        @(posedge clk);
        rst_n <= 1'b0;
        start <= 1'b0;
        seed  <= '0;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n <= 1'b1;
        repeat (2) @(posedge clk);
    endtask

    // Task in giá trị 1088-bit dạng Hex và từng Lane 64-bit
    task automatic display_hash(input [1087:0] h);
        $display("------------------- Squeezed 1088-bit Output -------------------");
        $display("  Hex Output : 0x%0272h", h);
        for (int i = 0; i < 17; i++) begin
            $display("  Lane [%02d] (bits %4d:%4d) = 0x%016h", 
                     i, (1087 - i*64), (1087 - i*64 - 63), h[1087 - i*64 -: 64]);
        end
        $display("----------------------------------------------------------------\n");
    endtask

    // Task thực thi testcase: Luôn RESET DUT trước khi kích START
    task automatic run_testcase(
        input string         tc_name,
        input [383:0]        in_seed,
        input bit            check_expected = 1'b0,
        input [1087:0]       exp_hash       = '0
    );
        int cycle_cnt;
        cycle_cnt = 0;

        $display("================================================================");
        $display("[INFO] Chạy Testcase: %s", tc_name);
        $display("  Input Seed (384-bit): 0x%096h", in_seed);

        // 1. Reset DUT trước khi bắt đầu
        apply_reset();

        // 2. Nạp Seed và kích xung Start đúng 1 chu kỳ clock
        @(posedge clk);
        seed  <= in_seed;
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
        seed  <= '0; // Clear seed sau khi DUT đã nhận

        // 3. Giám sát cờ Done kèm watchdog timeout
        while (!done) begin
            @(posedge clk);
            cycle_cnt++;
            if (cycle_cnt > TIMEOUT_CYCLES) begin
                $display("[ERROR] TIMEOUT! Module không trả cờ done sau %0d chu kỳ.", TIMEOUT_CYCLES);
                $stop;
            end
        end

        $display("[SUCCESS] Hoàn thành sau %0d chu kỳ clock.", cycle_cnt);
        display_hash(hash);

        // 4. So sánh kết quả nếu có cấu hình giá trị kỳ vọng
        if (check_expected) begin
            if (hash === exp_hash) begin
                $display("===> KẾT QUẢ: [PASS] Trùng khớp 100%% với vector chuẩn NIST!\n");
            end else begin
                $display("===> KẾT QUẢ: [FAIL] Lệch kết quả!");
                $display("  Kỳ vọng (Exp): 0x%0272h", exp_hash);
                $display("  Thực tế (Act): 0x%0272h\n", hash);
            end
        end

        repeat (5) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // 5. Kịch bản kiểm thử (Test Scenarios)
    // -------------------------------------------------------------------------
    initial begin
        // Trạng thái ban đầu
        rst_n = 1'b0;
        start = 1'b0;
        seed  = '0;

        // Chờ hệ thống ổn định trước khi chạy
        repeat (3) @(posedge clk);

        // TEST CASE 1: Seed toàn 0 (48 bytes 0x00) - Tự động đối chiếu vector chuẩn NIST
        run_testcase(
            .tc_name        ("TC1: Seed All-Zeros"),
            .in_seed        (384'h0),
            .check_expected (1'b1),
            .exp_hash       (1088'heda313c95591a023a5b37f361c07a5753a92d3d0427459f34c7895d727d62816b3aa2224eb9d823127d4f9f8a30fd7a1a02c6483d9c0f1fd41957b9ae4dfc63a3191da3442686282b3d5160f25cf162a517fd2131f83fbf2698a58f9c46afc5df74a686f5cd121749cd41fdac5ef39ec074e8a53f1d0b42314deb6ffcc684b7c28e19cb6c0b2decd)
        );

        // TEST CASE 2: Seed tăng dần từng byte (0x01, 0x02, ..., 0x30)
        run_testcase(
            .tc_name        ("TC2: Sequential Pattern Bytes"),
            .in_seed        (384'h0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f30)
        );

        // TEST CASE 3: Seed mẫu Entropy giả ngẫu nhiên
        run_testcase(
            .tc_name        ("TC3: Pseudo-random Entropy Seed"),
            .in_seed        (384'hA5A5A5A5_5A5A5A5A_01234567_89ABCDEF_FEDCBA98_76543210_DEADBEEF_CAFEBABE_11223344_55667788_99AABBCC_DDEEFF00)
        );

        $display("================ HOÀN TẤT TẤT CẢ TESTCASE ================\n");
        $finish;
    end

    // Ghi file VCD phục vụ debug waveform (GTKWave / Vivado Logic Simulator)
    initial begin
        $dumpfile("tb_shake_256.vcd");
        $dumpvars(0, tb_shake_256);
    end

endmodule