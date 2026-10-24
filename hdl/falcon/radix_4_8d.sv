/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : radix_4_8d
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: radix_4_8d.sv
 *    Create Date : Aug 28th 2026
 *    Last Update : Aug 28th 2026
 *    Description : Multiplier with 8 latency
 ******************************************************************************
  History:

 ******************************************************************************/

module radix_4_8d #(
    parameter int N = 64 
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [N-1:0]     a,
    input  logic [N-1:0]     b,
    output logic [2*N-1:0]   p
);

    localparam int NUM_STAGES = N / 8; // 8 Stages cho N=64

    // Pipeline registers cho A và B
    logic [N-1:0] a_1x_pipe [NUM_STAGES-2:0];
    logic [N+1:0] a_3x_pipe [NUM_STAGES-2:0];
    logic [N-1:0] b_pipe    [NUM_STAGES-2:0];

    logic [N-1:0] acc_r     [NUM_STAGES-1:0];
    logic [N-1:0] p_pipe    [NUM_STAGES-1:0];


    logic [N+1:0] a0_1x, a0_2x, a0_3x;
    assign a0_1x = {2'b00, a};
    assign a0_2x = {1'b0, a, 1'b0};
    assign a0_3x = {1'b0, a, 1'b0} + {2'b00, a};


    logic [N+1:0] pp0_0, pp0_1, pp0_2, pp0_3;

    assign pp0_0 = (b[1:0] == 2'b01) ? a0_1x :
                   (b[1:0] == 2'b10) ? a0_2x :
                   (b[1:0] == 2'b11) ? a0_3x : '0;

    assign pp0_1 = (b[3:2] == 2'b01) ? a0_1x :
                   (b[3:2] == 2'b10) ? a0_2x :
                   (b[3:2] == 2'b11) ? a0_3x : '0;

    assign pp0_2 = (b[5:4] == 2'b01) ? a0_1x :
                   (b[5:4] == 2'b10) ? a0_2x :
                   (b[5:4] == 2'b11) ? a0_3x : '0;

    assign pp0_3 = (b[7:6] == 2'b01) ? a0_1x :
                   (b[7:6] == 2'b10) ? a0_2x :
                   (b[7:6] == 2'b11) ? a0_3x : '0;

    logic [N+1:0] t0_0, t0_1, t0_2, t0_3;
    logic [7:0]   p_chunk0;

    assign t0_0     = pp0_0;                                        
    assign t0_1     = {2'b00, t0_0[N+1:2]} + pp0_1;
    assign t0_2     = {2'b00, t0_1[N+1:2]} + pp0_2;
    assign t0_3     = {2'b00, t0_2[N+1:2]} + pp0_3;
    assign p_chunk0 = {t0_3[1:0], t0_2[1:0], t0_1[1:0], t0_0[1:0]};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_r[0]     <= '0;
            p_pipe[0]    <= '0;
            a_1x_pipe[0] <= '0;
            a_3x_pipe[0] <= '0;
            b_pipe[0]    <= '0;
        end else begin
            acc_r[0]     <= t0_3[N+1:2];                                             
            p_pipe[0]    <= {p_chunk0, {(N-8){1'b0}}};
            a_1x_pipe[0] <= a;
            a_3x_pipe[0] <= a0_3x;
            b_pipe[0]    <= b >> 8;
        end
    end


    genvar i;
    generate
        for (i = 1; i < NUM_STAGES; i++) begin : gen_stages
            logic [N+1:0] ppi_0, ppi_1, ppi_2, ppi_3;


            assign ppi_0 = (b_pipe[i-1][1:0] == 2'b01) ? {2'b00, a_1x_pipe[i-1]} :
                           (b_pipe[i-1][1:0] == 2'b10) ? {1'b0, a_1x_pipe[i-1], 1'b0} :
                           (b_pipe[i-1][1:0] == 2'b11) ? a_3x_pipe[i-1] : '0;

            assign ppi_1 = (b_pipe[i-1][3:2] == 2'b01) ? {2'b00, a_1x_pipe[i-1]} :
                           (b_pipe[i-1][3:2] == 2'b10) ? {1'b0, a_1x_pipe[i-1], 1'b0} :
                           (b_pipe[i-1][3:2] == 2'b11) ? a_3x_pipe[i-1] : '0;

            assign ppi_2 = (b_pipe[i-1][5:4] == 2'b01) ? {2'b00, a_1x_pipe[i-1]} :
                           (b_pipe[i-1][5:4] == 2'b10) ? {1'b0, a_1x_pipe[i-1], 1'b0} :
                           (b_pipe[i-1][5:4] == 2'b11) ? a_3x_pipe[i-1] : '0;

            assign ppi_3 = (b_pipe[i-1][7:6] == 2'b01) ? {2'b00, a_1x_pipe[i-1]} :
                           (b_pipe[i-1][7:6] == 2'b10) ? {1'b0, a_1x_pipe[i-1], 1'b0} :
                           (b_pipe[i-1][7:6] == 2'b11) ? a_3x_pipe[i-1] : '0;

            logic [N+1:0] ti_0, ti_1, ti_2, ti_3;
            logic [7:0]   p_chunki;

            assign ti_0     = {2'b00, acc_r[i-1]}  + ppi_0;
            assign ti_1     = {2'b00, ti_0[N+1:2]} + ppi_1;
            assign ti_2     = {2'b00, ti_1[N+1:2]} + ppi_2;
            assign ti_3     = {2'b00, ti_2[N+1:2]} + ppi_3;
            assign p_chunki = {ti_3[1:0], ti_2[1:0], ti_1[1:0], ti_0[1:0]};

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    acc_r[i]  <= '0;
                    p_pipe[i] <= '0;
                    if (i < NUM_STAGES - 1) begin
                        a_1x_pipe[i] <= '0;
                        a_3x_pipe[i] <= '0;
                        b_pipe[i]    <= '0;
                    end
                end else begin
                    acc_r[i]  <= ti_3[N+1:2];
                    p_pipe[i] <= {p_chunki, p_pipe[i-1][N-1:8]};

                    if (i < NUM_STAGES - 1) begin
                        a_1x_pipe[i] <= a_1x_pipe[i-1];
                        a_3x_pipe[i] <= a_3x_pipe[i-1];
                        b_pipe[i]    <= b_pipe[i-1] >> 8;
                    end
                end
            end
        end
    endgenerate


    assign p = {acc_r[NUM_STAGES-1], p_pipe[NUM_STAGES-1]};

endmodule