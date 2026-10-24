/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : M2X1S.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: M2X1S
 *    Create Date : July 23th 2026
 *    Last Update : July 23th 2026
 *    Description : Mux 2 - 1
 ******************************************************************************
  History:

 ******************************************************************************/

module M2X1S(
	input   logic [1599 : 0] 	A,
	input   logic [1599 : 0] 	B,
	input   									sel,
	output  logic [1599 : 0] 	data_o
);
	
	/**
 	* sel = '1' permit data loop from port B
 	* sel = '0' permit data message from port A
 	* */
	assign data_o = sel == 1'b1 ? B : A;
endmodule