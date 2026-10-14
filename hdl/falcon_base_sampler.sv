/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_base_sampler
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_base_sampler.sv
 *    Create Date : Aug 23th 2026
 *    Last Update : Aug 23th 2026
 *    Description : Base Sampler -> SamplerZ
 ******************************************************************************
  History:

 ******************************************************************************/

`include "falcon_header.svh"

module falcon_base_sampler (
    input   clk,
    input   rst_n,
    input   logic [`FALCON_UNIFORM_BITS_BASE_SAMPLER - 1 : 0] unif_base,
    output  logic [4 : 0] z0
);
    
    logic [4 : 0] z0_tmp;

    localparam logic [`FALCON_REVERSE_CUMULATIVE_DATA_WIDTH - 1 : 0] RCDT [`FALCON_REVERSE_CUMULATIVE_DEPTH] = '{
        72'd3024686241123004913666, 72'd1564742784480091954050, 72'd636254429462080897535, 72'd199560484645026482916,
        72'd47667343854657281903, 72'd8595902006365044063, 72'd1163297957344668388, 72'd117656387352093658, 72'd8867391802663976,
        72'd496969357462633, 72'd20680885154299, 72'd638331848991, 72'd14602316184, 72'd247426747, 72'd3104126, 72'd28824, 
        72'd198, 72'd1
    };

    always_comb begin
        z0_tmp = '0;
        for(int i = 0; i < 18; i++) begin
            z0_tmp = z0_tmp + {4'd0, (unif_base < RCDT[i])};
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n)
            z0 <= '0;
        else
            z0 <= z0_tmp;
    end
endmodule : falcon_base_sampler