/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_splitfft.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_splitfft.sv
 *    Create Date : October 17th 2026
 *    Last Update : October 17th 2026
 *    Description : Require: FFT(f) = (f(ζ))ζ 
 * 									Ensure: FFT(f0) = (f0(ζ′))ζ′ and FFT(f1) = (f1(ζ′))ζ′
 ******************************************************************************
  History:

 ******************************************************************************/

 `include "falcon_header.svh"

 module falcon_splitfft (
 	input 															clk,    
 	input 															rst_n,  
 	input 															valid,
 	input 	logic [`FPU_STAND - 1 : 0]	a_real,						// A = f(ζ) (IEEE 754)
 	input 	logic [`FPU_STAND - 1 : 0] 	a_im,
 	input 	logic [`FPU_STAND - 1 : 0]  b_real,						// B = f(-ζ) (IEEE 754)
 	input 	logic [`FPU_STAND - 1 : 0] 	b_im,
 	input 	logic [`FPU_STAND - 1 : 0]  w_real,						// W =  1/2ζ (IEEE 754) -> from ROM 
 	input 	logic [`FPU_STAND - 1 : 0]	w_im,
 	output 	logic [`FPU_STAND - 1 : 0]  f0_real,					// FFT(f) -> (FFT(f0), FFT(f1))
 	output 	logic [`FPU_STAND - 1 : 0]	f0_im,
 	output 	logic [`FPU_STAND - 1 : 0]  f1_real,
	output 	logic [`FPU_STAND - 1 : 0]	f1_im,
	output 	logic 											valid_o
 );

 localparam div = 64'h4000000000000000;

 /**
  * FSM state
  * */
 	typedef enum logic[1 : 0]{
 		ST_IDLE,
 		ST_STAGE_1,
 		ST_STAGE_2,
 		ST_STAGE_3
 	}state_t;

 	state_t curr_state;
 	state_t next_state;


 /**
  * adder - fpu signals
  * */
 	logic 											s_a1;
 	logic												v_a1;
 	logic [`FPU_STAND - 1 : 0] 	x_a1;
 	logic [`FPU_STAND - 1 : 0] 	y_a1;
 	logic [`FPU_STAND - 1 : 0] 	z_a1;

 	logic 											s_a2;
 	logic 											v_a2;	
 	logic [`FPU_STAND - 1 : 0] 	x_a2;
 	logic [`FPU_STAND - 1 : 0] 	y_a2;
 	logic [`FPU_STAND - 1 : 0] 	z_a2;

 /**
  * subcriber - fpu signals
  * */
 	logic 											s_s1;
 	logic 											v_s1;	
 	logic [`FPU_STAND - 1 : 0] 	x_s1;
 	logic [`FPU_STAND - 1 : 0] 	y_s1;
 	logic [`FPU_STAND - 1 : 0] 	z_s1;

 	logic 											s_s2;
 	logic 											v_s2;
 	logic [`FPU_STAND - 1 : 0] 	x_s2;
 	logic [`FPU_STAND - 1 : 0] 	y_s2;
 	logic [`FPU_STAND - 1 : 0] 	z_s2;

 /**
  * divider - fpu signals
  * */
 	logic 											s_d1;
 	logic 											v_d1;
 	logic [`FPU_STAND - 1 : 0] 	x_d1;
 	logic [`FPU_STAND - 1 : 0] 	z_d1;

 	logic 											s_d2;
 	logic 											v_d2;
 	logic [`FPU_STAND - 1 : 0] 	x_d2;
 	logic [`FPU_STAND - 1 : 0] 	z_d2;

 /**
  * multiplier - fpu signals
  * */
  logic 											s_m1;
 	logic 											v_m1;
 	logic [`FPU_STAND - 1 : 0] 	x_m1;
 	logic [`FPU_STAND - 1 : 0] 	z_m1;

 	logic 											s_m2;
 	logic 											v_m2;
 	logic [`FPU_STAND - 1 : 0] 	x_m2;
 	logic [`FPU_STAND - 1 : 0] 	z_m2;

 	logic 											s_m3;
 	logic 											v_m3;
 	logic [`FPU_STAND - 1 : 0] 	x_m3;
 	logic [`FPU_STAND - 1 : 0] 	z_m3;

 	logic 											s_m4;
 	logic 											v_m4;
 	logic [`FPU_STAND - 1 : 0] 	x_m4;
 	logic [`FPU_STAND - 1 : 0] 	z_m4;


 fpu_addsub fpu_add_1(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(s_a1),
 	.sub    	(0),
 	.a 				(x_a1),
 	.b 				(y_a1),
 	.result		(z_a1),
 	.valid_o	(v_a1)
 );

 fpu_addsub fpu_add_2(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(s_a2),
 	.sub    	(0),
 	.a 				(x_a2),
 	.b 				(y_a2),
 	.result		(z_a2),
 	.valid_o	(v_a2)
 );

 fpu_addsub fpu_sub_1(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(s_s1),
 	.sub    	(1),
 	.a 				(x_s1),
 	.b 				(y_s1),
 	.result		(z_s1),
 	.valid_o	(v_s1)
 );

 fpu_addsub fpu_sub_2(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(s_s2),
 	.sub    	(1),
 	.a 				(x_s2),
 	.b 				(y_s2),
 	.result		(z_s2),
 	.valid_o	(v_s2)
 );

 fpu_divider fpu_div_1(
 	.clk   		(clk),
 	.rst_n 		(rst_n),
 	.start 		(s_d1),
 	.a 				(x_d1),
 	.b 				(div),
 	.result 	(z_d1),
 	.valid 		(v_d1),
 	.busy 		()
 );

 fpu_divider fpu_div_2(
 	.clk   		(clk),
 	.rst_n 		(rst_n),
 	.start 		(s_d2),
 	.a 				(x_d2),
 	.b 				(div),
 	.result 	(z_d2),
 	.valid 		(v_d2),
 	.busy 		()
 );

 fpu_mul fpu_mul_1(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start		(s_m1),
 	.a      	(x_m1),
 	.b      	(w_im),
 	.result 	(z_m1),
 	.valid_o	(v_m1)
 );

 fpu_mul fpu_mul_2(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(s_m2),
 	.a      	(x_m2),
 	.b      	(w_im),
 	.result 	(z_m2),
 	.valid_o	(v_m2)
 );

 fpu_mul fpu_mul_3(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(s_m3),
 	.a      	(x_m3),
 	.b      	(w_real),
 	.result 	(z_m3),
 	.valid_o	(v_m3)
 );

 fpu_mul fpu_mul_4(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(s_m4),
 	.a      	(x_m4),
 	.b      	(w_real),
 	.result 	(z_m4),
 	.valid_o	(v_m4)
 );




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
  * next state logic
  * */
  always_comb begin
  	next_state = curr_state;
  	case (curr_state)
  		ST_IDLE: 		if(valid) next_state = ST_STAGE_1;
  		ST_STAGE_1: if(v_a1 && v_a2 && v_s1 && v_a2) next_state = ST_STAGE_2;
  		ST_STAGE_2: if(v_m1 && v_m2 && v_m3 && v_m4) next_state = ST_STAGE_3;
  		ST_STAGE_3: if(v_s1 && v_a1) next_state = ST_IDLE;
  		default: next_state = ST_IDLE;
  	endcase
  end

 /******************************************************************/
 /******************************************************************/
 /**
  * Blocking logic
  * f0_real = a_real + b_real / 2
  * f0_im   = a_im + b_im / 2
  * 
  * d_real	= a_real - b_real
  * d_im  	= a_im - b_im
  * f1_real = d_real*w_real - d_im*w_im
  * f1_im 	= d_real*w_im + d_im*w_real  
  * */
  always_comb begin
  	s_a1 = 0;
  	s_a2 = 0;
  	s_s1 = 0;
  	s_s2 = 0;
  	x_a1 = 0;
  	x_a2 = 0;
  	x_s1 = 0;
  	x_s2 = 0;
  	y_a1 = 0;
  	y_a2 = 0;
  	y_s1 = 0;
  	y_s2 = 0;
  	s_m1 = 0;
  	s_m2 = 0;
  	s_m3 = 0;
  	s_m4 = 0;
  	s_d1 = 0;
  	s_d2 = 0;
  	x_d1 = 0;
  	x_d2 = 0;
  	x_m1 = 0;
  	x_m2 = 0;
  	x_m3 = 0;
  	x_m4 = 0;
  	case (curr_state)
  	ST_IDLE: begin
  		if(valid) begin
  			//a_real + b_real
  			s_a1 = 1;
  			x_a1 = a_real;
  			y_a1 = b_real;
  			//a_im + b_im
  			s_a2 = 1;
  			x_a2 = a_im;
  			y_a2 = b_im;
  			//d_real = a_real - b_real
  			s_s1 = 1;
  			x_s1 = a_real;
  			y_s1 = b_real;
  			//d_im = a_im - b_im
  			s_s2 = 1;
  			x_s2 = a_im;
  			y_s2 = b_im;
  		end
  	end
  	ST_STAGE_1: begin
  		//(a_real + b_real)/2
  		if(v_a1) begin
  			s_d1 = 1;
  			x_d1 = z_a1;
  		end
  		//(a_im + b_im)/2
  		if(v_a2) begin
  			s_d2 = 1;
  			x_d2 = z_a2;
  		end
  		//d_real*w_im
  		//d_real*w_real
  		if(v_s1) begin
  			s_m1 = 1;
  			s_m3 = 1;
  			x_m3 = z_s1;
  			x_m1 = z_s1;
  		end
  		//d_im*w_im
  		//d_im*w_real
  		if(v_s2) begin
  			s_m2 = 1;
  			s_m4 = 1;
  			x_m2 = z_s2;
  			x_m4 = z_s2;
  		end
  	end
  	ST_STAGE_2: begin
  		//f1_real
  		if(v_m2 && v_m3) begin
  			x_s1 = z_m3;
  			y_s1 = z_m2;
  			s_s1 = 1;
  		end
  		//f1_im
  		if(v_m1 && v_m4) begin
  			x_a1 = z_m1;
  			y_a1 = z_m4;
  			s_a1 = 1;
  		end
  	end
  	ST_STAGE_3: begin
  	end
  	default: begin
  		s_a1 = 0;
  		s_a2 = 0;
  		s_s1 = 0;
  		s_s2 = 0;
  		x_a1 = 0;
  		x_a2 = 0;
  		x_s1 = 0;
  		x_s2 = 0;
  		y_a1 = 0;
  		y_a2 = 0;
  		y_s1 = 0;
  		y_s2 = 0;
  		s_m1 = 0;
  		s_m2 = 0;
  		s_m3 = 0;
  		s_m4 = 0;
  		s_d1 = 0;
  		s_d2 = 0;
  		x_d1 = 0;
  		x_d2 = 0;
  		x_m1 = 0;
  		x_m2 = 0;
  		x_m3 = 0;
  		x_m4 = 0;
  	end
  endcase
  end

 /******************************************************************/
 /******************************************************************/
 /**
  * Non-Blocking logic 
  * */
  always_ff @(posedge clk) begin
  	if(!rst_n) begin
  		 f1_real 	<= 0;
  		 f1_im  	<= 0;
  	end else begin
  		if(v_s1) f1_real <= z_s1;
  		if(v_a1) f1_im 	 <= z_a1;
  	end
  end

 /******************************************************************/
 /******************************************************************/
 /**
  * Get result from fpu_divider (latency = 57) 
  * */
  always_ff @(posedge clk) begin
  	if(!rst_n) begin
  		f0_real <= 0;
  		f0_im   <= 0;
  	end else begin
  		if(v_d1 && v_d2) begin
  			f0_im 	<= z_d2;
  			f0_real	<= z_d1;
  			valid_o <= 1'b1;
  		end
  		else
  			valid_o <= 1'b0; 
  	end
  end
 endmodule : falcon_splitfft