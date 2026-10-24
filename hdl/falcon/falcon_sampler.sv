/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_sampler
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_sampler.sv
 *    Create Date : Oct 4th 2026
 *    Last Update : Oct 4th 2026
 *    Description : Get uniform bits form PRNG 
 ******************************************************************************
  History:

 ******************************************************************************/

 `include "falcon_header.svh"

 	module falcon_sampler (
 		input																															clk,
 		input 																														rst_n,
 		input  							[`FALCON_UNIFORM_BITS_BASE_SAMPLER - 1 : 0] 	unif_base,
 		input  							[`FALCON_UNIFORM_BITS_SAMPLERZ -1 : 0]				unif_samp,
 		output logic				[`FALCON_SPLERZ - 1 : 0]											z0,
 		output logic signed [`FALCON_SPLERZ - 1 : 0]											z
	);


		logic [4 : 0] 									z0_tmp;
		logic [5 : 0] 									z0_signed;
		// logic [`FALCON_SPLERZ - 1 : 0]	z0_fxp;


 		falcon_base_sampler base_sampler(
 			.clk				(clk),
 			.rst_n 			(rst_n),
 			.unif_base 	(unif_base),
 			.z0					(z0_tmp)
 		);


 		/**
 		 * Algorithm 15 SamplerZ - line 6 : z ← b+(2·b−1)z0
 		 * */
 		always_ff @(posedge clk) begin
 			if(!rst_n) begin
 				z0_signed	<= '0;
 				// z0_fxp 		<= '0;
 			end
 			else begin
 				if(unif_samp[0])
 					z0_signed <= $signed({1'b0, z0_tmp}) + 6'sd1;
 				else
 					z0_signed <= -$signed({1'b0, z0_tmp});
 			end
 		end


 		/**
 		 * Convert to fixpoint 
 		 * */
 		always_comb begin
 			z 	= {{10{z0_signed[5]}}, z0_signed, 48'd0};
 			z0 	= {59'd0, z0_tmp}; 
 		end
	endmodule	