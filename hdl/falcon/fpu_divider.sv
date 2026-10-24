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

// `include "falcon_header.svh"

// module fpu_divider (
//     input  logic                      clk,
//     input  logic                      rst_n,
//     input  logic                      start,
//     input  logic [`FPU_STAND - 1 : 0] a,
//     input  logic [`FPU_STAND - 1 : 0] b,
//     output logic [`FPU_STAND - 1 : 0] result,
//     output logic                      valid,
//     output logic                      busy
// );

//     logic        sign_a, sign_b;
//     logic [`FPU_EXPO - 1 : 0] exp_a, exp_b;
//     logic [`FPU_FRAC - 1 : 0] frac_a, frac_b;

//     assign sign_a = a[63];
//     assign exp_a  = a[62 : `FPU_FRAC];
//     assign frac_a = a[`FPU_FRAC - 1:0];

//     assign sign_b = b[63];
//     assign exp_b  = b[62 : `FPU_FRAC];
//     assign frac_b = b[`FPU_FRAC - 1 : 0];

//     typedef enum logic [1:0] {
//         IDLE     = 2'b00,
//         INIT     = 2'b01,
//         DIV_LOOP = 2'b10,
//         FINALIZE = 2'b11
//     } state_t;

//     state_t state;

//     logic        res_sign;
//     logic signed [12:0] res_exp;
//     logic [3:0]  iter_cnt;          

//     logic [52:0] divisor;          
//     logic [53:0] rem_reg;          
//     logic [55:0] quotient;       


//     logic [53:0] rem_stage [0:4];
//     logic [3:0]  q_bits;




//     always_comb begin
//         rem_stage[0] = rem_reg;

//         // Stage 1
//         if (rem_stage[0] >= {1'b0, divisor}) begin
//             rem_stage[1] = (rem_stage[0] - {1'b0, divisor}) << 1;
//             q_bits[3]    = 1'b1;
//         end else begin
//             rem_stage[1] = rem_stage[0] << 1;
//             q_bits[3]    = 1'b0;
//         end

//         // Stage 2
//         if (rem_stage[1] >= {1'b0, divisor}) begin
//             rem_stage[2] = (rem_stage[1] - {1'b0, divisor}) << 1;
//             q_bits[2]    = 1'b1;
//         end else begin
//             rem_stage[2] = rem_stage[1] << 1;
//             q_bits[2]    = 1'b0;
//         end

//         // Stage 3
//         if (rem_stage[2] >= {1'b0, divisor}) begin
//             rem_stage[3] = (rem_stage[2] - {1'b0, divisor}) << 1;
//             q_bits[1]    = 1'b1;
//         end else begin
//             rem_stage[3] = rem_stage[2] << 1;
//             q_bits[1]    = 1'b0;
//         end

//         // Stage 4
//         if (rem_stage[3] >= {1'b0, divisor}) begin
//             rem_stage[4] = (rem_stage[3] - {1'b0, divisor}) << 1;
//             q_bits[0]    = 1'b1;
//         end else begin
//             rem_stage[4] = rem_stage[3] << 1;
//             q_bits[0]    = 1'b0;
//         end
//     end



//     always_ff @(posedge clk) begin
//         if (!rst_n) begin
//             state     <= IDLE;
//             valid     <= 1'b0;
//             busy      <= 1'b0;
//             result    <= '0;
//             rem_reg   <= '0;
//             divisor   <= '0;
//             quotient  <= '0;
//             res_sign  <= 1'b0;
//             res_exp   <= '0;
//             iter_cnt  <= '0;
//         end else begin
//             case (state)
//                 IDLE: begin
//                     valid <= 1'b0;
//                     if (start) begin
//                         busy     <= 1'b1;
//                         res_sign <= sign_a ^ sign_b;
//                         state    <= INIT;
//                     end
//                 end

//                 INIT: begin
//                     divisor  <= {1'b1, frac_b};
//                     rem_reg  <= {1'b0, 1'b1, frac_a}; 
//                     res_exp  <= $signed({2'b00, exp_a}) - $signed({2'b00, exp_b}) + 13'sd1023;
//                     quotient <= '0;
//                     iter_cnt <= 4'd14; 
//                     state    <= DIV_LOOP;
//                 end

//                 DIV_LOOP: begin
//                     quotient <= (quotient << 4) | {52'd0, q_bits};
//                     rem_reg  <= rem_stage[4];

//                     if (iter_cnt == 4'd1) begin
//                         state <= FINALIZE;
//                     end else begin
//                         iter_cnt <= iter_cnt - 1'b1;
//                     end
//                 end

