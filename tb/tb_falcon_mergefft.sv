`timescale 1ns / 1ps

`include "falcon_header.svh"

module tb_falcon_mergefft;

    // -------------------------------------------------------------
    // 1. Tín hiệu kết nối DUT
    // -------------------------------------------------------------
    logic                       clk;
    logic                       rst_n;
    logic                       start;
    logic [`FPU_STAND - 1 : 0]  f0_real;
    logic [`FPU_STAND - 1 : 0]  f0_im;
    logic [`FPU_STAND - 1 : 0]  f1_real;
    logic [`FPU_STAND - 1 : 0]  f1_im;
    logic [`FPU_STAND - 1 : 0]  zeta_real;
    logic [`FPU_STAND - 1 : 0]  zeta_im;

    logic [`FPU_STAND - 1 : 0]  f_real;
    logic [`FPU_STAND - 1 : 0]  f_im;
    logic                       valid_o;

    // -------------------------------------------------------------
    // 2. Khởi tạo DUT (Device Under Test)
    // -------------------------------------------------------------
    falcon_mergefft dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .f0_real   (f0_real),
        .f0_im     (f0_im),
        .f1_real   (f1_real),
        .f1_im     (f1_im),
        .zeta_real (zeta_real),
        .zeta_im   (zeta_im),
        .f_real    (f_real),
        .f_im      (f_im),
        .valid_o   (valid_o)
    );

    // -------------------------------------------------------------
    // 3. Bộ tạo xung nhịp Clock (100 MHz, chu kỳ 10ns)
    // -------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------
    // 4. Hàm so sánh số thực dấu phẩy động (dung sai epsilon)
    // -------------------------------------------------------------
    function automatic bit is_close(real val, real expected, real eps = 1e-5);
        real diff;
        diff = (val >= expected) ? (val - expected) : (expected - val);
        return (diff <= eps);
    endfunction

    // -------------------------------------------------------------
    // 5. Task nạp dữ liệu và kiểm tra kết quả ngõ ra
    // -------------------------------------------------------------
    task automatic test_merge(
        input string test_name,
        input real f0_r, input real f0_i,       // f0(ζ^2)
        input real f1_r, input real f1_i,       // f1(ζ^2)
        input real z_r,  input real z_i        // ζ
    );
        real mul_r, mul_i;
        real exp_f_r, exp_f_i;
        real act_f_r, act_f_i;
        int  timeout_cnt;

        // Mô hình toán tham chiếu: f(ζ) = f0 + ζ * f1
        // Bước 1: Nhân số phức mul = ζ * f1
        mul_r = (z_r * f1_r) - (z_i * f1_i);
        mul_i = (z_r * f1_i) + (z_i * f1_r);

        // Bước 2: Cộng số phức exp_f = f0 + mul
        exp_f_r = f0_r + mul_r;
        exp_f_i = f0_i + mul_i;

        // Đẩy tín hiệu kích thích vào DUT
        @(posedge clk);
        start     <= 1'b1;
        f0_real   <= $realtobits(f0_r);
        f0_im     <= $realtobits(f0_i);
        f1_real   <= $realtobits(f1_r);
        f1_im     <= $realtobits(f1_i);
        zeta_real <= $realtobits(z_r);
        zeta_im   <= $realtobits(z_i);

        @(posedge clk);
        start     <= 1'b0; // Hạ start sau 1 chu kỳ clock

        // Chờ phản hồi valid_o (hỗ trợ pipeline nhiều chu kỳ)
        timeout_cnt = 0;
        while (!valid_o && timeout_cnt < 200) begin
            @(posedge clk);
            timeout_cnt++;
        end

        if (!valid_o) begin
            $display("[FAIL] %s: Timeout! Khong nhan duoc tin hieu valid_o.", test_name);
            $finish;
        end

        // Thu nhận kết quả từ DUT
        act_f_r = $bitstoreal(f_real);
        act_f_i = $bitstoreal(f_im);

        // Hiển thị báo cáo chi tiết
        $display("-----------------------------------------------------------------");
        $display("Kiem tra: %s (Do tre pipeline: %0d chu ky)", test_name, timeout_cnt);
        $display("  Dau vao f0     : %f + %fi", f0_r, f0_i);
        $display("  Dau vao f1     : %f + %fi", f1_r, f1_i);
        $display("  He so xoay zeta: %f + %fi", z_r, z_i);
        $display("  Ket qua ky vong (Expected) : %f + %fi", exp_f_r, exp_f_i);
        $display("  Ket qua thuc te (Actual)   : %f + %fi", act_f_r, act_f_i);

        // Đánh giá sai số
        if (is_close(act_f_r, exp_f_r) && is_close(act_f_i, exp_f_i)) begin
            $display("===> KET QUA: [PASS]");
        end else begin
            $display("===> KET QUA: [FAIL] - Sai lech vuot qua nguong cho phep!");
        end
        $display("-----------------------------------------------------------------");

        // Giãn cách 2 chu kỳ giữa các lần test
        repeat(2) @(posedge clk);
    endtask

    // -------------------------------------------------------------
    // 6. Kịch bản kiểm thử (Test Cases)
    // -------------------------------------------------------------
    initial begin
        // Khởi tạo và Reset hệ thống
        rst_n     = 1'b0;
        start     = 1'b0;
        f0_real   = '0; f0_im   = '0;
        f1_real   = '0; f1_im   = '0;
        zeta_real = '0; zeta_im = '0;

        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(3) @(posedge clk);

        // =========================================================
        // TEST CASE 1: Khôi phục lại điểm u = 3 + 4i từ splitfft
        // Ở bài toán trước: f0 = 2 + 3i, f1 = sqrt(2), zeta = sqrt(2)/2 + i*sqrt(2)/2
        // Kết quả mong đợi: f(zeta) = 3.0 + 4.0i
        // =========================================================
        test_merge(
            "Test 1: Khoi phuc u = 3 + 4i (Kiem tra nguoc splitfft)",
            2.0, 3.0,                                   // f0 = 2 + 3i
            1.4142135623730951, 0.0,                    // f1 = sqrt(2)
            0.7071067811865476, 0.7071067811865476      // zeta = sqrt(2)/2 + i*sqrt(2)/2
        );

        // =========================================================
        // TEST CASE 2: Khôi phục lại điểm v = 1 + 2i với -zeta
        // zeta_neg = -sqrt(2)/2 - i*sqrt(2)/2
        // Kết quả mong đợi: f(-zeta) = 1.0 + 2.0i
        // =========================================================
        test_merge(
            "Test 2: Khoi phuc v = 1 + 2i voi -zeta",
            2.0, 3.0,                                   // f0 = 2 + 3i
            1.4142135623730951, 0.0,                    // f1 = sqrt(2)
            -0.7071067811865476, -0.7071067811865476    // -zeta
        );

        // =========================================================
        // TEST CASE 3: Đa thức bậc 3 tổng quát: f(x) = 1 + 2x + 3x^2 + 4x^3
        // f0 = 1 + 3i, f1 = 2 + 4i, zeta = sqrt(2)/2 + i*sqrt(2)/2
        // Kết quả mong đợi: f(zeta) ≈ -0.414214 + 7.242641i
        // =========================================================
        test_merge(
            "Test 3: Da thuc tong quat tai zeta_0",
            1.0, 3.0,                                   // f0
            2.0, 4.0,                                   // f1
            0.7071067811865476, 0.7071067811865476      // zeta
        );

        // =========================================================
        // TEST CASE 4: Điểm đối xứng với -zeta của Test 3
        // Kết quả mong đợi: f(-zeta) ≈ 2.414214 - 1.242641i
        // =========================================================
        test_merge(
            "Test 4: Da thuc tong quat tai -zeta_0",
            1.0, 3.0,                                   // f0
            2.0, 4.0,                                   // f1
            -0.7071067811865476, -0.7071067811865476    // -zeta
        );

        // =========================================================
        // TEST CASE 5: Biên zero (f1 = 0 => f = f0)
        // =========================================================
        test_merge(
            "Test 5: f1 = 0 (f phai bang f0)",
            7.5, -4.25,                                 // f0
            0.0, 0.0,                                   // f1 = 0
            0.5, 0.8660254                              // zeta bat ky
        );

        $display("\n>>> HOAN TAT TAT CA CAC TEST CASE CHO MERGEFFT <<<\n");
        $finish;
    end

endmodule