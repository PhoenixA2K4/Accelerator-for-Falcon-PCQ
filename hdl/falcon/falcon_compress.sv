/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_compress.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_compress
 *    Create Date : Nov 1st 2026
 *    Last Update : Nov 1st 2026
 *    Description :	Compress string 
 ******************************************************************************
  History:

 ******************************************************************************/

`include "falcon_header.svh"

module falcon_compress (
	input  logic                            		clk,
	input  logic                            		rst_n,
	input  logic                            		valid,
	input  logic signed [15 : 0]            		coeff_data,
	output logic 				[`FALCON_SLEN - 1 : 0]  str,
	output logic                            		success,
	output logic                            		fail
);

	localparam int N    = 512;
	localparam int SLEN = `FALCON_SLEN; 

	logic [8 : 0]   round;
	logic [12 : 0]  bit_ptr;       
	logic           overflow_flag;

	logic          sign_b;
	logic [15 : 0] abs_s;
	logic [6 : 0]  low_bits;
	logic [8 : 0]  high_k;
	logic [5 : 0]  sym_len;        // Chiều dài chuỗi sinh ra: 9 + k
	logic [63 : 0] sym_bits;       // Tối đa 9 + 48 = 57 bit, dùng 64-bit là dư an toàn

 	assign sign_b   = coeff_data[15];
 	assign abs_s    = (coeff_data < 0) ? logic'(-coeff_data) : logic'(coeff_data);
 	assign low_bits = abs_s[6:0];
 	assign high_k   = abs_s[15:7];

 	always_comb begin
  	sym_len  = 6'(9 + high_k);
  	sym_bits = '0;
  	sym_bits[0] = 1'b1;
  	sym_bits[1 + high_k +: 7] = low_bits;
  	sym_bits[8 + high_k]      = sign_b;
 	end

  wire [SLEN-1 : 0] sym_extended = {{(SLEN-64){1'b0}}, sym_bits};

 	always_ff @(posedge clk or negedge rst_n) begin
   	if (!rst_n) begin
    	round         <= '0;
    	bit_ptr       <= '0;
    	str           <= '0;
    	success       <= 1'b0;
    	fail          <= 1'b0;
    	overflow_flag <= 1'b0;
  	end else begin
     	success <= 1'b0;
     	fail    <= 1'b0;
     	if (valid) begin
       	if (bit_ptr + sym_len > SLEN) begin
          overflow_flag <= 1'b1;
       	end else begin
        	str     <= str | (sym_extended << bit_ptr);
        	bit_ptr <= bit_ptr + sym_len;
     		end
    		if (round == (N - 1)) begin
     			round <= '0;
     			if (overflow_flag || (bit_ptr + sym_len > SLEN)) begin
       			fail    <= 1'b1;
       			success <= 1'b0;
     			end else begin
       			fail    <= 1'b0;
       			success <= 1'b1; 
     			end
     			bit_ptr       <= '0;
     			overflow_flag <= 1'b0;
    		end else begin
    			round <= round + 1'b1;
    			if (round == 0) begin
          	str <= sym_extended; 
    			end
     		end
   		end
		end
 	end

endmodule