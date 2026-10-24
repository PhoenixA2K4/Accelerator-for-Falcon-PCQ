/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_theta1.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_theta1
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : Theta1 for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/
// `include "SHAKE_pkg.sv"
import SHAKE_pkg :: * ;

module shake_theta1(
	input                       clk,
	input                       en_f1,
	input                       rst_n,
	input 				[4 : 0]				idx_i,
	input   logic [1599 : 0]    S_in,
	output  d2_arr              data_o,
	output  logic [1599 : 0]    S_out,
	output 	logic [4 : 0]				idx_o,
	output  logic               en_f2
);

  d3_arr A;
  d2_arr C;

  always_comb begin
  	A = converse_blk(S_in);
  end

 	genvar i;
 	generate
  	for(i = 0; i < 5; i++) begin : gen_C
      assign C[i] = ( A[0][i] ^ A[1][i] ) ^ ( A[2][i] ^ A[3][i] );
  	end
 	endgenerate

 	always_ff @(posedge clk)begin
  	if(!rst_n) begin
      data_o <= '{default: '0};
      en_f2 <= 1'b0;
  	end
  	else begin
    	if(en_f1) begin
       	data_o <= C;
       	S_out  <= S_in;
    	end
      en_f2 <= en_f1;
      idx_o <= idx_i;
  	end
 	end
endmodule