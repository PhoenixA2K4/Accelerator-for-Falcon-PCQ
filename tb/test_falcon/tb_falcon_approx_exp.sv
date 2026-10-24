/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : tb_falcon_approx_exp
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: tb_falcon_approx_exp.sv
 *    Create Date : Sep 3rd 2026
 *    Last Update : Sep 3rd 2026
 *    Description : Testbench for Approx_Exp
 ******************************************************************************
  History:

 ******************************************************************************/

`include "falcon_header.svh"

module tb_falcon_approx_exp;

    logic clk;
    logic rst_n;
    logic start;
    logic done;

    logic [`FALCON_X - 1 : 0]   x;
    logic [`FALCON_CCS - 1 : 0] ccs;
    logic [`FALCON_Y - 1 : 0]   y;

    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD / 2) clk = ~clk;

    falcon_approx_exp dut (
        .clk   (clk),
        .rst_n (rst_n),
        .start (start),
        .x     (x),
        .ccs   (ccs),
        .y     (y),
        .done  (done)
    );

    always @(posedge clk) begin
        if (dut.curr_state == dut.ASSIGN_ST) begin
            $display("  [@%0t] Step idx_2=%0d | z=%016h | y_tmp=%016h | zy[126:63]=%016h",
                     $time, dut.idx_2, dut.z, dut.y_tmp, dut.zy[126:63]);
        end
    end

    task automatic run_approx_test(
        input string       test_name,
        input logic [63:0] in_x,
        input logic [63:0] in_ccs
    );
        begin
            $display("==================================================================");
            $display("[RUNNING] %s", test_name);
            $display("  -> Input x   = 0x%016h", in_x);
            $display("  -> Input ccs = 0x%016h", in_ccs);

            @(posedge clk);
            x     <= in_x;
            ccs   <= in_ccs;
            start <= 1'b1;

            @(posedge clk);
            start <= 1'b0;

            fork
                begin
                    @(posedge done);
                    @(negedge clk);
                    $display("------------------------------------------------------------------");
                    $display("  [OUTPUT] Final y = 0x%016h", y);
                    $display("==================================================================\n");
                end
                begin
                    // Timeout bảo vệ nếu FSM bị treo
                    repeat(300) @(posedge clk);
                    if (!done) begin
                        $display("  [ERROR] TIMEOUT: Module did not assert 'done'!");
                        $display("==================================================================\n");
                        $stop;
                    end
                end
            join_any
            disable fork;

            repeat(5) @(posedge clk);
        end
    endtask

    initial begin
        clk   = 0;
        rst_n = 0;
        start = 0;
        x     = '0;
        ccs   = '0;

        // Reset DUT
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        run_approx_test(
            "Test 1: Boundary Case x = 0, ccs = 76F3F6C614DA0C00",
            64'h0000_0000_0000_0000,
            64'h76F3_F6C6_14DA_0C00
        );

        run_approx_test(
            "Test 2: Normal Case x = 0.05 (Q1.63 ~ 64'h0666666666666666)",
            64'h0666_6666_6666_6666,
            64'h76F3_F6C6_14DA_0C00
        );

        run_approx_test(
            "Test 3: x = 0.1, ccs = 1.0",
            64'h0CCC_CCCC_CCCC_CCCC,
            64'h8000_0000_0000_0000
        );

        repeat(10) @(posedge clk);
        $display(">>> ALL APPROX_EXP TESTS COMPLETED <<<");
        $finish;
    end

endmodule