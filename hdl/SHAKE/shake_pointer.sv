/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : shake_pointer.sv
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: shake_pointer
 *    Create Date : Oct 23th 2026
 *    Last Update : Oct 23th 2026
 *    Description : Calculate RC pointer for SHAKE-256
 ******************************************************************************
  History:

 ******************************************************************************/

module shake_pointer(
	input 	[4 : 0] a,
	input 	[4 : 0] b,
	output	[4 : 0] y 
);

	assign y = a + b;
endmodule