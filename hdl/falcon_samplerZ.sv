/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_samplerZ
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_samplerZ.sv
 *    Create Date : Sep 1st 2026
 *    Last Update : Sep 1st 2026
 *    Description : ApproxExp -> BerExp -> SamplerZ
 ******************************************************************************
  History:

 ******************************************************************************/

 // ** Lưu ý luồng họat động của uniform_bits để code PRNG : request gửi 1 đến PRNG / thì asser clk sau PRNG mới gửi uniforms_bits ra (Duy viết)

 `include "falcon_header.svh"

 module falcon_samplerZ (
    input   clk,
    input   rst_n,
    input   start,
    output  logic done,
    output  logic request,    // to PRNG
    input   logic [`FPU_STAND - 1 : 0] o_dot,
    input   logic [`FPU_STAND - 1 : 0]    mu,     // fp64
    input   logic [`FALCON_UNIFORM_BITS_SAMPLERZ - 1 : 0] uniform_bits, // for b and basesampler, ber_exp
    output  logic signed [`FALCON_Z - 1 : 0] z  
);

   localparam o_max_sqr = 64'h269E16886A343011;   // Q0.64 (fixed point) for 1 / (2 * o_max^2)

   logic ber_done;
   logic ber_check;
   logic p2_gen_valid;
   logic ccs_ready;

   logic ber_en;
   logic p2_gen_en;

   logic signed [`FPU_STAND - 1 : 0] mu_fxp;
   logic signed [47 : 0]             r;
   logic signed [`FALCON_SPLERZ - 1 : 0] r_fxp;      // back of point Q16.48
   logic signed [15 : 0]             s;      // in front of point Q16.48

   logic [`FALCON_CCS - 1 : 0]   ccs;
   logic [`FALCON_SQR_P - 1 : 0] o_sqr;

   logic [`FALCON_X - 1 : 0] x;
   logic [`FALCON_X - 1  : 0] x1, x2;
   logic [ 1 : 0]en_BSL;

   logic signed [5 : 0] z_tmp;
   logic [4 : 0] z0;
   logic signed [`FALCON_SPLERZ - 1 : 0] z_fxp;
   logic signed [`FALCON_SPLERZ - 1 : 0] diff_zr;
   logic [`MULTI_N - 1 : 0]              abs_diff_zr;

   logic [`MULTI_N - 1 : 0] numer_1, numer_2;
   logic [3 : 0] idx_2;
   logic [4 : 0] idx_1;

   logic [`MULTI_N - 1 : 0] a1,b1,a2,b2;
   logic [2 * `MULTI_N -  1 : 0] p1,p2;

   falcon_ber_exp ber_exp(
      .clk           (clk),
      .rst_n         (rst_n),
      .start         (ber_en),
      .x             (x),
      .ccs           (ccs),
      .uniform_bits  (uniform_bits[`FALCON_UNIFORM_BITS_SAMPLERZ - 1 : 80]),
      .check_bit     (ber_check),
      .done          (ber_done)
   );

   falcon_base_sampler base_sampler(
      .clk           (clk),
      .rst_n         (rst_n),
      .uniform_bits  (uniform_bits[71 : 0]),
      .z0            (z0)
   );

   falcon_ccs_2p_gen CCS_2P_GEN(
      .clk     (clk),
      .rst_n   (rst_n),
      .start   (p2_gen_en),
      .done    (p2_gen_valid),
      .o_dot   (o_dot),
      .ccs     (ccs),
      .o_sqr   (o_sqr)
   );

   radix_4_16d #(.N(`MULTI_N))
   multiplier_16d_1(
      .clk     (clk),
      .rst_n   (rst_n),
      .a       (a1),
      .b       (b1),
      .p       (p1)
   );

   radix_4_16d #(.N(`MULTI_N))
   multiplier_16d_2(
      .clk     (clk),
      .rst_n   (rst_n),
      .a       (a2),
      .b       (b2),
      .p       (p2)
   );


   typedef enum logic[2 : 0] {
      ST_IDLE,
      ST_REQ,
      ST_BSL,
      ST_CAL_XS1,
      ST_CAL_XS2,
      ST_CHECK,
      ST_BER
   }state_t;

   state_t next_state, curr_state;


   assign mu_fxp = converter_fpu_q16_48_signed(mu);
   assign r      = mu_fxp[47 : 0];
   assign s      = mu_fxp[63 : 48];
   assign r_fxp  = {16'd0, r};






   always_ff @(posedge clk) begin
      if(!rst_n)
         curr_state <= ST_IDLE;
      else
         curr_state <= next_state;
   end


   always_comb begin

      next_state = curr_state;

      case (curr_state)
         ST_IDLE     : if(start) next_state = ST_REQ;

         ST_REQ      : next_state = ST_BSL;

         ST_BSL      : if(en_BSL == 2) next_state = ST_CAL_XS1;

         ST_CAL_XS1  : if((ccs_ready || p2_gen_valid) & (idx_1 > 16)) next_state = ST_CAL_XS2;

         ST_CAL_XS2  : if(&idx_2) next_state = ST_CHECK;

         ST_CHECK    : next_state = ST_BER;

         ST_BER      : begin
            if(ber_done) begin
               if(ber_check)
                  next_state = ST_IDLE;
               else
                  next_state = ST_REQ;
            end
         end
         default : next_state = ST_IDLE;
      endcase
   end


   always_comb begin

         p2_gen_en = 1'b0;
         request   = 1'b0;
         {a1, b1}  = '0;
         {a2, b2}  = '0;
         x         = '0;
         ber_en    = 1'b0;
         diff_zr   = '0;
         abs_diff_zr = '0;
         x1          = '0;
         x2          = '0;

      case (curr_state)
         ST_IDLE     : if(start) p2_gen_en = 1'b1;

         ST_REQ      : request = 1'b1;

         ST_BSL      : begin

         end
         
         ST_CAL_XS1  : begin
            diff_zr     = z_fxp - r_fxp;
            abs_diff_zr = diff_zr[63] ? -diff_zr : diff_zr;

            a2 = {59'd0, z0};
            b2 = a2;
            a1 = abs_diff_zr;
            b1 = abs_diff_zr;
         end

         ST_CAL_XS2  : begin
            a1 = numer_1;
            b1 = o_sqr;
            a2 = numer_2;
            b2 = o_max_sqr;
         end

         ST_CHECK    : begin
            x1 = p1[119 : 56];
            x2 = p2[71 : 8];
            ber_en = 1'b1;
            if(x1 < x2) begin
               x      = '0;
            end
            else begin
               x      = x1 - x2;
            end
         end

         ST_BER      : begin
         end
         default : begin
            diff_zr   = '0;
            abs_diff_zr = '0;
            p2_gen_en = 1'b0;
            request   = 1'b0;
            {a1, b1}  = '0;
            {a2, b2}  = '0;
            x         = '0;
            ber_en    = 1'b0;
            x1        = '0;
            x2        = '0;
         end
      endcase
   end


   always_ff @(posedge clk) begin
      if(!rst_n) begin
         done        <= 1'b0;
         idx_1       <= 1'b0;
         idx_2       <= 1'b0;
         z_fxp       <= '0;
         numer_1     <= '0;
         numer_2     <= '0;
         z           <= '0;
         ccs_ready   <= 1'b0;
         en_BSL      <= 2'b00;
      
      end else begin
         case (curr_state)
            ST_IDLE     : done <= 1'b0;

            ST_REQ      : begin
               idx_1 <= '0;
               idx_2 <= '0;
            end

            ST_BSL      : begin
               en_BSL <= en_BSL + 1;
               if(en_BSL == 1) begin        
                  if(uniform_bits[72])
                     z_tmp <= $signed({1'b0, z0}) + 6'sd1;
                  else
                     z_tmp <= -$signed({1'b0, z0});
               end
               if(en_BSL == 2)z_fxp <= {{10{z_tmp[5]}}, z_tmp, 48'd0};
            end

            ST_CAL_XS1  : begin
               en_BSL <= 2'b00;
               if(p2_gen_valid == 1 ) ccs_ready <= 1'b1;
               if(idx_1 < 5'd16)
                  idx_1 <= idx_1 + 1;
               else if(idx_1 == 16) begin
                  numer_1 <= p1[111 : 48];
                  numer_2 <= {54'd0, p2[9 : 0]};
                  idx_1   <= idx_1 + 1;
               end
            end

            ST_CAL_XS2  : idx_2 <= idx_2 + 1;

            ST_CHECK    : begin
               // if(x1 < x2) begin
               //    z         <= {{10{z_tmp[5]}}, z_tmp} + s;
               //    done      <= 1'b1;
               // end
            end

            ST_BER      : begin
               if(ber_done) begin
                  if(ber_check) begin
                     z <= {{10{z_tmp[5]}}, z_tmp} + s;
                     done  <= 1'b1;
                  end  
                  else z <= '0;
               end
            end
         
            default : begin
               done        <= 1'b0;
               idx_1       <= 1'b0;
               idx_2       <= 1'b0;
               z_fxp       <= '0;
               numer_1     <= '0;
               numer_2     <= '0;
               ccs_ready   <= 1'b0;
               z           <= '0;
               en_BSL      <= 2'b00;
            end
         endcase
      end
   end
endmodule : falcon_samplerZ