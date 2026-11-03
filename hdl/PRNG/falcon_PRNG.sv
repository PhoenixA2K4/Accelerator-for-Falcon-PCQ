/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_PRNG.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_PRNG
 *    Create Date : Oct 27th 2026
 *    Last Update : Oct 27th 2026
 *    Description :	Generate "variable uniforms bit"
 ******************************************************************************
  History:

 ******************************************************************************/

 `include "falcon_header.svh"

module falcon_PRNG #(
	parameter int S = 1088
	)(
	input 																										clk,
	input 																										rst_n,
	input 																										start,
	input 			 [383 : 0] 																		seed,
	input 																										unif_req,
	input 																										unif_req_ber,
	input 																										unif_req_salt,
	output logic [`FALCON_UNIFORM_BITS_BASE_SAMPLER - 1 : 0] 	unif_base,
	output logic [`FALCON_UNIFORM_BITS_SAMPLERZ -1 : 0]				unif_samp,
	output logic [`FALCON_UNIFORM_BITS_BER_EXP - 1 : 0] 			unif_ber,
	output logic [319 : 0] 																		salt,
	output logic [2 : 0]																			valid_o,
	output logic 																							hash_valid 						// debug - can deleted
);

	wire valid;
	wire request;
	
	wire [S - 1 : 0] hash; 

	shake_256 XOF(
		.clk			(clk),
	 	.rst_n		(rst_n),
	 	.start		(request || start),
 		.seed			(seed),		
		.hash			(hash),
	 	.done			(valid)
	);

	falcon_buffer #(
		.S(S)
		)BUFFER(
		.clk						(clk),
		.rst_n					(rst_n),
		.valid 					(valid),
		.hash_in				(hash),
		.unif_req 			(unif_req),
		.unif_req_ber		(unif_req_ber),
		.unif_req_salt	(unif_req_salt),
		.valid_o 				(valid_o),
		.request  			(request),
		.unif_base 			(unif_base),
		.unif_samp 			(unif_samp),
		.unif_ber 			(unif_ber),
		.salt 					(salt)
	);
endmodule