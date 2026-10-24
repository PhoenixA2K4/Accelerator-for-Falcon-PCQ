/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_iota.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_iota
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : Iota for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/
`include "SHAKE_pkg.sv"
import SHAKE_pkg::*;

module shake_iota (
	input                   		clk,
	input                   		rst_n,
	input                   		en_f4,
	input 											interrupt,
	input   logic		[63 : 0]  	RC_data,
	input   d3_arr          		data_i,
	output 											en_loop,
	output 											flag_ctrl,
	output  logic 	[1599 : 0] 	data_o
);
	d3_arr Iota;

	genvar i, j;
  generate
   	for(i = 0; i < 5; i++) begin : gen_Iota
    	for(j = 0; j < 5; j++) begin : gen_Iota_inner
      	if(j == 0 && i == 0)
       		assign Iota[i][j] = data_i[i][j] ^ RC_data;
      	else
       		assign Iota[i][j] = data_i[i][j];
    	end
   	end
  endgenerate

  always_comb begin
  	data_o 		= converse_str(Iota);
  	flag_ctrl = en_f4;
  end

  always_ff @(posedge clk) begin
  	if(!rst_n)begin
  		en_loop 	<= 0;
  	end
  	else begin
  		if(interrupt) 
  			en_loop <= 0;
  		else 
  			en_loop <= en_f4;
  	end
  end
endmodule