/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_gen_x.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_gen_x
 *    Create Date : Oct 4th 2026
 *    Last Update : Oct 4th 2026
 *    Description : Generate x value for Ber_exp(x,ccs)
 ******************************************************************************
  History:

 ******************************************************************************/

 `include "falcon_header.svh"

 	module falcon_gen_x (
 		input 																		clk,
 		input 																		rst_n,
 		input																			valid,
 		output  logic															valid_o,

 		input          [`FPU_STAND - 1 : 0] 			mu,
 		//input 			   [`FALCON_CCS - 1 : 0]   		ccs,         	// fixed point Q1.63 from ccs_2p_gen
    input 			   [`FALCON_SQR_P - 1 : 0] 		o_sqr, 					// fixed point Q0.64 from ccs_2p_gen
    input 			 	 [`FALCON_SPLERZ - 1 : 0] 	z0,							// from falcon_sampler
 		input 	signed [`FALCON_SPLERZ - 1 : 0] 	z,              // from falcon_sampler
 		output 	logic signed [15 : 0]            	s,							// in front of point Q16.48
 		output  logic  [`FALCON_X - 1 : 0] 				x 							// Q8.56 to Ber_exp
 	);

 		localparam o_max_sqr = 64'h269F178307778416;   						// Q0.64 (fixed point) for 1 / (2 * o_max^2)

 		typedef enum logic[1 : 0] {
 			ST_IDLE,
 			ST_PHASE_1,
 			ST_PHASE_2
 		} state_t;


 		logic signed [`FPU_STAND - 1 : 0] 			mu_fxp;
   	logic signed [47 : 0]             			r;
   	logic signed [`FALCON_SPLERZ - 1 : 0] 	r_fxp;      			// back of point Q16.48
   	//logic signed [15 : 0]             			s;      					// in front of point Q16.48
   	logic signed [`FALCON_SPLERZ - 1 : 0] 	diff_zr;

   	logic [`MULTI_N - 1 : 0]    abs_diff_zr;
   	logic [`MULTI_N - 1 : 0] 		a1,b1;
   	logic [`MULTI_N - 1 : 0] 		a2,b2;
   	logic [2*`MULTI_N - 1 : 0] 	p1;
   	logic [2*`MULTI_N - 1 : 0] 	p2;

   	logic [3 : 0] idx_1;
   	logic [3 : 0] idx_2;

   	state_t curr_state, next_state;


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


   	/******************************************************************/
   	/******************************************************************/
   	/**
   	 * Algorithm 15 SamplerZ
   	 * *Line 1 : r ← µ − ⌊µ⌋
   	 * *Line 7 : z - r 
   	 * */
   	always_comb begin
   		mu_fxp  = converter_fpu_q16_48_signed(mu);
   			// r      = mu_fxp[47 : 0];
   			// r_fxp  = {16'd0, r};
   		s       = mu_fxp[63 : 48];
   		diff_zr = z - {16'd0, mu_fxp[47 : 0]};
   	end

   	/******************************************************************/
   	/******************************************************************/
   	/**
   	 * Current state logic
   	 * */
   	always_ff @(posedge clk) begin
   		if(!rst_n)
   			curr_state <= ST_IDLE;
   		else
   			curr_state <= next_state;
   	end

    /******************************************************************/
   	/******************************************************************/
   	/**
   	 * Next state logic
   	 * */
   	always_comb begin
   		next_state = curr_state;
   		case(curr_state)
   			ST_IDLE		 : 	if(valid) next_state = ST_PHASE_1;
   			ST_PHASE_1 :	if(idx_1 == 15) next_state = ST_PHASE_2;
   			ST_PHASE_2 : 	if(idx_2 == 15) next_state = ST_IDLE;
   			default 	 : 	next_state = ST_IDLE;
   		endcase
   	end

   	/******************************************************************/
   	/******************************************************************/
   	/**
   	 * Blocking logic
   	 * */
   	always_comb begin
   		  abs_diff_zr = '0;
   			a1 = '0;
   			b1 = '0;
   			a2 = '0;
   			b2 = '0;
   		case(curr_state)
   			ST_IDLE: begin
   				if(valid) begin
   					abs_diff_zr = diff_zr[63] ? -diff_zr : diff_zr;
   					a1 = abs_diff_zr;
   					b1 = abs_diff_zr;
   					a2 = z0;
   					b2 = z0;
   				end
   			end 
   			ST_PHASE_1: begin
   				if(idx_1 == 15) begin
   					a1 = p1[111 : 48];
   					b1 = o_sqr;
   					a2 = {54'd0, p2[9 : 0]};
   					b2 = o_max_sqr;
   				end
   			end
   			ST_PHASE_2: begin
   			end
   			default : begin
   				abs_diff_zr = '0;
   				a1 = '0;
   				b1 = '0;
   				a2 = '0;
   				b2 = '0;
   			end
   		endcase
   	end

   	/******************************************************************/
   	/******************************************************************/
   	/**
   	 * Nonblocking logic
   	 * */
   	always_ff @(posedge clk) begin
   		if(!rst_n) begin
   			idx_1 	<= '0;
   			idx_2 	<= '0;
   			valid_o	<= 1'b0;
   			x 			<= '0;
   		end else begin
   			case (curr_state)
   				ST_IDLE: begin
   					idx_1 	<= '0;
   					idx_2 	<= '0;
   					valid_o	<= 1'b0;
   				end
   				ST_PHASE_1: begin
   					idx_1 <= idx_1 + 1;
   				end
   				ST_PHASE_2: begin
   					idx_2 <= idx_2 + 1;
   					if(idx_2 == 15) begin
   						valid_o <= 1'b1;
   						if(p1[119 : 56] < p2[71 : 8])
   							x <= '0;
   						else
   							x <= p1[119 : 56] - p2[71 : 8];
   					end
   				end
   				default : begin
   					idx_1 	<= '0;
   					idx_2 	<= '0;
   					valid_o	<= 1'b0;
   					x 			<= '0;		
   				end
   			endcase
   		end
   	end
  endmodule


