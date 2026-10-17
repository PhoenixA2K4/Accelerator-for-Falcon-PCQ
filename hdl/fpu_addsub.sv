/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : fpu_addsub.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: fpu_addsub
 *    Create Date : Oct 17th 2026
 *    Last Update : Oct 17th 2026
 *    Description : Add - Sub for Floating Point type
 ******************************************************************************
  History:

 ******************************************************************************/

module fpu_addsub (
    input  logic        clk,        // 1-bit, clock
    input  logic        rst_n,      // 1-bit, reset active-low
    input  logic        start,      // 1-bit, input valid / start

    input  logic        sub,        // 1-bit, 0: a+b, 1: a-b
    input  logic [63:0] a,          // 64-bit, IEEE-754 binary64
    input  logic [63:0] b,          // 64-bit, IEEE-754 binary64

    output logic [63:0] result,     // 64-bit, IEEE-754 binary64
    output logic        valid_o      // 1-bit, result valid
);

    // =========================================================
    // Helper functions
    // =========================================================

    // Shift-right with sticky-bit jam
    function automatic logic [55:0] shr_jam56 (
        input logic [55:0] in,
        input logic [10:0] shamt
    );
        logic [55:0] tmp;
        logic        sticky;
        integer      i;
        begin
            if (shamt == 0) begin
                shr_jam56 = in;
            end
            else if (shamt >= 56) begin
                shr_jam56 = 56'd0;
                if (in != 56'd0)
                    shr_jam56[0] = 1'b1;
            end
            else begin
                tmp    = in >> shamt;
                sticky = 1'b0;
                for (i = 0; i < shamt; i = i + 1) begin
                    sticky = sticky | in[i];
                end
                tmp[0] = tmp[0] | sticky;
                shr_jam56 = tmp;
            end
        end
    endfunction

    // Leading-zero count for 56-bit vector
    function automatic logic [5:0] lzc56 (
        input logic [55:0] in
    );
        integer i;
        begin
            lzc56 = 6'd56;
            for (i = 55; i >= 0; i = i - 1) begin
                if (in[i]) begin
                    lzc56 = 6'(55 - i);
                    break;
                end
            end
        end
    endfunction

    // =========================================================
    // Stage 1 registers: unpack + compare + align
    // =========================================================
    logic        vld_s1;

    logic        s1_same_sign;      // 1-bit
    logic        s1_sign_big;       // 1-bit
    logic [10:0] s1_exp_big;        // 11-bit, effective exponent
    logic [55:0] s1_sig_big;        // 56-bit, 1.frac + GRS
    logic [55:0] s1_sig_small;      // 56-bit, aligned, jammed

    // =========================================================
    // Stage 2 registers: add/sub significand
    // =========================================================
    logic        vld_s2;

    logic        s2_add_mode;       // 1-bit, 1:add, 0:subtract
    logic        s2_sign;           // 1-bit
    logic [10:0] s2_exp;            // 11-bit
    logic [56:0] s2_sig_ext;        // 57-bit, add/sub result
    logic        s2_zero;           // 1-bit

    // =========================================================
    // Stage 3 registers: normalize
    // =========================================================
    logic        vld_s3;

    logic        s3_sign;           // 1-bit
    logic [10:0] s3_exp;            // 11-bit
    logic [55:0] s3_sig;            // 56-bit normalized significand
    logic        s3_zero;           // 1-bit

    // =========================================================
    // Stage 4: round + pack
    // =========================================================
    logic [63:0] result_r;
    logic        valid_r;

    assign result  = result_r;
    assign valid_o = valid_r;

    // =========================================================
    // Stage 1: unpack + compare + align
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s1       <= 1'b0;
            s1_same_sign <= 1'b0;
            s1_sign_big  <= 1'b0;
            s1_exp_big   <= '0;
            s1_sig_big   <= '0;
            s1_sig_small <= '0;
        end
        else begin
            vld_s1 <= start;

            if (start) begin
                logic        sign_a, sign_b, sign_b_eff;
                logic [10:0] exp_a, exp_b;
                logic [51:0] frac_a, frac_b;
                logic [55:0] sig_a, sig_b;
                logic        a_is_zero, b_is_zero;
                logic        a_ge_b;
                logic [10:0] exp_big, exp_small;
                logic [55:0] sig_big, sig_small;
                logic        sign_big, sign_small;
                logic [10:0] exp_diff;

                sign_a     = a[63];
                exp_a      = a[62:52];
                frac_a     = a[51:0];

                sign_b     = b[63];
                exp_b      = b[62:52];
                frac_b     = b[51:0];

                sign_b_eff = sign_b ^ sub;

                // Flush subnormal to zero in this version
                a_is_zero = (exp_a == 11'd0) && (frac_a == 52'd0);
                b_is_zero = (exp_b == 11'd0) && (frac_b == 52'd0);

                sig_a = a_is_zero ? 56'd0 : {1'b1, frac_a, 3'b000};
                sig_b = b_is_zero ? 56'd0 : {1'b1, frac_b, 3'b000};

                // Compare magnitudes
                if (exp_a > exp_b) begin
                    a_ge_b = 1'b1;
                end
                else if (exp_a < exp_b) begin
                    a_ge_b = 1'b0;
                end
                else begin
                    a_ge_b = (sig_a >= sig_b);
                end

                if (a_ge_b) begin
                    exp_big   = exp_a;
                    exp_small = exp_b;
                    sig_big   = sig_a;
                    sig_small = sig_b;
                    sign_big  = sign_a;
                    sign_small= sign_b_eff;
                end
                else begin
                    exp_big   = exp_b;
                    exp_small = exp_a;
                    sig_big   = sig_b;
                    sig_small = sig_a;
                    sign_big  = sign_b_eff;
                    sign_small= sign_a;
                end

                exp_diff = exp_big - exp_small;

                s1_same_sign <= (sign_big == sign_small);
                s1_sign_big  <= sign_big;
                s1_exp_big   <= exp_big;
                s1_sig_big   <= sig_big;
                s1_sig_small <= shr_jam56(sig_small, exp_diff);
            end
        end
    end

    // =========================================================
    // Stage 2: add/sub significand
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s2      <= 1'b0;
            s2_add_mode <= 1'b0;
            s2_sign     <= 1'b0;
            s2_exp      <= '0;
            s2_sig_ext  <= '0;
            s2_zero     <= 1'b0;
        end
        else begin
            vld_s2 <= vld_s1;

            if (vld_s1) begin
                s2_add_mode <= s1_same_sign;
                s2_sign     <= s1_sign_big;
                s2_exp      <= s1_exp_big;

                if (s1_same_sign) begin
                    s2_sig_ext <= {1'b0, s1_sig_big} + {1'b0, s1_sig_small};
                    s2_zero    <= 1'b0;
                end
                else begin
                    s2_sig_ext <= {1'b0, s1_sig_big} - {1'b0, s1_sig_small};
                    s2_zero    <= ({1'b0, s1_sig_big} == {1'b0, s1_sig_small});
                end
            end
        end
    end

    // =========================================================
    // Stage 3: normalize
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_s3  <= 1'b0;
            s3_sign <= 1'b0;
            s3_exp  <= '0;
            s3_sig  <= '0;
            s3_zero <= 1'b0;
        end
        else begin
            vld_s3 <= vld_s2;

            if (vld_s2) begin
                logic [55:0] sig_tmp;
                logic [5:0]  lz;

                s3_sign <= s2_sign;
                s3_zero <= s2_zero;

                if (s2_zero || (s2_sig_ext == 57'd0)) begin
                    s3_exp  <= 11'd0;
                    s3_sig  <= 56'd0;
                    s3_zero <= 1'b1;
                end
                else if (s2_add_mode) begin
                    // Addition path
                    if (s2_sig_ext[56]) begin
                        // Right shift by 1 with sticky jam
                        s3_exp     <= s2_exp + 11'd1;
                        s3_sig[55] <= s2_sig_ext[56];
                        s3_sig[54:1] <= s2_sig_ext[55:2];
                        s3_sig[0]  <= s2_sig_ext[1] | s2_sig_ext[0];
                    end
                    else begin
                        s3_exp <= s2_exp;
                        s3_sig <= s2_sig_ext[55:0];
                    end
                end
                else begin
                    // Subtraction path
                    sig_tmp = s2_sig_ext[55:0];
                    lz      = lzc56(sig_tmp);

                    if (lz == 6'd56) begin
                        s3_exp  <= 11'd0;
                        s3_sig  <= 56'd0;
                        s3_zero <= 1'b1;
                    end
                    else if (s2_exp > lz) begin
                        s3_exp <= s2_exp - lz;
                        s3_sig <= sig_tmp << lz;
                    end
                    else begin
                        // underflow to zero in this simplified version
                        s3_exp  <= 11'd0;
                        s3_sig  <= 56'd0;
                        s3_zero <= 1'b1;
                    end
                end
            end
        end
    end

    // =========================================================
    // Stage 4: round + pack
    // Round to nearest even
    // =========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_r  <= 1'b0;
            result_r <= 64'd0;
        end
        else begin
            valid_r <= vld_s3;

            if (vld_s3) begin
                logic [52:0] mant_pre;     // hidden + 52 frac
                logic [53:0] mant_round;   // for carry after rounding
                logic        guard_b, round_b, sticky_b;
                logic        inc_round;
                logic [10:0] exp_pack;
                logic [52:0] mant_fin;
                logic [51:0] frac_pack;

                if (s3_zero || (s3_exp == 11'd0)) begin
                    result_r <= 64'd0;
                end
                else begin
                    mant_pre = s3_sig[55:3];    // hidden + 52 fraction bits
                    guard_b  = s3_sig[2];
                    round_b  = s3_sig[1];
                    sticky_b = s3_sig[0];

                    // round-to-nearest-even
                    inc_round = guard_b && (round_b || sticky_b || mant_pre[0]);

                    mant_round = {1'b0, mant_pre} + inc_round;
                    exp_pack   = s3_exp;

                    if (mant_round[53]) begin
                        // carry from rounding
                        mant_fin = mant_round[53:1];
                        exp_pack = s3_exp + 11'd1;
                    end
                    else begin
                        mant_fin = mant_round[52:0];
                    end

                    // overflow -> inf
                    if (exp_pack >= 11'd2047) begin
                        result_r <= {s3_sign, 11'h7FF, 52'd0};
                    end
                    else begin
                        frac_pack = mant_fin[51:0];
                        result_r  <= {s3_sign, exp_pack, frac_pack};
                    end
                end
            end
        end
    end

endmodule