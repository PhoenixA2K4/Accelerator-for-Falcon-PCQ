/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_RC.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_RC
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : RC for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/

 module shake_RC (
 	input   [4 : 0]   index,
 	output  [63 : 0]  RC_out
);

	localparam logic [63 : 0] RC [24] = '{
  	64'h0000000000000001,
  	64'h0000000000008082,
  	64'h800000000000808A,
  	64'h8000000080008000,
  	64'h000000000000808B,
  	64'h0000000080000001,
  	64'h8000000080008081,
  	64'h8000000000008009,
  	64'h000000000000008A,
  	64'h0000000000000088,
  	64'h0000000080008009,
  	64'h000000008000000A,
  	64'h000000008000808B,
  	64'h800000000000008B,
  	64'h8000000000008089,
  	64'h8000000000008003,
  	64'h8000000000008002,
  	64'h8000000000000080,
  	64'h000000000000800A,
  	64'h800000008000000A,
  	64'h8000000080008081,
  	64'h8000000000008080,
  	64'h0000000080000001,
  	64'h8000000080008008
	};

	assign RC_out = RC[index];
endmodule