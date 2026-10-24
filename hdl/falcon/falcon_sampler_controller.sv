/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_sampler_controller.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_sampler_controller
 *    Create Date : Oct 11th 2026
 *    Last Update : Oct 11th 2026
 *    Description : Controller for falcon_samplerZ
 ******************************************************************************
  History:

 ******************************************************************************/
`include "falcon_header.svh"

 module falcon_sampler_controller (
 	input 																	clk,
 	input 																	rst_n,
 	input 																	start,
 	input 																	check_bit,
 	input 																	ber_valid,
 	output logic														genx_valid,
 	output 																	unif_req,
 	output logic 														valid_o,
 	input  			 signed	[`FALCON_Z - 1 : 0] z,							// 16 bit MSBs from falcon_sampler
 	input  logic signed [15 : 0]            s,
 	output logic signed [`FALCON_Z - 1 : 0] z_o						
 );

 logic [1 : 0] valid_dl;
 logic unif_req_1; 							// Triggered when falcon_ccs_2p_gen done 
 logic unif_req_2;							// Triggered when check bit assert 

 always_comb begin
 	if(ber_valid) unif_req_2 = ~check_bit;
 	else 					unif_req_2 = 1'b0;

 	if(start) unif_req_1 = 1'b1;
 	else 			unif_req_1 = 1'b0;
 end


 always_ff @(posedge clk) begin
 	if(!rst_n) begin
 		valid_dl 		<= 2'b00;
 		genx_valid	<= 1'b0;
 	end
 	else begin
 		valid_dl[0] <= unif_req_2;
 		valid_dl[1] <= valid_dl[0];
 		genx_valid  <= valid_dl[1];
 	end
 end


 always_ff @(posedge clk) begin
 	if(!rst_n) begin
 		z_o 		<= '0;
 		valid_o	<= 1'b0;
 	end
 	else begin
 		if(ber_valid && check_bit) begin
 			valid_o <= 1'b1;
 			z_o  		<= z + s;
 		end
 		else
 			valid_o <= 1'b0;
 	end
 end

 assign unif_req = unif_req_1 || unif_req_2;
endmodule

