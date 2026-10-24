/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_mergefft.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_mergefft.sv
 *    Create Date : October 18th 2026
 *    Last Update : October 18th 2026
 *    Description : Require: FFT(f0) 	= (f0(ζ′))ζ′ and FFT(f1) = (f1(ζ′))ζ′
 * 									Ensure: FFT(f) 		= (f(ζ))ζ
 ******************************************************************************
  History:

 ******************************************************************************/

 `include "falcon_header.svh"

 module falcon_mergefft (
    input  logic        							clk, 
    input  logic        							rst_n,        		
    input  logic        							start,       
    input  logic [`FPU_STAND - 1 : 0]	f0_real,								//FFT(f0)
    input  logic [`FPU_STAND - 1 : 0] f0_im,      
    input  logic [`FPU_STAND - 1 : 0] f1_real,      					//FFT(f1)
    input  logic [`FPU_STAND - 1 : 0] f1_im,      
    input  logic [`FPU_STAND - 1 : 0] zeta_real,    					//ζ from ROM
    input  logic [`FPU_STAND - 1 : 0] zeta_im,    
    output logic [`FPU_STAND - 1 : 0]	f_real,									//FFT(f)
    output logic [`FPU_STAND - 1 : 0]	f_im,
    output logic        							valid_o       
);

 	logic [`FPU_STAND - 1 : 0] p_im_1;
 	logic [`FPU_STAND - 1 : 0] p_im_2;
 	logic [`FPU_STAND - 1 : 0] p_real_1;
 	logic [`FPU_STAND - 1 : 0] p_real_2;

 	logic v_m1;
 	logic v_m2;
 	logic v_m3;
 	logic v_m4;
 	logic v_s1;
 	logic v_a1;
 	logic valid_o1;
 	logic valid_o2;

 	logic [`FPU_STAND - 1 : 0] z_s1;
 	logic [`FPU_STAND - 1 : 0] z_a1;

 /******************************************************************/
 /******************************************************************/
 /**
  * 
  * */
  fpu_mul fpu_mul_1(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start		(start),
 	.a      	(zeta_real),
 	.b      	(f1_real),
 	.result 	(p_real_1),
 	.valid_o	(v_m1)
 );

  fpu_mul fpu_mul_2(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start		(start),
 	.a      	(zeta_im),
 	.b      	(f1_im),
 	.result 	(p_real_2),
 	.valid_o	(v_m2)
	);

  fpu_mul fpu_mul_3(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start		(start),
 	.a      	(zeta_real),
 	.b      	(f1_im),
 	.result 	(p_im_1),
 	.valid_o	(v_m3)
 );

  fpu_mul fpu_mul_4(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start		(start),
 	.a      	(zeta_im),
 	.b      	(f1_real),
 	.result 	(p_im_2),
 	.valid_o	(v_m4)
 );

  fpu_addsub fpu_sub(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(v_m1 && v_m2),
 	.sub    	(1),
 	.a 				(p_real_1),
 	.b 				(p_real_2),
 	.result		(z_s1),
 	.valid_o	(v_s1)
 );

  fpu_addsub fpu_add_1(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(v_m3 && v_m4),
 	.sub    	(0),
 	.a 				(p_im_1),
 	.b 				(p_im_2),
 	.result		(z_a1),
 	.valid_o	(v_a1)
 );

  fpu_addsub fpu_add_2(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(v_s1),
 	.sub    	(0),
 	.a 				(f0_real),
 	.b 				(z_s1),
 	.result		(f_real),
 	.valid_o	(valid_o1)
 );

  fpu_addsub fpu_add_3(
 	.clk    	(clk),
 	.rst_n  	(rst_n),
 	.start  	(v_a1),
 	.sub    	(0),
 	.a 				(f0_im),
 	.b 				(z_a1),
 	.result		(f_im),
 	.valid_o	(valid_o2)
 );

  assign valid_o = valid_o1 & valid_o2;

endmodule