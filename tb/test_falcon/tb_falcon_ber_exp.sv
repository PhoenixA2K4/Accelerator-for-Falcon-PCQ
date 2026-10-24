`timescale 1ns/1ps
`include "falcon_header.svh"

module tb_falcon_ber_exp;

    /**********************************************************************
     * Signals
     **********************************************************************/

    logic clk;
    logic rst_n;
    logic start;

    logic [`FALCON_X - 1 : 0]   x;
    logic [`FALCON_CCS - 1 : 0] ccs;

    logic [7:0] uniform_bits;

    logic uniform_req;
    logic check_bit;
    logic done;


    integer test_count;
    integer pass_count;
    integer fail_count;


    /**********************************************************************
     * DUT
     **********************************************************************/

    falcon_ber_exp dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),

        .x              (x),
        .ccs            (ccs),

        .uniform_bits   (uniform_bits),

        .uniform_req    (uniform_req),
        .check_bit      (check_bit),
        .done           (done)
    );


    /**********************************************************************
     * Clock
     **********************************************************************/

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    /**********************************************************************
     * Reset
     **********************************************************************/

    task automatic reset_dut;
        begin

            rst_n        = 1'b0;
            start        = 1'b0;

            x            = '0;
            ccs          = '0;
            uniform_bits = '0;

            repeat(5) @(posedge clk);

            rst_n = 1'b1;

            repeat(2) @(posedge clk);

        end
    endtask


    /**********************************************************************
     * BerExp Test
     *
     * Mô phỏng PRNG:
     *
     * Clock N:
     *      DUT đặt uniform_req = 1
     *
     * Clock N+1:
     *      PRNG cập nhật uniform_bits
     *
     **********************************************************************/

    task automatic run_ber_test(
        input string                  test_name,

        input logic [`FALCON_X-1:0]   test_x,
        input logic [`FALCON_CCS-1:0] test_ccs,

        /*
         * Cho phép tối đa 8 random bytes vì BerExp
         * có thể kiểm tra tối đa 8 byte của z.
         */
        input logic [7:0] rand_0,
        input logic [7:0] rand_1,
        input logic [7:0] rand_2,
        input logic [7:0] rand_3,
        input logic [7:0] rand_4,
        input logic [7:0] rand_5,
        input logic [7:0] rand_6,
        input logic [7:0] rand_7,

        input integer expected_req,
        input logic   expected_result
    );

        integer req_count;

        logic [7:0] random_array [0:7];

        begin

            /**************************************************************
             * Prepare test
             **************************************************************/

            test_count = test_count + 1;

            req_count = 0;

            random_array[0] = rand_0;
            random_array[1] = rand_1;
            random_array[2] = rand_2;
            random_array[3] = rand_3;

            random_array[4] = rand_4;
            random_array[5] = rand_5;
            random_array[6] = rand_6;
            random_array[7] = rand_7;


            $display("");
            $display("======================================================");
            $display("TEST %0d", test_count);
            $display("%s", test_name);
            $display("======================================================");

            $display("x   = %016h", test_x);
            $display("ccs = %016h", test_ccs);


            /**************************************************************
             * Start BerExp
             **************************************************************/

            @(negedge clk);

            x            = test_x;
            ccs          = test_ccs;
            uniform_bits = 8'h00;

            start = 1'b1;


            @(negedge clk);

            start = 1'b0;


            /**************************************************************
             * Wait for BerExp
             **************************************************************/

            while(done !== 1'b1) begin

                /*
                 * DUT yêu cầu random byte.
                 */
                if(uniform_req === 1'b1) begin

                    if(req_count < 8) begin

                        $display(
                            "[PRNG] Request #%0d detected",
                            req_count + 1
                        );


                        /*
                         * DUT request ở clock hiện tại.
                         *
                         * PRNG phải chờ tới rising edge tiếp theo
                         * rồi mới cập nhật uniform_bits.
                         */
                        @(posedge clk);


                        uniform_bits = random_array[req_count];


                        $display(
                            "[PRNG] New uniform_bits = 8'h%02h",
                            random_array[req_count]
                        );


                        req_count = req_count + 1;

                    end

                    else begin

                        $display(
                            "[ERROR] BerExp requested more than 8 bytes!"
                        );

                        fail_count = fail_count + 1;

                        disable run_ber_test;

                    end

                end


                @(negedge clk);

            end


            /**************************************************************
             * Check result
             **************************************************************/

            #1;


            $display("-----------------------------------------");

            $display(
                "Result           = %0b",
                check_bit
            );

            $display(
                "Expected result  = %0b",
                expected_result
            );

            $display(
                "Random requests  = %0d",
                req_count
            );

            $display(
                "Expected request = %0d",
                expected_req
            );


            if(
                (check_bit === expected_result)
                &&
                (req_count == expected_req)
            ) begin

                $display("");
                $display(">>> PASS");

                pass_count = pass_count + 1;

            end

            else begin

                $display("");
                $display(">>> FAIL");

                fail_count = fail_count + 1;

            end


            /*
             * Chờ DUT quay lại IDLE.
             */
            repeat(3) @(posedge clk);

        end

    endtask



    /**********************************************************************
     * Main Test
     **********************************************************************/

    initial begin

        test_count = 0;
        pass_count = 0;
        fail_count = 0;


        reset_dut();


        /******************************************************************
         * TEST 1
         *
         * x   = 0
         * ccs = 1
         *
         * ApproxExp = 0x8000000000000000
         *
         * z = 0xFFFFFFFFFFFFFFFF
         *
         * first z byte = FF
         *
         * random = 80
         *
         * 80 < FF
         *
         * result = 1
         ******************************************************************/

        run_ber_test(

            "Test 1: x = 0, rand < z_byte",

            64'h0000_0000_0000_0000,
            64'h8000_0000_0000_0000,

            8'h80,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,

            1,
            1'b1
        );



        /******************************************************************
         * TEST 2
         *
         * x = 0.5
         *
         * z approximately:
         *
         * 9B 45 97 E3 7C B0 46 C1
         *
         * first byte = 9B
         *
         * random = 50
         *
         * 50 < 9B
         ******************************************************************/

        run_ber_test(

            "Test 2: x = 0.5, rand < z_byte",

            64'h0080_0000_0000_0000,
            64'h8000_0000_0000_0000,

            8'h50,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,

            1,
            1'b1
        );



        /******************************************************************
         * TEST 3
         *
         * x = 0.5
         *
         * first z byte = 9B
         *
         * random = C0
         *
         * C0 > 9B
         ******************************************************************/

        run_ber_test(

            "Test 3: x = 0.5, rand > z_byte",

            64'h0080_0000_0000_0000,
            64'h8000_0000_0000_0000,

            8'hC0,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,

            1,
            1'b0
        );



        /******************************************************************
         * TEST 4
         *
         * Kiểm tra REQUEST 2 lần.
         *
         * z:
         *
         * 9B 45 97 E3 7C B0 46 C1
         * ^^ ^^
         *
         * Random #1 = 9B
         *
         *      9B == 9B
         *
         * => w = 0
         * => BerExp phải request byte thứ 2.
         *
         *
         * Random #2 = 20
         *
         *      20 < 45
         *
         * => w < 0
         * => result = 1
         ******************************************************************/

        run_ber_test(

            "Test 4: Request twice, second random < z_byte",

            64'h0080_0000_0000_0000,
            64'h8000_0000_0000_0000,

            8'h9B,
            8'h20,

            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,

            2,
            1'b1
        );



        /******************************************************************
         * TEST 5
         *
         * Request 2 lần nhưng kết quả = 0.
         *
         * Random #1:
         *
         *      9B == 9B
         *
         * => request tiếp
         *
         * Random #2:
         *
         *      80 > 45
         *
         * => result = 0
         ******************************************************************/

        run_ber_test(

            "Test 5: Request twice, second random > z_byte",

            64'h0080_0000_0000_0000,
            64'h8000_0000_0000_0000,

            8'h9B,
            8'h80,

            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,

            2,
            1'b0
        );



        /******************************************************************
         * TEST 6
         *
         * Kiểm tra REQUEST 3 lần.
         *
         * z:
         *
         * 9B 45 97 E3 7C B0 46 C1
         * ^^ ^^ ^^
         *
         *
         * Random #1:
         *
         *      9B == 9B
         *
         * => request #2
         *
         *
         * Random #2:
         *
         *      45 == 45
         *
         * => request #3
         *
         *
         * Random #3:
         *
         *      50 < 97
         *
         * => result = 1
         ******************************************************************/

        run_ber_test(

            "Test 6: Request three random bytes",

            64'h0080_0000_0000_0000,
            64'h8000_0000_0000_0000,

            8'h9B,
            8'h45,
            8'h50,

            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,

            3,
            1'b1
        );



        /******************************************************************
         * TEST 7
         *
         * x = 1
         *
         * s = 1
         *
         * first z byte approximately 5E
         *
         * random = 30
         *
         * 30 < 5E
         ******************************************************************/

        run_ber_test(

            "Test 7: x = 1.0, s = 1",

            64'h0100_0000_0000_0000,
            64'h8000_0000_0000_0000,

            8'h30,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,

            1,
            1'b1
        );



        /******************************************************************
         * TEST 8
         *
         * x = 44
         *
         * s >= 63
         *
         * s is saturated to 63.
         *
         * high byte of z = 00
         *
         * random = 05
         *
         * 05 > 00
         *
         * result = 0
         ******************************************************************/

        run_ber_test(

            "Test 8: x = 44, s saturated to 63",

            64'h2C00_0000_0000_0000,
            64'h8000_0000_0000_0000,

            8'h05,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,
            8'h00,

            1,
            1'b0
        );



        /******************************************************************
         * Final report
         ******************************************************************/

        $display("");
        $display("");
        $display("======================================================");
        $display("                TEST SUMMARY");
        $display("======================================================");

        $display("Total : %0d", test_count);
        $display("Pass  : %0d", pass_count);
        $display("Fail  : %0d", fail_count);

        $display("======================================================");


        if(fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");


        $display("======================================================");


        #100;

        $finish;

    end


    /**********************************************************************
     * Timeout
     **********************************************************************/

    initial begin

        #1000000;

        $display("");
        $display("[ERROR] Simulation timeout!");

        $finish;

    end


endmodule