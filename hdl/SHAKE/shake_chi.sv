/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_chi.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_chi
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : CHi for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/

 // `include "SHAKE_pkg.sv"
import SHAKE_pkg :: * ;

module shake_chi (
	input           			clk,
	input           			rst_n,
	input           			en_f3,
	input  	d3_arr   			data_i,
	input 	logic [4 : 0] idx_i,
	output 	logic [4 : 0] idx_o,
	output 	d3_arr   			data_o,	 
	output 	logic    			en_f4
);

	d3_arr Chi;

	genvar i,j;
 	generate
   	for(i = 0; i < 5; i++) begin : gen_Chi
     	for(j = 0; j < 5; j++) begin : gen_Chi_inner
      	assign Chi[i][j] = data_i[i][j] ^ (~(data_i[i][(j +1) % 5]) & data_i[i][(j +2) % 5]);
     	end
   	end
 	endgenerate


	always_ff @(posedge clk) begin
  	if(!rst_n)begin
      data_o <= '{default : '0};
      en_f4 <= 1'b0;
  	end
  	else begin
      if(en_f3) data_o <= Chi;
      en_f4 <= en_f3;
      idx_o <= idx_i;
  	end
	end
endmodule