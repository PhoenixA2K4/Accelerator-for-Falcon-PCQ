/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_header
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_header.svh
 *    Create Date : Aug 23th 2026
 *    Last Update : Aug 23th 2026
 *    Description : Header for Falcon Accelerator
 ******************************************************************************
  History:

 ******************************************************************************/

`ifndef FALCON_DEFINES_SVH
`define FALCON_DEFINES_SVH

`define FALCON_N                                512
`define FALCON_LOGN                             9
`define FALCON_Q                                12289
`define FALCON_Q_BITS                           14


// Base_Sampler
`define FALCON_REVERSE_CUMULATIVE_DATA_WIDTH    72
`define FALCON_PROBABILITY_DATA_WIDTH           72
`define FALCON_CUMULATIVE_DATA_WIDTH            72

`define FALCON_REVERSE_CUMULATIVE_DEPTH         18
`define FALCON_PROBABILITY_DEPTH                19
`define FALCON_CUMULATIVE_DEPTH                 19

`define FALCON_UNIFORM_BITS_BASE_SAMPLER        72


// ApproxExp & Ber_Exp
`define FALCON_CCS                      64
`define FALCON_X                        64
`define FALCON_Y                        64
`define FALCON_C_QUANTITY               13
`define FALCON_UNIFORM_BITS_BER_EXP     8

// Multiplier parameter and FPU divider
`define MULTI_N             64
`define FPU_SIGN            1
`define FPU_EXPO            11
`define FPU_FRAC            52
`define FPU_STAND           64


// SamplerZ
`define FALCON_SQR_P                    64
`define FALCON_SPLERZ                   64
`define FALCON_UNIFORM_BITS_SAMPLERZ    88
`define FALCON_Z                        16



function automatic logic [63:0] converter_fpu_q1_63(input logic [63:0] fp_in);
    logic [10:0] exp;
    logic [51:0] frac;
    logic [63:0] res;
    
    exp  = fp_in[62:52];
    frac = fp_in[51:0];
    
    if (exp == 11'd0) begin
        res = 64'd0;
    end else if (exp >= 11'd1023) begin
        res = 64'h8000_0000_0000_0000;
    end else if (exp == 11'd1022) begin
        res = {1'b0, 1'b1, frac, 10'b0};
    end else begin
        // Các trường hợp shift > 1 khác
        res = ({1'b1, frac, 10'b0} >> (11'd1022 - exp));
    end
    return res;
endfunction



function automatic logic signed [63:0] converter_fpu_q16_48_signed(input logic [63:0] fp_in);
    logic        sign;
    logic [10:0] exp;
    logic [51:0] frac;
    logic [52:0] mantissa;
    logic signed [11:0] shift_amt;
    logic [99:0] aligned_mantissa;
    logic [63:0] mag_q;
    logic signed [63:0] res;

    sign     = fp_in[63];
    exp      = fp_in[62:52];
    frac     = fp_in[51:0];
    mantissa = {1'b1, frac};

    aligned_mantissa = {mantissa, 47'd0};
    shift_amt        = 12'd1074 - {1'b0, exp};

    if (exp == 11'd0) begin
        mag_q = 64'd0;
    end else if (exp >= 11'd1039) begin
        mag_q = 64'h7FFF_FFFF_FFFF_FFFF;
    end else if (shift_amt >= 12'd100) begin
        mag_q = 64'd0;
    end else begin
        mag_q = (aligned_mantissa >> shift_amt);
    end

    if (sign) begin
        res = (exp >= 11'd1039) ? 64'h8000_0000_0000_0000 : (-mag_q);
    end else begin
        res = mag_q;
    end

    return res;
endfunction

`endif
