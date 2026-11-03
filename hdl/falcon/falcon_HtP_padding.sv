/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_HtP_padding.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_HtP_padding
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : Padding block's HashToPoint (SHAKE-256)
 ******************************************************************************
  History:

 ******************************************************************************/

module shake_HtP_padding (
	input  logic [263 : 0]   msg,   
	output logic [1599 : 0]  Sp
);

  function automatic [263 : 0] bswap;
  	input [263 : 0] x;
 	begin
  	for (int i = 0; i < 33; i++) begin
     	bswap[263 - i*8 -: 8] = x[i*8 + 7 -: 8];
  	end
  end
  endfunction

  logic [1599 : 0] S;

 	always_comb begin
  	S             = '0;
  	S[263 : 0]    = bswap(msg);
  	S[268 : 264]  = 5'b11111; 
  	S[1087]       = 1'b1;     
  	Sp            = S;
 	end
endmodule