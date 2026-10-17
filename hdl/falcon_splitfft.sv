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
										Ensure: FFT(f0) = (f0(ζ′))ζ′ and FFT(f1) = (f1(ζ′))ζ′
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
 
 endmodule : falcon_splitfft