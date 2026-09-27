/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : radix_4_32d
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: radix_4_32d.sv
 *    Create Date : Aug 28th 2026
 *    Last Update : Aug 28th 2026
 *    Description : Multiplier with 32 latency
 ******************************************************************************
  History:

 ******************************************************************************/

module radix_4_32d #(
    parameter int N = 64 
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [N-1:0]     a,
    input  logic [N-1:0]     b,
    output logic [2*N-1:0]   p
);

    localparam int NUM_TIERS = N / 2;

    // Pipeline registers cho A và B
    logic [N-1:0] a_1x_pipe [NUM_TIERS-2:0];
    logic [N+1:0] a_3x_pipe [NUM_TIERS-2:0];
    logic [N-1:0] b_pipe    [NUM_TIERS-2:0];


    logic [N+2:0]   acc_r  [NUM_TIERS-1:0];
    logic [2*N-1:0] p_pipe [NUM_TIERS-1:0];


    logic [N+1:0] a0_1x, a0_2x, a0_3x;
    assign a0_1x = {2'b00, a};
    assign a0_2x = {1'b0, a, 1'b0};
    assign a0_3x = {1'b0, a, 1'b0} + {2'b00, a}; 

    logic [N+1:0] pp_0;
    assign pp_0 = (b[1:0] == 2'b01) ? a0_1x :
                  (b[1:0] == 2'b10) ? a0_2x :
                  (b[1:0] == 2'b11) ? a0_3x : '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_r[0]     <= '0;
            a_1x_pipe[0] <= '0;
            a_3x_pipe[0] <= '0;
            b_pipe[0]    <= '0;
            p_pipe[0]    <= '0;
        end else begin
            acc_r[0]     <= {1'b0, pp_0};
            a_1x_pipe[0] <= a;
            a_3x_pipe[0] <= a0_3x;
            b_pipe[0]    <= b >> 2;
            p_pipe[0]    <= '0;
        end
    end


    genvar i;
    generate
        for (i = 1; i < NUM_TIERS; i++) begin : gen_stages
            logic [N+1:0] pp_i;

            assign pp_i = (b_pipe[i-1][1:0] == 2'b01) ? {2'b00, a_1x_pipe[i-1]} :
                          (b_pipe[i-1][1:0] == 2'b10) ? {1'b0, a_1x_pipe[i-1], 1'b0} :
                          (b_pipe[i-1][1:0] == 2'b11) ? a_3x_pipe[i-1] : '0;

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    acc_r[i]  <= '0;
                    p_pipe[i] <= '0;
                    if (i < NUM_TIERS - 1) begin
                        a_1x_pipe[i] <= '0;
                        a_3x_pipe[i] <= '0;
                        b_pipe[i]    <= '0;
                    end
                end else begin
                    acc_r[i]  <= {2'b00, acc_r[i-1][N+2:2]} + {1'b0, pp_i};

                    if (i < NUM_TIERS - 1) begin
                        a_1x_pipe[i] <= a_1x_pipe[i-1];
                        a_3x_pipe[i] <= a_3x_pipe[i-1];
                        b_pipe[i]    <= b_pipe[i-1] >> 2;
                    end

                    p_pipe[i] <= {acc_r[i-1][1:0], p_pipe[i-1][2*N-1:2]};
                end
            end
        end
    endgenerate


    assign p = {
        acc_r[NUM_TIERS-1][N+1:2], 
        acc_r[NUM_TIERS-1][1:0], 
        p_pipe[NUM_TIERS-1][2*N-1 : 2*N - (2*NUM_TIERS-2)]
    };

endmodule