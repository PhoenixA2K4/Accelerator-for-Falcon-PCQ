/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_buffer.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_buffer
 *    Create Date : Oct 27th 2026
 *    Last Update : Oct 27th 2026
 *    Description :	Generate "variable uniforms bit"
 ******************************************************************************
  History:

 ******************************************************************************/
 `include "falcon_header.svh"

module falcon_buffer #(
	parameter int S = 1088
	)(
	input 																										clk,    
	input 																										rst_n,  
	input 																										valid,
	input 			 [S - 1 : 0] 																	hash_in,  				// hash data from SHAKE-256
	input 																										unif_req, 				// request from base_sampler and samplerZ
	input 																										unif_req_ber,			// request from berexp
	input 																										unif_req_salt,		// request from sign
	output logic [2 : 0]																			valid_o, 					// broadcast "valid signal" to requester
	output logic																							request,  				// request to SHAKE-256 execute 24 loop
	output logic [`FALCON_UNIFORM_BITS_BASE_SAMPLER - 1 : 0] 	unif_base,				// request data to base_sampler
	output logic [`FALCON_UNIFORM_BITS_SAMPLERZ -1 : 0]				unif_samp,				// request data to samplerZ
	output logic [`FALCON_UNIFORM_BITS_BER_EXP - 1 : 0] 			unif_ber, 				// request data to ber_exp
	output logic [319 : 0] 																		salt  						// salt data to sign step
);

	logic [`FALCON_UNIFORM_BITS_BASE_SAMPLER - 1 : 0] 	unif_base_ovf;
	logic [`FALCON_UNIFORM_BITS_SAMPLERZ -1 : 0]				unif_samp_ovf;			
	logic [`FALCON_UNIFORM_BITS_BER_EXP - 1 : 0] 				unif_ber_ovf;
	logic [319 : 0] 																		salt_ovf;

	logic [1 : 0] 		mode;
	logic [11 : 0] 		ptr;
	logic [11 : 0] 		ptr_next;

	logic [S - 1 : 0] hash_curr;
	wire [2*S - 1 : 0] window = {hash_in, hash_curr}; 

	typedef enum logic [1 : 0] {
		ST_IDLE,
		ST_OVF,
		ST_NOVF,
		ST_RESP
	}state_t;

	state_t curr_state;
	state_t next_state;


	/******************************************************************/
	/******************************************************************/
	/**
	 * Pointer location calculator
	 * */
	always_comb begin
		if(unif_req_salt)
			ptr_next = ptr + 320;
		else if(unif_req) 
			ptr_next = ptr + 80;
		else if(unif_req_ber)
			ptr_next = ptr + 8;
		else
			ptr_next = ptr;
	end

	always_ff @(posedge clk) begin
		if(!rst_n) begin
			ptr <= '0;
		end
		else begin
			ptr <= ptr_next;
		end
	end


	/******************************************************************/
	/******************************************************************/
	/**
	 * current state logic block
	 * */
	always_ff @(posedge clk) begin
		if(!rst_n)
			curr_state <= ST_IDLE;
		else
			curr_state <= next_state;
	end


	/******************************************************************/
	/******************************************************************/
	/**
	 * next state logic block
	 * */
	always_comb begin
		next_state = curr_state;
		request    = 0;
		case(curr_state)
			ST_IDLE: begin
				if(unif_req_salt || unif_req || unif_req_ber) begin
					if(ptr_next > (S - 1)) begin
						next_state = ST_OVF;
						request    = 1;
					end
					else begin
						next_state = ST_NOVF;
						request    = 0;
					end
				end
				else
					next_state = ST_IDLE;
			end
			ST_OVF: begin
				if(valid)
					next_state = ST_RESP;
				else
					next_state = ST_OVF;
			end
			ST_NOVF: begin
				next_state = ST_RESP;
			end
			ST_RESP: begin
				next_state = ST_IDLE;
			end
			default: begin
				request 	 = 0;
				next_state = ST_IDLE;
			end
		endcase
	end


	/******************************************************************/
	/******************************************************************/
	/**
	 * Non-blocking logic block
	 * */
	always_ff @(posedge clk) begin
		if(!rst_n) begin
			mode 					<= 0;
			unif_base_ovf <= '0;
			unif_samp_ovf <= '0;
			unif_ber_ovf  <= '0;
			salt_ovf 			<= '0;
			unif_base 		<= '0;
			unif_samp 		<= '0;
			unif_ber  		<= '0;
			salt 					<= '0;
			valid_o 			<= '0;
		end
		else begin
			case(curr_state)
				ST_IDLE: begin
					valid_o 	<= '0;
					hash_curr <= hash_in;
					if(unif_req_salt)
						mode <= 1;
					else if(unif_req)
						mode <= 2;
					else if(unif_req_ber)
						mode <= 3;
				end
				ST_NOVF: begin
					if(mode == 1)
						salt_ovf <= hash_curr[(ptr - 1) -: 320];
					else if(mode == 2)
						{unif_samp_ovf,unif_base_ovf} <= hash_curr[(ptr - 1) -: 80];
					else if(mode == 3)
						unif_ber_ovf <= hash_curr[(ptr - 1) -: 8];
				end
				ST_OVF: begin
					if(valid) begin
						case(mode)
							2'd1: salt_ovf <= window[(ptr - 1 ) -: 320];
							2'd2: {unif_samp_ovf,unif_base_ovf} <= window[(ptr - 1) -: 80];
							2'd3: unif_ber_ovf <= window[(ptr - 1) -: 8];
							default: ;
						endcase
						ptr <= ptr - S;
					end
				end
				ST_RESP:begin
					unif_base <= unif_base_ovf;
					unif_samp <= unif_samp_ovf;
					unif_ber  <= unif_ber_ovf;
					salt 			<= salt_ovf;
					case (mode)
						2'd1: valid_o <= 3'b001;
						2'd2: valid_o <= 3'b010;
						2'd3: valid_o <= 3'b100;
						default : valid_o <= '0;
					endcase
				end
				default: begin
					mode 					<= 0;
					unif_base_ovf <= '0;
					unif_samp_ovf <= '0;
					unif_ber_ovf  <= '0;
					salt_ovf 			<= '0;
					unif_base 		<= '0;
					unif_samp 		<= '0;
					unif_ber  		<= '0;
					salt 					<= '0;
					valid_o 			<= '0;
				end
			endcase
		end
	end
endmodule
