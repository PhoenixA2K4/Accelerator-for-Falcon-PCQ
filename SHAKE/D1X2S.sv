/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : D1X2S.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: D1X2S
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : Demux 1 - 2
 ******************************************************************************
  History:

 ******************************************************************************/

module D1X2S (
	input 										clk,
	input 										rst_n,
	input   			[1599 : 0] 	data_i,
	input   									sel,
	output  logic [1599 : 0] 	A,
	output  logic [1599 : 0] 	B
);

	logic [1599 : 0] A_tmp;
	logic [1599 : 0] B_tmp;

/**
 * sel = '0' transmit data loop into Stage 1 (Theta1)
 * sel = '1' export final data to outside
 * */
	always_comb begin
   	A_tmp = '0;
   	B_tmp = '0;
  	unique case (sel)
    	1'b0: A_tmp = data_i;
    	1'b1: begin 
    		A_tmp = data_i;
    		B_tmp = data_i;
    	end
  	endcase
	end

/**
 * Return to new round
 * */
 	always_ff @(posedge clk) begin
 		if(!rst_n) begin
 			A <= 0;
 			B <= 0;
 		end else begin
 			A <= A_tmp;
 			B <= B_tmp;
 		end
 	end
endmodule