//                 FINALIZE: begin
//                     logic [52:0] norm_man;
//                     logic signed [12:0] final_exp;

//                     if (quotient[55]) begin
//                         norm_man  = quotient[55:3];
//                         final_exp = res_exp;
//                     end else begin
//                         norm_man  = quotient[54:2];
//                         final_exp = res_exp - 1'b1;
//                     end

//                     if (quotient[1] || quotient[0]) begin
//                         norm_man = norm_man + 1'b1;
//                     end

//                     if (exp_a == 11'd0 && frac_a == 52'd0) begin
//                         result <= {res_sign, 63'd0};        
//                     end else if (exp_b == 11'd0 && frac_b == 52'd0) begin
//                         result <= {res_sign, 11'h7FF, 52'd0}; 
//                     end else if (final_exp >= 13'sd2047) begin
//                         result <= {res_sign, 11'h7FF, 52'd0}; 
//                     end else if (final_exp <= 13'sd0) begin
//                         result <= {res_sign, 63'd0};      
//                     end else begin
//                         result <= {res_sign, final_exp[10:0], norm_man[51:0]};
//                     end

//                     valid <= 1'b1;
//                     busy  <= 1'b0;
//                     state <= IDLE;
//                 end
//             endcase
//         end
//     end

// endmodule

// `include "falcon_header.svh"

// // Radix-2 iterative FP64 divider.
// // Normal finite operands: round-to-nearest, ties-to-even.
// // Subnormal inputs/outputs are flushed to signed zero.
// // NaN/Infinity inputs are handled as documented below.
// module fpu_divider (
//     input  logic                      clk,     // 1-bit clock
//     input  logic                      rst_n,   // 1-bit synchronous active-low reset
//     input  logic                      start,   // 1-bit request; accepted only when !busy
//     input  logic [`FPU_STAND-1:0]     a,       // 64-bit IEEE-754 binary64 bits
//     input  logic [`FPU_STAND-1:0]     b,       // 64-bit IEEE-754 binary64 bits
//     output logic [`FPU_STAND-1:0]     result,  // 64-bit IEEE-754 binary64 bits
//     output logic                      valid,   // 1-bit response pulse
//     output logic                      busy     // 1-bit divider occupied
// );
//     localparam logic [63:0] QNAN = 64'h7ff8_0000_0000_0000;

//     typedef enum logic [1:0] { IDLE, DIVIDE, FINISH } state_t;
//     state_t state;

//     logic         sign_q;
//     logic signed [12:0] exponent_q;
//     logic [52:0] divisor_q;       // 53-bit, 1.fraction
//     logic [53:0] remainder_q;     // 54-bit, shifted remainder
//     logic [55:0] quotient_q;      // 56 quotient bits, MSB first
//     logic [5:0]  cycles_left;     // 56 down to 1
//     logic        special_q;
//     logic [63:0] special_result_q;

//     // Exactly ONE restoring-division step per cycle.
//     // 55-bit subtract supplies comparison (borrow) and difference together.
//     logic [54:0] difference;
//     logic        quotient_bit;
//     logic [53:0] next_remainder;

//     assign difference = {1'b0, remainder_q} - {2'b00, divisor_q};
//     assign quotient_bit = !difference[54];
//     assign next_remainder = quotient_bit
//                           ? {difference[52:0], 1'b0}
//                           : {remainder_q[52:0], 1'b0};

//     always_ff @(posedge clk) begin : divider_regs
//         if (!rst_n) begin
//             state            <= IDLE;
//             busy             <= 1'b0;
//             valid            <= 1'b0;
//             result           <= '0;
//             sign_q           <= 1'b0;
//             exponent_q       <= '0;
//             divisor_q        <= '0;
//             remainder_q      <= '0;
//             quotient_q       <= '0;
//             cycles_left      <= '0;
//             special_q        <= 1'b0;
//             special_result_q <= '0;
//         end else begin
//             valid <= 1'b0;
//             case (state)
//                 IDLE: begin
//                     busy <= 1'b0;
//                     if (start) begin
//                         sign_q      <= a[63] ^ b[63];
//                         exponent_q  <= $signed({2'b00, a[62:52]})
//                                      - $signed({2'b00, b[62:52]}) + 13'sd1023;
//                         divisor_q   <= {1'b1, b[51:0]};
//                         remainder_q <= {1'b0, 1'b1, a[51:0]};
//                         quotient_q  <= 56'd0;
//                         cycles_left <= 6'd56;
//                         busy        <= 1'b1;

