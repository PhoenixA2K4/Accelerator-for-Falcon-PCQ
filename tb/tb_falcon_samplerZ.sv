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
 *    Create Date : Sep 1st 2026
 *    Last Update : Sep 1st 2026
 *    Description : Testbench for 
 ******************************************************************************
  History:

 ******************************************************************************/

// `include "falcon_header.svh"

// module tb_falcon_samplerZ;

//     // -------------------------------------------------------------
//     // Giao tiếp DUT
//     // -------------------------------------------------------------
//     logic                                            clk;
//     logic                                            rst_n;
//     logic                                            start;
//     logic                                            done;
//     logic                                            request;
//     logic [`FPU_STAND - 1 : 0]                       o_dot; // FP64
//     logic [`FPU_STAND - 1 : 0]                       mu;    // FP64
//     logic [`FALCON_UNIFORM_BITS_SAMPLERZ - 1 : 0]    uniform_bits;
//     logic signed [`FALCON_Z - 1 : 0]                 z;

//     int test_count = 0;
//     int pass_count = 0;
//     int fail_count = 0;

//     byte unsigned rand_mem [0 : 127];
//     int rand_ptr = 0;

//     // -------------------------------------------------------------
//     // Khởi tạo DUT
//     // -------------------------------------------------------------
//     falcon_samplerZ dut (
//         .clk          (clk),
//         .rst_n        (rst_n),
//         .start        (start),
//         .done         (done),
//         .request      (request),
//         .o_dot        (o_dot),
//         .mu           (mu),
//         .uniform_bits (uniform_bits),
//         .z            (z)
//     );

//     // Clock 100MHz (Chu kỳ 10ns)
//     initial clk = 0;
//     always #5 clk = ~clk;

//     // -------------------------------------------------------------
//     // Nạp stream byte chuẩn theo logic của bạn:
//     // [71 : 0]  : 9 byte cho BaseSampler (Big-Endian)
//     // [72]      : bit b (bit 0 của byte thứ 10)
//     // [87 : 80] : 1 byte cho BerExp (byte thứ 11)
//     // -------------------------------------------------------------
//     always_ff @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             uniform_bits <= '0;
//         end else if (request) begin
//             // 9 byte cấp cho BaseSampler theo chuẩn Big-Endian: byte đọc trước nằm ở bit cao [71:64]
//             for (int i = 0; i < 9; i++) begin
//                 uniform_bits[(8 - i)*8 +: 8] <= rand_mem[rand_ptr + i];
//             end
            
//             // Bit dấu b lấy từ bit 0 của byte thứ 10
//             uniform_bits[72] <= rand_mem[rand_ptr + 9][0];
            
//             // Byte cho BerExp
//             uniform_bits[87 : 80] <= rand_mem[rand_ptr + 10];

//             rand_ptr <= rand_ptr + 11;
//         end
//     end

//     // -------------------------------------------------------------
//     // Task chạy kiểm thử từng vector
//     // -------------------------------------------------------------
//     task automatic run_kat(
//         input string       test_id,
//         input logic [63:0] in_mu_fp64,
//         input logic [63:0] in_sigma_fp64,
//         input byte unsigned stream[],
//         input int          expected_z
//     );
//         int timeout = 0;
//         test_count++;
//         rand_ptr = 0;

//         for (int i = 0; i < stream.size(); i++) begin
//             rand_mem[i] = stream[i];
//         end

//         @(posedge clk);
//         mu    <= in_mu_fp64;
//         o_dot <= in_sigma_fp64;
//         start <= 1'b1;

//         @(posedge clk);
//         start <= 1'b0;

//         fork
//             begin
//                 @(posedge done);
//             end
//             begin
//                 while (!done && timeout < 4000) begin
//                     @(posedge clk);
//                     timeout++;
//                 end
//                 if (!done) begin
//                     $display("\n[TIMEOUT] %s: DUT bi treo hoac khong thoat loop!", test_id);
//                     fail_count++;
//                     disable fork;
//                 end
//             end
//         join_any
//         disable fork;

//         if (done) begin
//             #1;
//             if (z === expected_z) begin
//                 $display("[PASS] %s | Output z = %0d (Expected: %0d)", test_id, z, expected_z);
//                 pass_count++;
//             end else begin
//                 $display("[FAIL] %s | Output z = %0d (Expected: %0d)", test_id, z, expected_z);
//                 fail_count++;
//             end
//         end

//         repeat(5) @(posedge clk);
//     endtask

//     // -------------------------------------------------------------
//     // Kịch bản kiểm thử: Đầy đủ 16 mẫu trích từ Table 3.2
//     // -------------------------------------------------------------
//     initial begin
//         rst_n = 1'b0;
//         start = 1'b0;
//         mu    = '0;
//         o_dot = '0;

//         repeat(5) @(posedge clk);
//         rst_n = 1'b1;
//         repeat(5) @(posedge clk);

//         $display("=================================================");
//         $display("   VERIFY DU 16 TEST VECTOR FALCON SAMPLERZ      ");
//         $display("=================================================");

//         // Test 1: mu = -91.90471153063714 | sigma' = 1.7037990414754918 (2 iterations)
//         run_kat("Test 1", 64'hC056F9E6CB3119A4, 64'h3FFB42C2C8A17E81,
//             '{8'h0f, 8'hc5, 8'h44, 8'h2f, 8'hf0, 8'h43, 8'hd6, 8'h6e, 8'h91, 8'hd1, 8'hea,
//               8'hca, 8'hc6, 8'h4e, 8'ha5, 8'h45, 8'h0a, 8'h22, 8'h94, 8'h1e, 8'hdc, 8'h6c},
//             -92
//         );

//         // Test 2: mu = -8.322564895434937 | sigma' = 1.7037990414754918 (2 iterations)
//         run_kat("Test 2", 64'hc020a52796443c7b, 64'h3FFB42C2C8A17E81,
//             '{8'hf4, 8'hda, 8'h0f, 8'h8d, 8'h84, 8'h44, 8'hd1, 8'ha7, 8'h72, 8'h65, 8'hc2,
//               8'hef, 8'h6f, 8'h98, 8'hbb, 8'hbb, 8'h4b, 8'hee, 8'h7d, 8'hb8, 8'hd9, 8'hb3},
//             -8
//         );

//         // Test 3: mu = -19.096516109216804 | sigma' = 1.7035823083824078 (2 iterations)
//         run_kat("Test 3", 64'hC03318B5479C9F93, 64'h3FFB41DF85C8BEFD,
//             '{8'hdb, 8'h47, 8'hf6, 8'hd7, 8'hfb, 8'h9b, 8'h19, 8'hf2, 8'h5c, 8'h36, 8'hd6,
//               8'hb9, 8'h33, 8'h4d, 8'h47, 8'h7a, 8'h8b, 8'hc0, 8'hbe, 8'h68, 8'h14, 8'h5d},
//             -20
//         );


//         // Test 4: mu = -11.335543982423326 | sigma' = 1.7035823083824078 -> z = -12
//         run_kat("Test 4", 64'hC026ABCC6BBDC16D, 64'h3FFB41DF85C8BEFD,
//             '{8'hae, 8'h41, 8'hb4, 8'hf5, 8'h20, 8'h96, 8'h65, 8'hc7, 8'h4d, 8'h00, 8'hdc,
//               8'hc1, 8'ha8, 8'h16, 8'h8a, 8'h7b, 8'hb5, 8'h16, 8'hb3, 8'h19, 8'h0c, 8'hb4,
//               8'h2c, 8'h1d, 8'hed, 8'h26, 8'hcd, 8'h52, 8'hae, 8'hd7, 8'h70, 8'hec, 8'ha7,
//               8'hdd, 8'h33, 8'h4e, 8'h05, 8'h47, 8'hbc, 8'hc3, 8'hc1, 8'h63, 8'hce, 8'h0b},
//             -12);

//         // Test 5: mu = 7.9386734193997555 | sigma' = 1.6984647769450156 -> z = 8
//         run_kat("Test 5", 64'h401FC1339AD7C928, 64'h3FFB2CE966E6303D,
//             '{8'h31, 8'h05, 8'h41, 8'h66, 8'hc1, 8'h01, 8'h27, 8'h80, 8'hc6, 8'h03, 8'hae,
//               8'h9b, 8'h83, 8'h3c, 8'hec, 8'h73, 8'hf2, 8'hf4, 8'h1c, 8'ha5, 8'h80, 8'h7c,
//               8'hc8, 8'h9c, 8'h92, 8'h15, 8'h88, 8'h34, 8'h63, 8'h2f, 8'h9b, 8'h15, 8'h55},
//             8);

