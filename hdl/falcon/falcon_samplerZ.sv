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


 /**
  *property random_base;
  *	@(posedge clk)
  * 	unif_req |=> (unif_base == random_base);
  * endproperty
  * 
  *property random_samp;
  *	@(posedge clk)
  * 	unif_req |=> (unif_samp == random_samp);
  * endproperty
  * 
  *property random_ber;
  *	@(posedge clk)
  * 	unif_req_ber |=> (unif_ber == random_ber);
  * endproperty
  * 
  * */


`include "falcon_header.svh"

module falcon_samplerZ (
	input																														clk,
	input 																													rst_n,
	input  																													start,
	input  							[`FALCON_UNIFORM_BITS_BASE_SAMPLER - 1 : 0] unif_base,			// Uniform bits to base_sampler
 	input  							[`FALCON_UNIFORM_BITS_SAMPLERZ -1 : 0]			unif_samp,			// Uniform bits to samplerZ
 	input  			 				[`FALCON_UNIFORM_BITS_BER_EXP - 1 : 0] 			unif_ber,				// Uniform bits to ber_exp
 	input  			 				[`FPU_STAND - 1 : 0] 												o_dot,        	// σ′(floating point unit)
 	input          			[`FPU_STAND - 1 : 0] 												mu,							// µ (floating point unit)
 	output logic																										unif_req,				// Request to PRNG - SHAKE
 	output logic 																										unif_req_ber,
 	output logic 																										valid_o,
 	output logic signed [`FALCON_Z - 1 : 0] 												z_o							
);
	
	
	logic 				[`FALCON_SPLERZ - 1 : 0] 	z0;
	logic signed 	[`FALCON_SPLERZ - 1 : 0] 	z;
	logic signed  [15 : 0]             			s;
	logic 				[`FALCON_CCS - 1 : 0]   	ccs;
	logic 				[`FALCON_SQR_P - 1 : 0] 	o_sqr;
	logic 				[`FALCON_X - 1 : 0] 			x;

	logic valid_x1;
	logic valid_x2;
	logic valid_ber;
	logic check_bit;
	logic en_ber;
	

	falcon_sampler falcon_sampler(
		.clk 				(clk),
		.rst_n 			(rst_n),
		.unif_base 	(unif_base),
		.unif_samp 	(unif_samp),
		.z0 				(z0),
		.z 					(z)
	);


	falcon_ccs_2p_gen falcon_ccs_2p_gen(
		.clk  			(clk),
		.rst_n  		(rst_n),
		.start			(start),
		.o_dot			(o_dot),
		.ccs  			(ccs),
		.o_sqr			(o_sqr),
		.done 			(valid_x1)
	);


	falcon_gen_x falcon_generate_x(
		.clk 				(clk),
		.rst_n 			(rst_n),
		.valid 			(valid_x1 || valid_x2),
		.valid_o 		(en_ber),
		.mu 				(mu),
		// .ccs 				(ccs),
		.o_sqr 			(o_sqr),
		.z0 				(z0),
		.z 					(z),
		.s 					(s),
		.x 					(x)
	);


	falcon_ber_exp falcon_ber_exp(
 		.clk        	(clk),
 		.rst_n      	(rst_n),
 		.start      	(en_ber),
 		.x          	(x),
 		.ccs         	(ccs),
 		.uniform_bits	(unif_ber),
 		.uniform_req 	(unif_req_ber),
 		.check_bit   	(check_bit),
 		.done        	(valid_ber)
	);


	falcon_sampler_controller falcon_sampler_controller(
		.clk 					(clk),
		.rst_n 				(rst_n),
		.start     		(start),
		.check_bit 		(check_bit),
		.ber_valid 		(valid_ber),
		.genx_valid 	(valid_x2),
		.unif_req 		(unif_req),
		.valid_o 			(valid_o),
		.z  					(z[`FALCON_SPLERZ -  1 -: 16]),	
		.s 						(s),
		.z_o 					(z_o)			
	);

endmodule