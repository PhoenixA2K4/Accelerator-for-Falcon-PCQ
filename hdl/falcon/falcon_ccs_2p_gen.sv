/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_ccs_2p_gen
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_ccs_2p_gen.sv
 *    Create Date : Sep 1st 2026
 *    Last Update : Sep 1st 2026
 *    Description : Calculate ccs and 1 / (2 * o'^2) for step 2 & 7 in SamplerZ
 ******************************************************************************
  History:

 ******************************************************************************/

 `include "falcon_header.svh"

 module falcon_ccs_2p_gen (
    input         												clk,
    input         												rst_n,
    input         												start,
    output  logic 												done,
    input   logic [`FPU_STAND - 1 : 0] 		o_dot,        	// FPU
    output  logic [`FALCON_CCS - 1 : 0]   ccs,        		// fixed point Q1.63
    output  logic [`FALCON_SQR_P - 1 : 0] o_sqr      			// fixed point Q0.64
);

      localparam o_min     = 64'h3FF47201BF2577E7;    		// FPU for phi min
      localparam o_min_sqr = 64'h4E63DE84E5EE3645;    		// Q0.64 (fixed point) for 1 / (2 * o_min^2)
      localparam o_max_sqr = 64'h269F178307778416;   			// Q0.64 (fixed point) for 1 / (2 * o_max^2)


      logic 		[`MULTI_N - 1 : 0]  a;
      logic 		[`MULTI_N - 1 : 0]  b;
      logic [2 * `MULTI_N - 1 : 0] 	p;

      logic div_en;
      logic div_valid;

      logic [`FPU_STAND - 1 : 0] q;

      logic [3 : 0] idx_1, idx_2;


      radix_4_16d #(.N(`MULTI_N))
      multiplier_16d(
         .clk     (clk),
         .rst_n   (rst_n),
         .a       (a),
         .b       (b),
         .p       (p)
      );

      fpu_divider divider_fpu (
         .clk     (clk),
         .rst_n   (rst_n),
         .start   (div_en),
         .a       (o_min),
         .b       (o_dot),
         .result  (q),
         .valid   (div_valid),
         .busy    ()
      );


      typedef enum logic [1 : 0]{
         ST_IDLE    = 2'b00,
         ST_DIVIDE  = 2'b01,
         ST_SQUARE  = 2'b11,
         ST_TIME    = 2'b10
      }state_t;

      state_t curr_state, next_state;



      always_ff @(posedge clk) begin
         if(!rst_n) begin
            curr_state <= ST_IDLE;
         end else begin
            curr_state <= next_state;
         end
      end


      always_comb begin

         next_state = curr_state;

         case(curr_state)
            ST_IDLE   : begin if(start) next_state = ST_DIVIDE; end

            ST_DIVIDE : begin if(div_valid) next_state = ST_SQUARE; end

            ST_SQUARE : begin if(&idx_1) next_state = ST_TIME; end

            ST_TIME   : begin if(&idx_2) next_state = ST_IDLE; end

            default   : next_state = ST_IDLE;
         endcase
      end


      always_ff @(posedge clk) begin
         if(!rst_n) begin
            idx_1 <= '0;
            idx_2 <= '0;
            done  <= 1'b0;
            o_sqr <= '0;
            ccs   <= '0;
         end else begin
            case (curr_state)
               ST_IDLE : begin
                  idx_1 <= '0;
                  idx_2 <= '0;
                  done  <= 1'b0;
               end

               ST_DIVIDE : begin if(div_valid) ccs <= converter_fpu_q1_63(q); end

               ST_SQUARE : begin idx_1 <= idx_1 + 1; end

               ST_TIME   : begin 
                  idx_2 <= idx_2 + 1;
                  if(&idx_2) begin
                     o_sqr <= p[126 : 63];
                     done  <= 1'b1;
                  end
               end
               default : begin
                  idx_1 <= '0;
                  idx_2 <= '0;
                  done  <= 1'b0;
                  o_sqr <= '0;
                  ccs   <= '0;
               end
            endcase
         end
      end


      always_comb begin

         a      = '0;
         b      = '0;
         div_en = 1'b0;
         
         case (curr_state)
            ST_IDLE   : begin if(start) div_en = 1'b1; end

            ST_DIVIDE : begin 
               if(div_valid) begin
                  a = converter_fpu_q1_63(q);
                  b = a;
               end
            end

            ST_SQUARE : begin
               if(&idx_1) begin
                  a = p[126 : 63];
                  b = o_min_sqr;
               end
            end

            ST_TIME   : begin
            end

            default : begin
               a      = '0;
               b      = '0;
               div_en = 1'b0;
            end
         endcase
      end


endmodule