//         // Test 6: mu = -28.990850086867255 | sigma' = 1.6984647769450156 (1 iteration)
//         run_kat("Test 6", 64'hC03CFDA859EE5568, 64'h3FFB2CE966E6303D,
//             '{8'h73, 8'h7e, 8'h9d, 8'h68, 8'ha5, 8'h0a, 8'h06, 8'hdb, 8'hbc, 8'h64, 8'h77},
//             -30
//         );

//         // Test 7: mu = -9.071257914091655 | sigma' = 1.6980782114808988 (1 iteration)
//         run_kat("Test 7", 64'hC022247BEAD535AD, 64'h3FFB2B540F05C526,
//             '{8'ha9, 8'h8d, 8'hdd, 8'h14, 8'hbf, 8'h0b, 8'hf2, 8'h20, 8'h61, 8'hd6, 8'h32},
//             -10
//         );

//         // Test 8: mu = -43.88754568839566 | sigma' = 1.6980782114808988 (1 iteration)
//         run_kat("Test 8", 64'hC045F19B18DCAEBE, 64'h3FFB2B540F05C526,
//             '{8'h3c, 8'hbf, 8'h68, 8'h18, 8'ha6, 8'h8f, 8'h7a, 8'hb9, 8'h99, 8'h15, 8'h14},
//             -41
//         );


//         // Test 9: mu = -58.17435547946095 | sigma' = 1.7010983419195522 -> z = -61
//         // Iteration 1 dung 11 byte; Iteration 2 dung 12 byte (BerExp dung 2 byte: 58 7c)
//         run_kat("Test 9", 64'hC04D165147C514E3, 64'h3FFB37B2E51D3058,
//             '{8'h6f, 8'h86, 8'h33, 8'hf5, 8'hbf, 8'ha5, 8'hd2, 8'h68, 8'h48, 8'h66, 8'h8e,
//               8'h3d, 8'h5d, 8'hdd, 8'h46, 8'h95, 8'h8e, 8'h97, 8'h63, 8'h04, 8'h10, 8'h58, 8'h7c},
//             -61);

//         // Test 10: mu = -43.58664906684732 | sigma' = 1.7010983419195522 -> z = -46
//         run_kat("Test 10", 64'hC045CB17510E2B49, 64'h3FFB37B2E51D3058,
//             '{8'h27, 8'h2b, 8'hc6, 8'hc2, 8'h5f, 8'h5c, 8'h5e, 8'he5, 8'h3f, 8'h83, 8'hc4,
//               8'h3a, 8'h36, 8'h1f, 8'hbc, 8'h7c, 8'hc9, 8'h1d, 8'hc7, 8'h83, 8'he2, 8'h0a},
//             -46);

//         // Test 11: mu = -34.70565203313315 | sigma' = 1.7009387219711465 -> z = -34
//         run_kat("Test 11", 64'hC0415A52CE4A54D6, 64'h3FFB370B8575DB97,
//             '{8'h45, 8'h44, 8'h3c, 8'h59, 8'h57, 8'h4c, 8'h2c, 8'h3b, 8'h07, 8'he2, 8'he1,
//               8'hd9, 8'h07, 8'h1e, 8'h6d, 8'h13, 8'h3d, 8'hbe, 8'h32, 8'h75, 8'h4b, 8'h0a},
//             -34);

//         // Test 12: mu = -44.36009577368896 | sigma' = 1.7009387219711465 -> z = -44
//         run_kat("Test 12", 64'hC0462E179E49B601, 64'h3FFB370B8575DB97,
//             '{8'h6a, 8'hc1, 8'h16, 8'hed, 8'h60, 8'hc2, 8'h58, 8'he2, 8'hcb, 8'hae, 8'hab,
//               8'h72, 8'h8c, 8'h48, 8'h23, 8'he6, 8'hda, 8'h36, 8'he1, 8'h8d, 8'h08, 8'hda,
//               8'h5d, 8'h0c, 8'hc1, 8'h04, 8'he2, 8'h1c, 8'hc7, 8'hfd, 8'h1f, 8'h5c, 8'ha8,
//               8'hd9, 8'hdb, 8'hb6, 8'h75, 8'h26, 8'h6c, 8'h92, 8'h84, 8'h48, 8'h05, 8'h9e},
//             -44);

