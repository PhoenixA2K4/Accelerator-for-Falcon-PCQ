/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_theta2_rho_pi.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_theta2_rho_pi
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : Theta 2 - Rho - Pi for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/

 // `include "SHAKE_pkg.sv"
import SHAKE_pkg :: * ;

module shake_theta2_rho_pi (
	input               			clk,
	input               			rst_n,
	input               			en_f2,
	input  				[4 : 0]			idx_i,
	input  				[1599 : 0]  S_in,
	input  d2_arr       			data_i,
	output logic 	[4 : 0]			idx_o,
	output logic        			en_f3,
	output d3_arr       			data_o
);
    d3_arr A, Ap, Rho, Pi;
    d2_arr C, D;

    assign A = converse_blk(S_in);


    // Generate C for Theta
    genvar i;
    generate
    	for(i = 0; i < 5; i++) begin : gen_C
      	assign C[i] = data_i[i] ^ A[4][i];
    	end
    endgenerate


    // Generate D for Theta
    genvar j;
    generate
    	for(j = 0; j < 5; j++) begin : gen_D
      	assign D[j] = { C[(j + 1) %5][62 : 0], C[(j + 1) %5][63] } ^ C[( j + 4) %5];
    	end
    endgenerate


    // Generate A' for Theta
    genvar x, y;
    generate
    	for(x = 0; x < 5; x++) begin : gen_A_p
       	for(y = 0; y < 5; y++) begin : gen_A_p_inner
          assign Ap[x][y] = A[x][y] ^ D[y];
       	end
    	end
    endgenerate


    // Rho
    genvar a, b;
    generate
     	for(a = 0; a < 5; a++) begin : gen_Rho
       	for(b = 0; b < 5; b++) begin : gen_Rho_inner
         	assign Rho[a][b] = rotl(Ap[a][b], R[a][b]);
       	end
     	end
    endgenerate


    // Pi
    generate
   		for(a = 0; a < 5; a++) begin : gen_Pi
       	for(b = 0; b < 5; b++) begin : gen_Pi_inner
          assign Pi[a][b] = Rho[b][(b + 3*a) %5];
       	end
   		end
    endgenerate


    always_ff @(posedge clk) begin
   		if(!rst_n)begin
     		data_o <= '{default: '0};
     		en_f3 <= 1'b0;
     	end
     	else begin
     		if(en_f2) data_o <= Pi;
     		en_f3 <= en_f2;
     		idx_o <= idx_i;
   		end
    end
endmodule