//                         special_q <= (a[62:52] == 11'h7ff) ||
//                                      (b[62:52] == 11'h7ff) ||
//                                      (a[62:52] == 11'd0) ||
//                                      (b[62:52] == 11'd0);
//                         // Flush subnormal operands to zero. 0/0, Inf/Inf,
//                         // NaN operands and 0*Inf-like division => qNaN.
//                         if ((a[62:52] == 11'h7ff && a[51:0] != 0) ||
//                             (b[62:52] == 11'h7ff && b[51:0] != 0) ||
//                             (a[62:52] == 11'd0 && b[62:52] == 11'd0) ||
//                             (a[62:52] == 11'h7ff && b[62:52] == 11'h7ff))
//                             special_result_q <= QNAN;
//                         else if (a[62:52] == 11'h7ff || b[62:52] == 11'd0)
//                             special_result_q <= {a[63]^b[63], 11'h7ff, 52'd0};
//                         else
//                             special_result_q <= {a[63]^b[63], 63'd0};
//                         state <= DIVIDE;
//                     end
//                 end
//                 DIVIDE: begin
//                     if (special_q) begin
//                         state <= FINISH;
//                     end else begin
//                         quotient_q  <= {quotient_q[54:0], quotient_bit};
//                         remainder_q <= next_remainder;
//                         cycles_left <= cycles_left - 6'd1;
//                         if (cycles_left == 6'd1)
//                             state <= FINISH;
//                     end
//                 end
//                 FINISH: begin : pack_stage
//                     logic [52:0] mant;
//                     logic [53:0] rounded;
//                     logic g, r, s, inc;
//                     logic signed [12:0] exp;
//                     if (special_q) begin
//                         result <= special_result_q;
//                     end else begin
//                         exp = exponent_q;
//                         if (quotient_q[55]) begin
//                             mant = quotient_q[55:3];
//                             g = quotient_q[2];
//                             r = quotient_q[1];
//                             s = quotient_q[0] | (remainder_q != 0);
//                         end else begin
//                             mant = quotient_q[54:2];
//                             g = quotient_q[1];
//                             r = quotient_q[0];
//                             s = (remainder_q != 0);
//                             exp = exp - 13'sd1;
//                         end
//                         inc = g && (r || s || mant[0]);
//                         rounded = {1'b0, mant} + {53'd0,inc};
//                         if (rounded[53]) begin
//                             rounded = rounded >> 1;
//                             exp = exp + 13'sd1;
//                         end
//                         if (exp >= 13'sd2047)
//                             result <= {sign_q, 11'h7ff, 52'd0};
//                         else if (exp <= 13'sd0)
//                             result <= {sign_q, 63'd0};
//                         else
//                             result <= {sign_q, exp[10:0], rounded[51:0]};
//                     end
//                     busy  <= 1'b0;
//                     valid <= 1'b1;
//                     state <= IDLE;
//                 end
//                 default: state <= IDLE;
//             endcase
//         end
//     end
// endmodule



