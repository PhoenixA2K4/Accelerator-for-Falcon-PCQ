/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_approx_exp
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_approx_exp.sv
 *    Create Date : Aug 28th 2026
 *    Last Update : Aug 28th 2026
 *    Description : ApproxExp -> BerExp -> SamplerZ
 ******************************************************************************
  History:

 ******************************************************************************/

 `include "falcon_header.svh"

 module falcon_approx_exp (
    input   clk,
    input   rst_n,
    input   start,
    input   logic [`FALCON_X - 1 : 0]   x,      // Q1.63
    input   logic [`FALCON_CCS - 1 : 0] ccs,    // Q1.63
    output  logic [`FALCON_Y - 1 : 0]   y,
    output  logic done
);

    localparam logic [`FALCON_CCS - 1 : 0] C [`FALCON_C_QUANTITY] = '{
        64'h00000004741183A3, 64'h00000036548CFC06, 64'h0000024FDCBF140A,
        64'h0000171D939DE045, 64'h0000D00CF58F6F84, 64'h000680681CF796E3,
        64'h002D82D8305B0FEA, 64'h011111110E066FD0, 64'h0555555555070F00,
        64'h155555555581FF00, 64'h400000000002B400, 64'h7FFFFFFFFFFF4800,
        64'h8000000000000000
    };


    logic [`FALCON_Y - 1 : 0]       y_tmp;
    logic [`FALCON_Y - 1 : 0]       z;
    logic [`FALCON_Y * 2 - 1 : 0]   zy;

    typedef enum logic [1 : 0] { 
        INITIAL_ST  = 2'b00, 
        WAIT_ST     = 2'b01, 
        ASSIGN_ST   = 2'b10
    } state_t;

    state_t curr_state, next_state;
    logic [3 : 0] idx_1, idx_2; // counter 1 in loop, counter 2 out loop

    
    radix_4_16d #(.N(`MULTI_N))
    multiplier_16d(
        .clk    (clk),
        .rst_n  (rst_n),
        .a      (z),
        .b      (y_tmp),
        .p      (zy)
    );




    always_ff @(posedge clk) begin
        if(!rst_n)
            curr_state <= INITIAL_ST;
        else
            curr_state <= next_state;
    end


    always_comb begin

        next_state = curr_state;

        case(curr_state)
            INITIAL_ST : begin
                if(start) next_state = WAIT_ST;     // pulse start
            end

            WAIT_ST : begin
                if(idx_1 == 15) next_state = ASSIGN_ST;
            end

            ASSIGN_ST : begin
                if(idx_2 == 13) 
                    next_state = INITIAL_ST;
                else
                    next_state = WAIT_ST;
            end

            default : next_state = INITIAL_ST;
        endcase
    end


    always_ff @(posedge clk) begin
        if(!rst_n) begin
            idx_1 <= '0;
            idx_2 <= '0;
            y_tmp <= '0;
            y     <= '0;
            z     <= '0;
            done  <= 1'b0;
        end else begin
            case(curr_state)
                INITIAL_ST : begin
                        done <= 1'b0;
                    if(start) begin
                        y_tmp <= C[0];
                        idx_2 <= '0;
                        idx_1 <= '0;
                        z     <= x;
                    end
                end

                WAIT_ST : begin
                    idx_1 <= idx_1 + 1;
                    if(idx_1 == 15) begin
                        idx_2 <= idx_2 + 1;
                        idx_1 <= '0;
                    end
                end

                ASSIGN_ST : begin
                    if(idx_2 < 13) y_tmp <= C[idx_2] - zy[126 : 63];
                    if(idx_2 == 12) z <= ccs;
                    if(idx_2 == 13) begin
                        y <= zy[126 : 63];
                        done <= 1'b1;
                    end
                end

                default : begin
                    idx_1 <= '0;
                    idx_2 <= '0;
                    y_tmp <= '0;
                    z     <= '0;
                    y     <= '0;
                    done  <= 1'b0;
                end
            endcase
        end
    end

endmodule