//         // Test 13: mu = -21.783037079346236 | sigma' = 1.6958406126012802 -> z = -23
//         run_kat("Test 13", 64'hC035C8751E3758F2, 64'h3FFB2229C4259E1F,
//             '{8'h68, 8'h16, 8'h3b, 8'hc1, 8'he2, 8'hcb, 8'hf3, 8'he1, 8'h8e, 8'h74, 8'h26},
//             -23);

//         // Test 14: mu = -39.68827784633828 | sigma' = 1.6958406126012802 -> z = -40
//         run_kat("Test 14", 64'hC043D8197D0C4AC8, 64'h3FFB2229C4259E1F,
//             '{8'hd6, 8'ha1, 8'hb5, 8'h1d, 8'h76, 8'h22, 8'h2a, 8'h70, 8'h5a, 8'h02, 8'h59},
//             -40);

//         // Test 15: mu = -18.488607061056847 | sigma' = 1.6955259305261838 -> z = -22
//         run_kat("Test 15", 64'hC0327D155A33D576, 64'h3FFB20DFCC52142F,
//             '{8'hf0, 8'h52, 8'h3b, 8'hfa, 8'ha8, 8'ha3, 8'h94, 8'hbf, 8'h4e, 8'ha5, 8'hc1,
//               8'h0f, 8'h84, 8'h23, 8'h66, 8'hfd, 8'he2, 8'h86, 8'hd6, 8'ha3, 8'h08, 8'h03},
//             -22);

//         // Test 16: mu = -48.39610939101591 | sigma' = 1.6955259305261838 -> z = -50
//         run_kat("Test 16", 64'hC04832B3B66806A2, 64'h3FFB20DFCC52142F,
//             '{8'h87, 8'hbd, 8'h87, 8'he6, 8'h33, 8'h74, 8'hce, 8'he6, 8'h21, 8'h27, 8'hfc,
//               8'h69, 8'h31, 8'h10, 8'h4a, 8'hab, 8'h64, 8'hf1, 8'h36, 8'ha0, 8'h48, 8'h5b},
//             -50);

//         $display("\n=================================================");
//         $display(" KET QUA TESTBENCH: PASS = %0d / %0d | FAIL = %0d", pass_count, test_count, fail_count);
//         $display("=================================================");

//         $finish;
//     end

// endmodule



/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    File Name   : tb_falcon_samplerZ.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Description : Corrected Testbench for SamplerZ (Full 16 KAT Vectors)
 ******************************************************************************/

