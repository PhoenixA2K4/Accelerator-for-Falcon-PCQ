/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_keccakf.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_keccakf
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : Keccak-f for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/

 // `include "SHAKE_pkg.sv"
 import SHAKE_pkg ::*;

 module shake_keccakf(
 	input              				clk,
 	input              				rst_n,
 	input              				en_kf,
 	input 										interrupt,
 	input 				[4 : 0]			summand,
 	input 				[4 : 0]		 	idx_i,	
 	input   			[1599 : 0] 	S_in,
 	output  logic	[1599 : 0] 	S_out,
 	output	logic [4 : 0]			idx_o,
 	output 	logic							en_loop,
 	output 	logic							flag_ctrl
 );

	logic   en_f2, en_f3, en_f4;
	logic   [1599 : 0] str_stg;

	d2_arr  data_stg2;
	d3_arr  data_stg3, data_stg4;

	logic 	[63 : 0] 	RC_data;
	logic 	[4 : 0] 	idx_f2;
	logic 	[4 : 0] 	idx_f3;
	logic 	[4 : 0] 	idx_f4;
	logic 	[4 : 0]		idx_f4_tmp;


 	shake_theta1 STG_1 (
 		.clk    (clk),
 		.rst_n  (rst_n),
 		.en_f1  (en_kf),
 		.idx_i 	(idx_i),
 		.S_in   (S_in),
 		.data_o (data_stg2),
 		.S_out  (str_stg),
 		.idx_o 	(idx_f2),
 		.en_f2  (en_f2)
 	);

 	shake_theta2_rho_pi STG_2 (
  	.clk    (clk),
  	.rst_n  (rst_n),
  	.en_f2  (en_f2),
  	.idx_i 	(idx_f2),
  	.S_in   (str_stg),
  	.data_i (data_stg2),
  	.data_o (data_stg3),
  	.idx_o	(idx_f3),
  	.en_f3  (en_f3)
 	);

 	shake_chi STG_3 (
  	.clk    (clk),
  	.rst_n  (rst_n),
  	.en_f3  (en_f3),
  	.idx_i 	(idx_f4_tmp),
  	.idx_o 	(idx_f4),
  	.data_i (data_stg3),
  	.data_o (data_stg4),
  	.en_f4  (en_f4)
 	);

 	shake_iota STG_4 (
  	.clk        (clk),
  	.rst_n      (rst_n),
  	.en_f4      (en_f4),
  	.interrupt	(interrupt),
  	.RC_data    (RC_data),
  	.data_i   	(data_stg4),
  	.en_loop  	(en_loop),
  	.flag_ctrl	(flag_ctrl),
  	.data_o			(S_out)
 	);

 	shake_RC RC (
 		.index 	(idx_f4),
 		.RC_out	(RC_data)
 	);

 	shake_pointer RC_Pointer (
 		.a			(idx_f3),
 		.b			(summand),
 		.y			(idx_f4_tmp)
 	);

 	assign idx_o = idx_f4;
endmodule