/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_256.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_256
 *    Create Date : Oct 24th 2026
 *    Last Update : Oct 24th 2026
 *    Description : SHAKE-256 - File top
 ******************************************************************************
  History:

 ******************************************************************************/

module shake_256 (
	input 										clk,
	input 										rst_n,
	input 										start,
	input 				[383 	: 0] 	seed,
	output	logic	[1087 : 0]	hash,
	output 	logic							done
);

	logic [1599 : 0] new_seed;
	logic [1599 : 0] S_in;
	logic [1599 : 0] data_d1x2s;

	logic [4 : 0] summand;
	logic [4 : 0] idx_o;
	logic	[4 : 0] idx_i;

	logic m2x1s_en;
	logic d1x2s_en;
	logic interrupt;
	logic en_loop;
	logic flag_ctrl;

	shake_padding Padding (
		.msg				(seed),
		.Sp 				(new_seed)
	);

	M2X1S M2X1S (
		.A     			(new_seed),
		.B     			(data_loop),
		.sel   			(m2x1s_en),
		.data_o			(S_in)
	);

	shake_keccakf Keccak_f (
		.clk      	(clk),
		.rst_n			(rst_n),
		.en_kf    	(start || en_loop),
		.interrupt	(interrupt),
		.summand  	(summand),
		.idx_i    	(idx_i),
		.S_in     	(S_in),
		.S_out    	(data_d1x2s),
		.en_loop  	(en_loop),
		.flag_ctrl	(flag_ctrl)
	);

	D1X2S D1X2S (
		.clk   			(clk),
		.rst_n			(rst_n),
		.data_i			(data_d1x2s),
		.sel   			(d1x2s_en),
		.A     			(data_loop),
		.B     			(hash)
	);

	shake_round_ctrl Controller (
		.clk				(clk),
		.start			(start),
		.rst_n			(rst_n),
		.flag_ctrl	(flag_ctrl),
		.idx_i			(idx_o),
		.idx_o			(idx_i),
		.summand		(summand),
		.d1x2s_en		(d1x2s_en),
		.m2x1s_en		(m2x1s_en),
		.interrupt	(interrupt),
		.done				(done)
	);

endmodule