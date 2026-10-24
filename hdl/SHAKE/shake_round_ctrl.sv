/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_round_ctrl.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_round_ctrl
 *    Create Date : Oct 23th 2026
 *    Last Update : Oct 23th 2026
 *    Description : Controller for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/

module shake_round_ctrl(
	input 								clk,
	input 								start,
	input 								rst_n,
	input 								flag_ctrl,			// from shake_iota
	input					[4 : 0]	idx_i,					// Check index round of keccak-f
	output 	logic	[4 : 0]	idx_o,					// Pointer to "RC pointer calculator"
	output 	logic [4 : 0]	summand,				// Send to adder (RC pointer calculator)
	output 	logic			 		d1x2s_en,				// To demux 1-2
	output 	logic 				m2x1s_en,				// To mux 2-1
	output	logic					interrupt,			// Reset en_loop (shake_iota)
	output 	logic					done						// pulse if completing 24 rounds
);
	

	/******************************************************************/
	/******************************************************************/
	/**
	 * control signals to "select" port of M2X1S
	 * */
	always_ff @(posedge clk) begin
		if(!rst_n)
			m2x1s_en <= 0;
		else begin
			if(start) m2x1s_en <= 1;
		end
	end

	/******************************************************************/
	/******************************************************************/
	/**
	 * Control signals to "select" port of D1X2S
	 * Send a interrupt to shake_iota
	 * */
	always_comb begin
		if(flag_ctrl && idx_i == 23) begin
			d1x2s_en 	= 1;
			interrupt = 1;
		end else begin
			d1x2s_en 	<= 0;
			interrupt <= 0;
		end
	end

	/******************************************************************/
	/******************************************************************/
	/**
	 * Send 1 to "Pointer calculator" 
	 * */
	always_ff @(posedge clk) begin
		if(!rst_n)
			summand <= '0;
		else begin
			if(flag_ctrl && idx_i == 23)
				summand <= 5'h0;
			else if(flag_ctrl) 
				summand <= 5'h01;
		end
	end

	/******************************************************************/
	/******************************************************************/
	/**
	 * RC pointer Controller (Pipeline) - red line in specification
	 * */
	always_ff @(posedge clk) begin
		if(!rst_n)
			idx_o	<= 0;
		else begin
			if(flag_ctrl) begin
				if(idx_i == 23)
					idx_o <= 0;
				else
					idx_o <= idx_i;
			end
		end
	end

	/******************************************************************/
	/******************************************************************/
	/**
	 * Pulse done when rounds = 24
	 * */
	always_ff @(posedge clk) begin
		if(!rst_n)
			done <= 0;
		else begin
			if(flag_ctrl && idx_i == 23)
				done <= 1;
			else
				done <= 0;
		end
	end
endmodule