`include "falcon_header.svh"

module tb_falcon_samplerZ;

    // -------------------------------------------------------------
    // Giao tiếp DUT
    // -------------------------------------------------------------
    logic                                            clk;
    logic                                            rst_n;
    logic                                            start;
    logic                                            done;
    logic                                            request;
    logic [`FPU_STAND - 1 : 0]                       o_dot; // FP64
    logic [`FPU_STAND - 1 : 0]                       mu;    // FP64
    logic [`FALCON_UNIFORM_BITS_SAMPLERZ - 1 : 0]    uniform_bits;
    logic signed [`FALCON_Z - 1 : 0]                 z;

    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    byte unsigned rand_mem [0 : 255];
    int rand_ptr = 0;
    int total_bytes = 0;

    // -------------------------------------------------------------
    // Khởi tạo DUT
    // -------------------------------------------------------------
    falcon_samplerZ dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .done         (done),
        .request      (request),
        .o_dot        (o_dot),
        .mu           (mu),
        .uniform_bits (uniform_bits),
        .z            (z)
    );

    // Clock 100MHz (Chu kỳ 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------
    // Khối phát Uniform Bits khi DUT gửi tín hiệu request
    // Căn chỉnh đúng:
    // [71 : 0]  : 9 byte cho BaseSampler (Byte đầu tiên là MSB [71:64])
    // [79 : 72] : Byte thứ 10 cho b (DUT đọc bit uniform_bits[72])
    // [87 : 80] : Byte thứ 11 cho BerExp
    // -------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uniform_bits <= '0;
        end else if (request) begin
            // Nạp 9 byte cho BaseSampler theo đúng thứ tự xuất hiện (Big-Endian)
            for (int i = 0; i < 9; i++) begin
                uniform_bits[(8 - i)*8 +: 8] <= rand_mem[rand_ptr + i];
            end
            
            // Byte thứ 10: Toàn bộ byte cho b (DUT đọc uniform_bits[72] = bit 0 của byte này)
            uniform_bits[79 : 72] <= rand_mem[rand_ptr + 9];
            
            // Byte thứ 11: Dành cho BerExp
            uniform_bits[87 : 80] <= rand_mem[rand_ptr + 10];

            // Tự động kiểm tra nếu là vòng 2 của Test 9 (dùng 12 byte) hay vòng bình thường (11 byte)
            // Nếu còn đúng 12 byte tính đến cuối mảng stream thì bước nhảy là 12, ngược lại là 11
            if ((total_bytes - rand_ptr) == 12) begin
                rand_ptr <= rand_ptr + 12;
            end else begin
                rand_ptr <= rand_ptr + 11;
            end
        end
    end

    // -------------------------------------------------------------
    // Task chạy kiểm thử từng vector
    // -------------------------------------------------------------
    task automatic run_kat(
        input string       test_id,
        input logic [63:0] in_mu_fp64,
        input logic [63:0] in_sigma_fp64,
        input byte unsigned stream[],
        input int          expected_z
    );
        int timeout = 0;
        test_count++;
        rand_ptr = 0;
        total_bytes = stream.size();

        for (int i = 0; i < stream.size(); i++) begin
            rand_mem[i] = stream[i];
        end

        // Giữ rst/idle tối thiểu 1 chu kỳ trước khi bắn start
        @(posedge clk);
        mu    <= in_mu_fp64;
        o_dot <= in_sigma_fp64;
        start <= 1'b1;

        @(posedge clk);
        start <= 1'b0;

        fork
            begin
                @(posedge done);
            end
            begin
                while (!done && timeout < 50000) begin
                    @(posedge clk);
                    timeout++;
                end
                if (!done) begin
                    $display("\n[TIMEOUT] %s: DUT bi treo hoac khong thoat loop!", test_id);
                    fail_count++;
                    disable fork;
                end
            end
        join_any
        disable fork;

        if (done) begin
            #1;
            if (z === expected_z) begin
                $display("[PASS] %s | Output z = %0d (Expected: %0d)", test_id, z, expected_z);
                pass_count++;
            end else begin
                $display("[FAIL] %s | Output z = %0d (Expected: %0d)", test_id, z, expected_z);
                fail_count++;
            end
        end

        repeat(5) @(posedge clk);
    endtask

    // -------------------------------------------------------------
    // Kịch bản kiểm thử: Đầy đủ 16 mẫu trích từ Table 3.2 (GIỮ NGUYÊN)
    // -------------------------------------------------------------
    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        mu    = '0;
        o_dot = '0;

        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);

        $display("=================================================");
        $display("   VERIFY DU 16 TEST VECTOR FALCON SAMPLERZ      ");
        $display("=================================================");

        // Test 1: mu = -91.90471153063714 | sigma' = 1.7037990414754918 (2 iterations)
        run_kat("Test 1", 64'hC056F9E6CB3119A4, 64'h3FFB42C2C8A17E81,
            '{8'h0f, 8'hc5, 8'h44, 8'h2f, 8'hf0, 8'h43, 8'hd6, 8'h6e, 8'h91, 8'hd1, 8'hea,
              8'hca, 8'hc6, 8'h4e, 8'ha5, 8'h45, 8'h0a, 8'h22, 8'h94, 8'h1e, 8'hdc, 8'h6c},
            -92
        );

        // Test 2: mu = -8.322564895434937 | sigma' = 1.7037990414754918 (2 iterations)
        run_kat("Test 2", 64'hc020a52796443c7b, 64'h3FFB42C2C8A17E81,
            '{8'hf4, 8'hda, 8'h0f, 8'h8d, 8'h84, 8'h44, 8'hd1, 8'ha7, 8'h72, 8'h65, 8'hc2,
              8'hef, 8'h6f, 8'h98, 8'hbb, 8'hbb, 8'h4b, 8'hee, 8'h7d, 8'hb8, 8'hd9, 8'hb3},
            -8
        );

        // Test 3: mu = -19.096516109216804 | sigma' = 1.7035823083824078 (2 iterations)
        run_kat("Test 3", 64'hC03318B5479C9F93, 64'h3FFB41DF85C8BEFD,
            '{8'hdb, 8'h47, 8'hf6, 8'hd7, 8'hfb, 8'h9b, 8'h19, 8'hf2, 8'h5c, 8'h36, 8'hd6,
              8'hb9, 8'h33, 8'h4d, 8'h47, 8'h7a, 8'h8b, 8'hc0, 8'hbe, 8'h68, 8'h14, 8'h5d},
            -20
        );

        // Test 4: mu = -11.335543982423326 | sigma' = 1.7035823083824078 -> z = -12
        run_kat("Test 4", 64'hC026ABCC6BBDC16D, 64'h3FFB41DF85C8BEFD,
            '{8'hae, 8'h41, 8'hb4, 8'hf5, 8'h20, 8'h96, 8'h65, 8'hc7, 8'h4d, 8'h00, 8'hdc,
              8'hc1, 8'ha8, 8'h16, 8'h8a, 8'h7b, 8'hb5, 8'h16, 8'hb3, 8'h19, 8'h0c, 8'hb4,
              8'h2c, 8'h1d, 8'hed, 8'h26, 8'hcd, 8'h52, 8'hae, 8'hd7, 8'h70, 8'hec, 8'ha7,
              8'hdd, 8'h33, 8'h4e, 8'h05, 8'h47, 8'hbc, 8'hc3, 8'hc1, 8'h63, 8'hce, 8'h0b},
            -12
        );

        // Test 5: mu = 7.9386734193997555 | sigma' = 1.6984647769450156 -> z = 8
        run_kat("Test 5", 64'h401FC1339AD7C928, 64'h3FFB2CE966E6303D,
            '{8'h31, 8'h05, 8'h41, 8'h66, 8'hc1, 8'h01, 8'h27, 8'h80, 8'hc6, 8'h03, 8'hae,
              8'h9b, 8'h83, 8'h3c, 8'hec, 8'h73, 8'hf2, 8'hf4, 8'h1c, 8'ha5, 8'h80, 8'h7c,
              8'hc8, 8'h9c, 8'h92, 8'h15, 8'h88, 8'h34, 8'h63, 8'h2f, 8'h9b, 8'h15, 8'h55},
            8
        );

        // Test 6: mu = -28.990850086867255 | sigma' = 1.6984647769450156 (1 iteration)
        run_kat("Test 6", 64'hC03CFDA859EE5568, 64'h3FFB2CE966E6303D,
            '{8'h73, 8'h7e, 8'h9d, 8'h68, 8'ha5, 8'h0a, 8'h06, 8'hdb, 8'hbc, 8'h64, 8'h77},
            -30
        );

        // Test 7: mu = -9.071257914091655 | sigma' = 1.6980782114808988 (1 iteration)
        run_kat("Test 7", 64'hC022247BEAD535AD, 64'h3FFB2B540F05C526,
            '{8'ha9, 8'h8d, 8'hdd, 8'h14, 8'hbf, 8'h0b, 8'hf2, 8'h20, 8'h61, 8'hd6, 8'h32},
            -10
        );

        // Test 8: mu = -43.88754568839566 | sigma' = 1.6980782114808988 (1 iteration)
        run_kat("Test 8", 64'hC045F19B18DCAEBE, 64'h3FFB2B540F05C526,
            '{8'h3c, 8'hbf, 8'h68, 8'h18, 8'ha6, 8'h8f, 8'h7a, 8'hb9, 8'h99, 8'h15, 8'h14},
            -41
        );

        // Test 9: mu = -58.17435547946095 | sigma' = 1.7010983419195522 -> z = -61
        // Iteration 1 dung 11 byte; Iteration 2 dung 12 byte (BerExp dung 2 byte: 58 7c)
        run_kat("Test 9", 64'hC04D165147C514E3, 64'h3FFB37B2E51D3058,
            '{8'h6f, 8'h86, 8'h33, 8'hf5, 8'hbf, 8'ha5, 8'hd2, 8'h68, 8'h48, 8'h66, 8'h8e,
              8'h3d, 8'h5d, 8'hdd, 8'h46, 8'h95, 8'h8e, 8'h97, 8'h63, 8'h04, 8'h10, 8'h58, 8'h7c},
            -61
        );

        // Test 10: mu = -43.58664906684732 | sigma' = 1.7010983419195522 -> z = -46
        run_kat("Test 10", 64'hC045CB17510E2B49, 64'h3FFB37B2E51D3058,
            '{8'h27, 8'h2b, 8'hc6, 8'hc2, 8'h5f, 8'h5c, 8'h5e, 8'he5, 8'h3f, 8'h83, 8'hc4,
              8'h3a, 8'h36, 8'h1f, 8'hbc, 8'h7c, 8'hc9, 8'h1d, 8'hc7, 8'h83, 8'he2, 8'h0a},
            -46
        );

        // Test 11: mu = -34.70565203313315 | sigma' = 1.7009387219711465 -> z = -34
        run_kat("Test 11", 64'hC0415A52CE4A54D6, 64'h3FFB370B8575DB97,
            '{8'h45, 8'h44, 8'h3c, 8'h59, 8'h57, 8'h4c, 8'h2c, 8'h3b, 8'h07, 8'he2, 8'he1,
              8'hd9, 8'h07, 8'h1e, 8'h6d, 8'h13, 8'h3d, 8'hbe, 8'h32, 8'h75, 8'h4b, 8'h0a},
            -34
        );

        // Test 12: mu = -44.36009577368896 | sigma' = 1.7009387219711465 -> z = -44
        run_kat("Test 12", 64'hC0462E179E49B601, 64'h3FFB370B8575DB97,
            '{8'h6a, 8'hc1, 8'h16, 8'hed, 8'h60, 8'hc2, 8'h58, 8'he2, 8'hcb, 8'hae, 8'hab,
              8'h72, 8'h8c, 8'h48, 8'h23, 8'he6, 8'hda, 8'h36, 8'he1, 8'h8d, 8'h08, 8'hda,
              8'h5d, 8'h0c, 8'hc1, 8'h04, 8'he2, 8'h1c, 8'hc7, 8'hfd, 8'h1f, 8'h5c, 8'ha8,
              8'hd9, 8'hdb, 8'hb6, 8'h75, 8'h26, 8'h6c, 8'h92, 8'h84, 8'h48, 8'h05, 8'h9e},
            -44
        );

        // Test 13: mu = -21.783037079346236 | sigma' = 1.6958406126012802 -> z = -23
        run_kat("Test 13", 64'hC035C8751E3758F2, 64'h3FFB2229C4259E1F,
            '{8'h68, 8'h16, 8'h3b, 8'hc1, 8'he2, 8'hcb, 8'hf3, 8'he1, 8'h8e, 8'h74, 8'h26},
            -23
        );

        // Test 14: mu = -39.68827784633828 | sigma' = 1.6958406126012802 -> z = -40
        run_kat("Test 14", 64'hC043D8197D0C4AC8, 64'h3FFB2229C4259E1F,
            '{8'hd6, 8'ha1, 8'hb5, 8'h1d, 8'h76, 8'h22, 8'h2a, 8'h70, 8'h5a, 8'h02, 8'h59},
            -40
        );

        // Test 15: mu = -18.488607061056847 | sigma' = 1.6955259305261838 -> z = -22
        run_kat("Test 15", 64'hC0327D155A33D576, 64'h3FFB20DFCC52142F,
            '{8'hf0, 8'h52, 8'h3b, 8'hfa, 8'ha8, 8'ha3, 8'h94, 8'hbf, 8'h4e, 8'ha5, 8'hc1,
              8'h0f, 8'h84, 8'h23, 8'h66, 8'hfd, 8'he2, 8'h86, 8'hd6, 8'ha3, 8'h08, 8'h03},
            -22
        );

        // Test 16: mu = -48.39610939101591 | sigma' = 1.6955259305261838 -> z = -50
        run_kat("Test 16", 64'hC04832B3B66806A2, 64'h3FFB20DFCC52142F,
            '{8'h87, 8'hbd, 8'h87, 8'he6, 8'h33, 8'h74, 8'hce, 8'he6, 8'h21, 8'h27, 8'hfc,
              8'h69, 8'h31, 8'h10, 8'h4a, 8'hab, 8'h64, 8'hf1, 8'h36, 8'ha0, 8'h48, 8'h5b},
            -50
        );

        $display("\n=================================================");
        $display(" KET QUA TESTBENCH: PASS = %0d / %0d | FAIL = %0d", pass_count, test_count, fail_count);
        $display("=================================================");

        $finish;
    end

endmodule