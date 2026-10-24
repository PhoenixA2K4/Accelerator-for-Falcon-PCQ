/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : SHAKE_pkg.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: SHAKE_pkg
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : Package for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/

`ifndef SHAKE_PKG_SV
`define SHAKE_PKG_SV

	package SHAKE_pkg;

   	typedef logic[63 : 0] d3_arr [0 : 4][0 : 4];
    typedef logic[63 : 0] d2_arr [0 : 4];

    typedef struct packed {
    	logic [24 : 0][63 : 0] dword;
    }kecf_t;


    // RC Table
    localparam int R [5][5]= '{
   		'{0,  1,  62,  28,  27},
   		'{36, 44, 6,   55,  20},
   		'{3,  10, 43,  25,  39},
   		'{41, 45, 15,  21,  8},
   		'{18, 2,  61,  56,  14}
    };


    // Transfer string data into block array
    function automatic d3_arr converse_blk;
    	input kecf S;
    begin
    	for(int i = 0; i < 5; i++) begin
      	for(int j = 0; j < 5; j++) begin
        	converse_blk[i][j] = S.dword[i*5+j];
      	end
    	end
    end
    endfunction

    // Transfer block array into string data
    function automatic kecf_t converse_str;
    	input d3_arr A;
    begin
    	for(int i = 0; i < 5; i++) begin
      	for(int j = 0; j < 5; j++) begin
        	converse_str.dword[i*5+j] = A[i][j];
      	end
    	end
    end
    endfunction

    // Specification of Rho
    function automatic logic [63:0] rotl;
   		input logic [63:0] value;
   		input integer offset;
    begin
    	if (offset == 0)
     		rotl = value;
    	else
     		rotl = (value << offset) | (value >> (64 - offset));
    end
    endfunction

endpackage: SHAKE_pkg
`endif