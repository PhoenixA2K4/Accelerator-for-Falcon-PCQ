/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : fpu_divider
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: fpu_divider.sv
 *    Create Date : Sep 1st 2026
 *    Last Update : Sep 1st 2026
 *    Description : Divider for Floating Point type
 ******************************************************************************
  History:

 ******************************************************************************/

`include "falcon_header.svh"

module fpu_divider (
    input  logic                      clk,
    input  logic                      rst_n,
    input  logic                      start,
    input  logic [`FPU_STAND - 1 : 0] a,
    input  logic [`FPU_STAND - 1 : 0] b,
    output logic [`FPU_STAND - 1 : 0] result,
    output logic                      valid,
    output logic                      busy
);

    logic        sign_a, sign_b;
    logic [`FPU_EXPO - 1 : 0] exp_a, exp_b;
    logic [`FPU_FRAC - 1 : 0] frac_a, frac_b;

    assign sign_a = a[63];
    assign exp_a  = a[62 : `FPU_FRAC];
    assign frac_a = a[`FPU_FRAC - 1:0];

    assign sign_b = b[63];
    assign exp_b  = b[62 : `FPU_FRAC];
    assign frac_b = b[`FPU_FRAC - 1 : 0];

    typedef enum logic [1:0] {
        IDLE     = 2'b00,
        INIT     = 2'b01,
        DIV_LOOP = 2'b10,
        FINALIZE = 2'b11
    } state_t;

    state_t state;

    logic        res_sign;
    logic signed [12:0] res_exp;
    logic [3:0]  iter_cnt;          

    logic [52:0] divisor;          
    logic [53:0] rem_reg;          
    logic [55:0] quotient;       


    logic [53:0] rem_stage [0:4];
    logic [3:0]  q_bits;




    always_comb begin
        rem_stage[0] = rem_reg;

        // Stage 1
        if (rem_stage[0] >= {1'b0, divisor}) begin
            rem_stage[1] = (rem_stage[0] - {1'b0, divisor}) << 1;
            q_bits[3]    = 1'b1;
        end else begin
            rem_stage[1] = rem_stage[0] << 1;
            q_bits[3]    = 1'b0;
        end

        // Stage 2
        if (rem_stage[1] >= {1'b0, divisor}) begin
            rem_stage[2] = (rem_stage[1] - {1'b0, divisor}) << 1;
            q_bits[2]    = 1'b1;
        end else begin
            rem_stage[2] = rem_stage[1] << 1;
            q_bits[2]    = 1'b0;
        end

        // Stage 3
        if (rem_stage[2] >= {1'b0, divisor}) begin
            rem_stage[3] = (rem_stage[2] - {1'b0, divisor}) << 1;
            q_bits[1]    = 1'b1;
        end else begin
            rem_stage[3] = rem_stage[2] << 1;
            q_bits[1]    = 1'b0;
        end

        // Stage 4
        if (rem_stage[3] >= {1'b0, divisor}) begin
            rem_stage[4] = (rem_stage[3] - {1'b0, divisor}) << 1;
            q_bits[0]    = 1'b1;
        end else begin
            rem_stage[4] = rem_stage[3] << 1;
            q_bits[0]    = 1'b0;
        end
    end



    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state     <= IDLE;
            valid     <= 1'b0;
            busy      <= 1'b0;
            result    <= '0;
            rem_reg   <= '0;
            divisor   <= '0;
            quotient  <= '0;
            res_sign  <= 1'b0;
            res_exp   <= '0;
            iter_cnt  <= '0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    if (start) begin
                        busy     <= 1'b1;
                        res_sign <= sign_a ^ sign_b;
                        state    <= INIT;
                    end
                end

                INIT: begin
                    divisor  <= {1'b1, frac_b};
                    rem_reg  <= {1'b0, 1'b1, frac_a}; 
                    res_exp  <= $signed({2'b00, exp_a}) - $signed({2'b00, exp_b}) + 13'sd1023;
                    quotient <= '0;
                    iter_cnt <= 4'd14; 
                    state    <= DIV_LOOP;
                end

                DIV_LOOP: begin
                    quotient <= (quotient << 4) | {52'd0, q_bits};
                    rem_reg  <= rem_stage[4];

                    if (iter_cnt == 4'd1) begin
                        state <= FINALIZE;
                    end else begin
                        iter_cnt <= iter_cnt - 1'b1;
                    end
                end

                FINALIZE: begin
                    logic [52:0] norm_man;
                    logic signed [12:0] final_exp;

                    if (quotient[55]) begin
                        norm_man  = quotient[55:3];
                        final_exp = res_exp;
                    end else begin
                        norm_man  = quotient[54:2];
                        final_exp = res_exp - 1'b1;
                    end

                    if (quotient[1] || quotient[0]) begin
                        norm_man = norm_man + 1'b1;
                    end

                    if (exp_a == 11'd0 && frac_a == 52'd0) begin
                        result <= {res_sign, 63'd0};        
                    end else if (exp_b == 11'd0 && frac_b == 52'd0) begin
                        result <= {res_sign, 11'h7FF, 52'd0}; 
                    end else if (final_exp >= 13'sd2047) begin
                        result <= {res_sign, 11'h7FF, 52'd0}; 
                    end else if (final_exp <= 13'sd0) begin
                        result <= {res_sign, 63'd0};      
                    end else begin
                        result <= {res_sign, final_exp[10:0], norm_man[51:0]};
                    end

                    valid <= 1'b1;
                    busy  <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule