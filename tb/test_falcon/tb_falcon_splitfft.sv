`timescale 1ns / 1ps

`include "falcon_header.svh"

module tb_falcon_splitfft;

    // -------------------------------------------------------------
    // 1. Tín hiệu kết nối DUT
    // -------------------------------------------------------------
    logic                       clk;
    logic                       rst_n;
    logic                       valid;
    logic [`FPU_STAND - 1 : 0]  a_real;
    logic [`FPU_STAND - 1 : 0]  a_im;
    logic [`FPU_STAND - 1 : 0]  b_real;
    logic [`FPU_STAND - 1 : 0]  b_im;
    logic [`FPU_STAND - 1 : 0]  w_real;
    logic [`FPU_STAND - 1 : 0]  w_im;

    logic [`FPU_STAND - 1 : 0]  f0_real;
    logic [`FPU_STAND - 1 : 0]  f0_im;
    logic [`FPU_STAND - 1 : 0]  f1_real;
    logic [`FPU_STAND - 1 : 0]  f1_im;
    logic                       valid_o;

    // -------------------------------------------------------------
    // 2. Khởi tạo DUT (Device Under Test)
    // -------------------------------------------------------------
    falcon_splitfft dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid    (valid),
        .a_real   (a_real),
        .a_im     (a_im),
        .b_real   (b_real),
        .b_im     (b_im),
        .w_real   (w_real),
        .w_im     (w_im),
        .f0_real  (f0_real),
        .f0_im    (f0_im),
        .f1_real  (f1_real),
        .f1_im    (f1_im),
        .valid_o  (valid_o)
    );

    // -------------------------------------------------------------
    // 3. Tạo xung Clock (Chu kỳ 10ns = 100MHz)
    // -------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------
    // 4. Hàm so sánh số thực dấu phẩy động (cho phép sai số epsilon)
    // -------------------------------------------------------------
    function automatic bit is_close(real val, real expected, real eps = 1e-5);
        real diff;
        diff = (val >= expected) ? (val - expected) : (expected - val);
        return (diff <= eps);
    endfunction

    // -------------------------------------------------------------
    // 5. Task gửi 1 mẫu cánh bướm và tự động kiểm tra kết quả
    // -------------------------------------------------------------
    task automatic test_butterfly(
        input string test_name,
        input real ar, input real ai,   // A = f(ζ)
        input real br, input real bi,   // B = f(-ζ)
        input real wr, input real wi    // W = 1 / (2*ζ)
    );
        real exp_f0_r, exp_f0_i;
        real sub_r, sub_i;
        real exp_f1_r, exp_f1_i;
        real act_f0_r, act_f0_i;
        real act_f1_r, act_f1_i;
        int  timeout_cnt;

        // Mô hình toán tham chiếu:
        // f0 = (A + B) / 2
        exp_f0_r = (ar + br) * 0.5;
        exp_f0_i = (ai + bi) * 0.5;

        // f1 = (A - B) * W  (với W = 1 / 2ζ)
        sub_r    = ar - br;
        sub_i    = ai - bi;
        exp_f1_r = sub_r * wr - sub_i * wi;
        exp_f1_i = sub_r * wi + sub_i * wr;

        // Đẩy dữ liệu vào DUT theo sườn xung clock
        @(posedge clk);
        valid  <= 1'b1;
        a_real <= $realtobits(ar);
        a_im   <= $realtobits(ai);
        b_real <= $realtobits(br);
        b_im   <= $realtobits(bi);
        w_real <= $realtobits(wr);
        w_im   <= $realtobits(wi);

        @(posedge clk);
        valid  <= 1'b0; // Hạ xung valid sau 1 chu kỳ

        // Chờ kết quả valid_o từ DUT (hỗ trợ pipeline nhiều chu kỳ)
        timeout_cnt = 0;
        while (!valid_o && timeout_cnt < 200) begin
            @(posedge clk);
            timeout_cnt++;
        end

        if (!valid_o) begin
            $display("[FAIL] %s: Timeout! Khong nhan duoc tin hieu valid_o.", test_name);
            $finish;
        end

        // Đọc giá trị ngõ ra từ DUT và đổi ngược về số thực
        act_f0_r = $bitstoreal(f0_real);
        act_f0_i = $bitstoreal(f0_im);
        act_f1_r = $bitstoreal(f1_real);
        act_f1_i = $bitstoreal(f1_im);

        // Hiển thị thông tin kiểm tra
        $display("-----------------------------------------------------------------");
        $display("Kiem tra: %s (Do tre: %0d chu ky)", test_name, timeout_cnt);
        $display("  Dau vao A   : %f + %fi", ar, ai);
        $display("  Dau vao B   : %f + %fi", br, bi);
        $display("  He so xoay W: %f + %fi", wr, wi);
        $display("  f0 (Expected): %f + %fi", exp_f0_r, exp_f0_i);
        $display("  f0 (Actual)  : %f + %fi", act_f0_r, act_f0_i);
        $display("  f1 (Expected): %f + %fi", exp_f1_r, exp_f1_i);
        $display("  f1 (Actual)  : %f + %fi", act_f1_r, act_f1_i);

        // Đánh giá sai số
        if (is_close(act_f0_r, exp_f0_r) && is_close(act_f0_i, exp_f0_i) &&
            is_close(act_f1_r, exp_f1_r) && is_close(act_f1_i, exp_f1_i)) begin
            $display("===> KET QUA: [PASS]");
        end else begin
            $display("===> KET QUA: [FAIL] - Sai lech vuot qua nguong cho phep!");
        end
        $display("-----------------------------------------------------------------");

        // Nghỉ 2 chu kỳ giữa các test case
        repeat(2) @(posedge clk);
    endtask

    // -------------------------------------------------------------
    // 6. Kịch bản chạy mô phỏng (Test Cases)
    // -------------------------------------------------------------
    initial begin
        // Reset hệ thống
        rst_n  = 1'b0;
        valid  = 1'b0;
        a_real = '0; a_im   = '0;
        b_real = '0; b_im   = '0;
        w_real = '0; w_im   = '0;

        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        // TEST CASE 1: Ví dụ số học ta vừa thảo luận
        // A = 3 + 4i, B = 1 + 2i
        // zeta = sqrt(2)/2 + i*sqrt(2)/2
        // W = 1 / (2*zeta) = (sqrt(2)/4) - i*(sqrt(2)/4)
        test_butterfly(
            "Test 1: Vi du so hoc co ban",
            3.0, 4.0,                                   // A
            1.0, 2.0,                                   // B
            0.3535533905932738, -0.3535533905932738     // W = 1 / 2*zeta
        );

        // TEST CASE 2: Trường hợp A = B
        // Khi A = B thì f0 = A, f1 = 0
        test_butterfly(
            "Test 2: A bang B (f1 phai triet tieu ve 0)",
            5.5, -2.25,                                 // A
            5.5, -2.25,                                 // B
            0.5, 0.0                                    // W tuy y
        );

        // TEST CASE 3: Trường hợp A = -B
        // Khi A = -B thì f0 = 0, f1 = (2A) * W
        test_butterfly(
            "Test 3: A doi dau B (f0 phai triet tieu ve 0)",
            4.0, 2.0,                                   // A
            -4.0, -2.0,                                 // B
            0.25, 0.5                                   // W
        );

        $display("\n>>> HOAN TAT TAT CA CAC TEST CASE <<<\n");
        $finish;
    end

endmodule