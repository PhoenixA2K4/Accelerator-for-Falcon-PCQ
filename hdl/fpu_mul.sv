/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : fpu_mul.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: fpu_mul.sv
 *    Create Date : Oct 17th 2026
 *    Last Update : Oct 17th 2026
 *    Description : Multiplier for Floating Point type
 ******************************************************************************
  History:

 ******************************************************************************/
module fpu_mul (
    input  logic        clk,       // 1-bit clock
    input  logic        rst_n,     // 1-bit asynchronous active-low reset
    input  logic        start,     // 1-bit input valid
    input  logic [63:0] a,         // 64-bit IEEE-754 binary64 encoded operand
    input  logic [63:0] b,         // 64-bit IEEE-754 binary64 encoded operand
    output logic [63:0] result,    // 64-bit IEEE-754 binary64 encoded result
    output logic        valid_o    // 1-bit output valid
);
    // Stage 1: unpack and split each 53-bit significand into 26+27 bits.
    logic v1, sign1, zero1;
    logic signed [13:0] exp1;
    logic [25:0] ah1, bh1;
    logic [26:0] al1, bl1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v1 <= 0; sign1 <= 0; zero1 <= 0; exp1 <= '0;
            ah1 <= '0; bh1 <= '0; al1 <= '0; bl1 <= '0;
        end else begin
            v1 <= start;
            if (start) begin
                sign1 <= a[63] ^ b[63];
                zero1 <= (a[62:52] == 0) || (b[62:52] == 0);
                exp1 <= $signed({3'b000,a[62:52]})
                      + $signed({3'b000,b[62:52]}) - 14'sd1023;
                ah1 <= {1'b1,a[51:27]};  // significand[52:27]
                al1 <= a[26:0];
                bh1 <= {1'b1,b[51:27]};
                bl1 <= b[26:0];
            end
        end
    end

    // Stage 2: four parallel, narrower integer multiplies.
    logic v2, sign2, zero2;
    logic signed [13:0] exp2;
    logic [51:0] hh2;
    logic [52:0] hl2, lh2;
    logic [53:0] ll2;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v2 <= 0; sign2 <= 0; zero2 <= 0; exp2 <= '0;
            hh2 <= '0; hl2 <= '0; lh2 <= '0; ll2 <= '0;
        end else begin
            v2 <= v1;
            if (v1) begin
                sign2 <= sign1; zero2 <= zero1; exp2 <= exp1;
                hh2 <= ah1 * bh1;
                hl2 <= ah1 * bl1;
                lh2 <= al1 * bh1;
                ll2 <= al1 * bl1;
            end
        end
    end

    // Stage 3: reconstruct full 106-bit significand product.
    logic v3, sign3, zero3;
    logic signed [13:0] exp3;
    logic [105:0] prod3;
    logic [53:0] cross_sum;
    logic [105:0] product_comb;
    assign cross_sum = {1'b0,hl2} + {1'b0,lh2};
    assign product_comb = ({54'b0,hh2} << 54)
                        + ({52'b0,cross_sum} << 27)
                        + {52'b0,ll2};
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v3 <= 0; sign3 <= 0; zero3 <= 0; exp3 <= '0; prod3 <= '0;
        end else begin
            v3 <= v2;
            if (v2) begin
                sign3 <= sign2; zero3 <= zero2; exp3 <= exp2;
                prod3 <= product_comb;
            end
        end
    end

    // Stage 4: normalization and guard/round/sticky extraction.
    logic v4, sign4, zero4;
    logic signed [13:0] exp4;
    logic [52:0] mant4; // hidden 1 + fraction
    logic guard4, round4, sticky4;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v4 <= 0; sign4 <= 0; zero4 <= 0; exp4 <= '0;
            mant4 <= '0; guard4 <= 0; round4 <= 0; sticky4 <= 0;
        end else begin
            v4 <= v3;
            if (v3) begin
                sign4 <= sign3; zero4 <= zero3;
                if (prod3[105]) begin
                    exp4 <= exp3 + 14'sd1;
                    mant4 <= prod3[105:53];
                    guard4 <= prod3[52];
                    round4 <= prod3[51];
                    sticky4 <= |prod3[50:0];
                end else begin
                    exp4 <= exp3;
                    mant4 <= prod3[104:52];
                    guard4 <= prod3[51];
                    round4 <= prod3[50];
                    sticky4 <= |prod3[49:0];
                end
            end
        end
    end

    // Stage 5: round-to-nearest-even and pack. No subnormal result support.
    logic [53:0] rounded;
    logic signed [13:0] final_exp;
    always_comb begin
        rounded = {1'b0,mant4} +
                  {53'd0,(guard4 && (round4 || sticky4 || mant4[0]))};
        final_exp = exp4 + (rounded[53] ? 14'sd1 : 14'sd0);
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            result <= 64'd0;
        end else begin
            valid_o <= v4;
            if (v4) begin
                if (zero4 || (final_exp <= 0))
                    result <= {sign4, 63'd0};
                else if (final_exp >= 14'sd2047)
                    result <= {sign4, 11'h7ff, 52'd0};
                else if (rounded[53])
                    result <= {sign4, final_exp[10:0], rounded[52:1]};
                else
                    result <= {sign4, final_exp[10:0], rounded[51:0]};
            end
        end
    end
endmodule