`include "falcon_header.svh"

// Two radix-2 restoring steps per cycle (radix-4 throughput per iteration).
// Normal finite operands: round-to-nearest, ties-to-even.
// Subnormal inputs/outputs are flushed to signed zero.
// NaN/Infinity inputs are handled as documented below.
module fpu_divider (
    input  logic                      clk,     // 1-bit clock
    input  logic                      rst_n,   // 1-bit synchronous active-low reset
    input  logic                      start,   // 1-bit request; accepted only when !busy
    input  logic [`FPU_STAND-1:0]     a,       // 64-bit IEEE-754 binary64 bits
    input  logic [`FPU_STAND-1:0]     b,       // 64-bit IEEE-754 binary64 bits
    output logic [`FPU_STAND-1:0]     result,  // 64-bit IEEE-754 binary64 bits
    output logic                      valid,   // 1-bit response pulse
    output logic                      busy     // 1-bit divider occupied
);
    localparam logic [63:0] QNAN = 64'h7ff8_0000_0000_0000;

    typedef enum logic [1:0] { IDLE, DIVIDE, FINISH } state_t;
    state_t state;

    logic         sign_q;
    logic signed [12:0] exponent_q;
    logic [52:0] divisor_q;       // 53-bit, 1.fraction
    logic [53:0] remainder_q;     // 54-bit, shifted remainder
    logic [55:0] quotient_q;      // 56 quotient bits, MSB first
    logic [4:0]  cycles_left;     // 28 down to 1
    logic        special_q;
    logic [63:0] special_result_q;

    // Two dependent restoring steps in one clock cycle.
    // 55-bit subtraction sign bit acts as unsigned borrow.
    logic [54:0] difference0, difference1;
    logic        qbit0, qbit1;
    logic [53:0] rem1, rem2;

    assign difference0 = {1'b0, remainder_q} - {2'b00, divisor_q};
    assign qbit0       = !difference0[54];
    assign rem1        = qbit0 ? {difference0[52:0], 1'b0}
                               : {remainder_q[52:0], 1'b0};

    assign difference1 = {1'b0, rem1} - {2'b00, divisor_q};
    assign qbit1       = !difference1[54];
    assign rem2        = qbit1 ? {difference1[52:0], 1'b0}
                               : {rem1[52:0], 1'b0};

    always_ff @(posedge clk) begin : divider_regs
        if (!rst_n) begin
            state            <= IDLE;
            busy             <= 1'b0;
            valid            <= 1'b0;
            result           <= '0;
            sign_q           <= 1'b0;
            exponent_q       <= '0;
            divisor_q        <= '0;
            remainder_q      <= '0;
            quotient_q       <= '0;
            cycles_left      <= '0;
            special_q        <= 1'b0;
            special_result_q <= '0;
        end else begin
            valid <= 1'b0;
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        sign_q      <= a[63] ^ b[63];
                        exponent_q  <= $signed({2'b00, a[62:52]})
                                     - $signed({2'b00, b[62:52]}) + 13'sd1023;
                        divisor_q   <= {1'b1, b[51:0]};
                        remainder_q <= {1'b0, 1'b1, a[51:0]};
                        quotient_q  <= 56'd0;
                        cycles_left <= 5'd28;
                        busy        <= 1'b1;

                        special_q <= (a[62:52] == 11'h7ff) ||
                                     (b[62:52] == 11'h7ff) ||
                                     (a[62:52] == 11'd0) ||
                                     (b[62:52] == 11'd0);
                        // Flush subnormal operands to zero. 0/0, Inf/Inf,
                        // NaN operands and 0*Inf-like division => qNaN.
                        if ((a[62:52] == 11'h7ff && a[51:0] != 0) ||
                            (b[62:52] == 11'h7ff && b[51:0] != 0) ||
                            (a[62:52] == 11'd0 && b[62:52] == 11'd0) ||
                            (a[62:52] == 11'h7ff && b[62:52] == 11'h7ff))
                            special_result_q <= QNAN;
                        else if (a[62:52] == 11'h7ff || b[62:52] == 11'd0)
                            special_result_q <= {a[63]^b[63], 11'h7ff, 52'd0};
                        else
                            special_result_q <= {a[63]^b[63], 63'd0};
                        state <= DIVIDE;
                    end
                end
                // DIVIDE: begin
                //     if (special_q) begin
                //         state <= FINISH;
                //     end else begin
                //         quotient_q  <= {quotient_q[53:0], qbit0, qbit1};
                //         remainder_q <= rem2;
                //         cycles_left <= cycles_left - 6'd1;
                //         if (cycles_left == 5'd1)
                //             state <= FINISH;
                //     end
                // end
                DIVIDE: begin
                 	quotient_q  <= {quotient_q[53:0], qbit0, qbit1};
                 	remainder_q <= rem2;
                 	cycles_left <= cycles_left - 5'd1;
                 	if (cycles_left == 5'd1)
                   	state <= FINISH;
                end
                FINISH: begin : pack_stage
                    logic [52:0] mant;
                    logic [53:0] rounded;
                    logic g, r, s, inc;
                    logic signed [12:0] exp;
                    if (special_q) begin
                        result <= special_result_q;
                    end else begin
                        exp = exponent_q;
                        if (quotient_q[55]) begin
                            mant = quotient_q[55:3];
                            g = quotient_q[2];
                            r = quotient_q[1];
                            s = quotient_q[0] | (remainder_q != 0);
                        end else begin
                            mant = quotient_q[54:2];
                            g = quotient_q[1];
                            r = quotient_q[0];
                            s = (remainder_q != 0);
                            exp = exp - 13'sd1;
                        end
                        inc = g && (r || s || mant[0]);
                        rounded = {1'b0, mant} + {53'd0,inc};
                        if (rounded[53]) begin
                            rounded = rounded >> 1;
                            exp = exp + 13'sd1;
                        end
                        if (exp >= 13'sd2047)
                            result <= {sign_q, 11'h7ff, 52'd0};
                        else if (exp <= 13'sd0)
                            result <= {sign_q, 63'd0};
                        else
                            result <= {sign_q, exp[10:0], rounded[51:0]};
                    end
                    busy  <= 1'b0;
                    valid <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
