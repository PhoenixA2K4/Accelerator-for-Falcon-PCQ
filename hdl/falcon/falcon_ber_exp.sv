/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : falcon_ber_exp
 *    Company     : Academy of Cryptography Techniques
 *    Project     : falcon_accelerator
 *    Author      : ducduy
 *    Module/Class: falcon_ber_exp.sv
 *    Create Date : Aug 30th 2026
 *    Last Update : Aug 30th 2026
 *    Description : ApproxExp -> BerExp -> SamplerZ
 ******************************************************************************/

`include "falcon_header.svh"

module falcon_ber_exp (
	input   																						 clk,
  input   																						 rst_n,
  input   																						 start,
  input   logic [`FALCON_X - 1 : 0] 									 x,       				// Q8.56
  input   logic [`FALCON_CCS - 1 : 0] 								 ccs,   					// Q1.63
  input   logic [`FALCON_UNIFORM_BITS_BER_EXP - 1 : 0] uniform_bits,
  output  logic 																			 uniform_req,
  output  logic 																			 check_bit,
  output  logic 																			 done
);


	localparam logic [`FALCON_X - 1 : 0] ln2_t = 64'h5C551D94AE54E9F6;    // Q2.62
	localparam logic [`FALCON_X - 1 : 0] ln2 	 = 64'hB17217F7D1DEDE8B;    // Q0.64


	logic [`FALCON_X - 1 : 0]       a, b;
	logic [(2*`FALCON_X) - 1 : 0]   p;
	logic [`FALCON_X - 1 : 0]       s_tmp;
	logic [5 : 0]                   s;
	logic [`FALCON_X - 1 : 0]       r;      															// Q0.64
	logic [`FALCON_Y : 0]           z;
	logic [`FALCON_X - 1 : 0]       x_reg;

	logic [3 : 0] idx_1;
	logic [4 : 0] idx_2;

 	logic [5 : 0] byte_shift;

 	logic                     approx_en;
 	logic [`FALCON_Y - 1 : 0] approx_o;
 	logic                     approx_done;


 	radix_4_16d #(.N(64))
 	multiplier_16d(
  	.clk    (clk),
  	.rst_n  (rst_n),
  	.a      (a),
  	.b      (b),
  	.p      (p)
 	);


	falcon_approx_exp APPROX_EXP(
  	.clk    (clk),
  	.rst_n  (rst_n),
  	.start  (approx_en),
  	.x      (r),
  	.ccs    (ccs),
  	.y      (approx_o),
  	.done   (approx_done)
	);


  typedef enum logic [2 : 0] {
  	IDLE_ST,
  	S_ST,
  	R_ST,
  	APPROX_ST,
  	RAND_REQ_ST,
  	CHECK_ST
	} state_t;


 	state_t curr_state, next_state;

 	always_ff @(posedge clk) begin
  	if(!rst_n)
     	curr_state <= IDLE_ST;
   	else
  		curr_state <= next_state;
 	end


 	/**********************************************************************
  	* Next-state logic
  	**********************************************************************/
 	always_comb begin
 		next_state = curr_state;
   	case(curr_state)
    	IDLE_ST : begin
      	if(start) next_state = S_ST;
    	end

     	S_ST : begin
      	if(idx_1 == 15) next_state = R_ST;
     	end

    	R_ST : begin
       	if(idx_2 == 16) next_state = APPROX_ST;
    	end

    	APPROX_ST : begin
       	if(approx_done) next_state = RAND_REQ_ST;
    	end

    	RAND_REQ_ST : begin
      	next_state = CHECK_ST;
    	end

    	CHECK_ST : begin
      	if((uniform_bits == ((z >> byte_shift) & 8'hFF)) && (byte_shift != 0)) begin
        	next_state = RAND_REQ_ST;
      	end else begin
         	next_state = IDLE_ST;
       	end
    	end

     	default : begin
      	next_state = IDLE_ST;
     	end
   	endcase
  end


 	/**********************************************************************
  	* Combinational output logic
  	**********************************************************************/
 	always_comb begin
    a           = '0;
    b           = '0;
    check_bit   = 1'b0;
    done        = 1'b0;
    // approx_en   = 1'b0;
    uniform_req = 1'b0;
    case(curr_state)
    	IDLE_ST : begin
     		// approx_en = 1'b0;
     		if(start) begin
         	a = x;
          b = ln2_t;
          // uniform_req = 1'b1;
     		end
 			end

    	S_ST : begin
    	end

    	R_ST : begin
      	a = s_tmp;
       	b = ln2;
    	end

     	APPROX_ST : begin
      	// approx_en = 1'b1;
     	end

     	RAND_REQ_ST : begin
        uniform_req = 1'b1;
     	end

      CHECK_ST : begin
      	if (uniform_bits < ((z >> byte_shift) & 8'hFF)) begin
       		check_bit = 1'b1;
       		done      = 1'b1;
      	end
      	else if (uniform_bits > ((z >> byte_shift) & 8'hFF)) begin
       		check_bit = 1'b0;
       		done      = 1'b1;
      	end
      	else begin
       		if(byte_shift == 0) begin
          	check_bit = 1'b0;
          	done      = 1'b1;
       		end
      	end
      end

    	default : begin
      	a           = '0;
      	b           = '0;
      	check_bit   = 1'b0;
      	done        = 1'b0;
      	// approx_en   = 1'b0;
      	uniform_req = 1'b0;
    	end
    endcase
 	end


  /**********************************************************************
   * Sequential datapath
   **********************************************************************/
    always_ff @(posedge clk) begin : non_blocking_output_logic
    	if(!rst_n) begin
      	idx_1      <= '0;
      	idx_2      <= '0;
      	s_tmp      <= '0;
      	r          <= '0;
      	s          <= '0;
      	z          <= '0;
      	x_reg      <= '0;
      	byte_shift <= 6'd56;
      	approx_en  <= 1'b0;
    	end else begin
      	case(curr_state)
         	IDLE_ST : begin
          	idx_1      <= '0;
          	idx_2      <= '0;
          	s_tmp      <= '0;
          	r          <= '0;
          	s          <= '0;
          	z          <= '0;
          	byte_shift <= 6'd56;
          	if(start) x_reg <= x;
       		end

       		S_ST : begin
        		idx_1 <= idx_1 + 1;
        		if(idx_1 == 15) s_tmp <= {54'd0, p[127 : 118]};
       		end

        	R_ST : begin
        		idx_2 <= idx_2 + 1;
        		if(idx_2 == 16) begin
        			approx_en <= 1'b1;
          		if(s_tmp == '0) begin
              	r <= {x_reg[56 : 0], 7'd0};
              	s <= 6'd0;
          		end else begin
            		if({x_reg, 8'd0} >= p[71 : 0]) begin
               		r <= ({x_reg, 8'd0} - p[71 : 0]) >> 1;
            		end else begin
               		r <= 64'd0;
            		end
            		s <= (s_tmp > 64'd63)? 6'd63 : s_tmp[5 : 0];
          		end
        		end
        	end

        	APPROX_ST : begin
        		approx_en <= 1'b0;
        		if(approx_done) begin
        	    z <= ({1'b0, approx_o, 1'b0} - 1) >> s;
        	    byte_shift <= 6'd56;
        		end
        	end

       		RAND_REQ_ST : begin
       		end

       		CHECK_ST : begin
         		if ((uniform_bits == ((z >> byte_shift) & 8'hFF)) && (byte_shift != 0)) begin
          	  byte_shift <= byte_shift - 6'd8;
         		end
       		end

     			default : begin
        		idx_1      <= '0;
        		idx_2      <= '0;
        		s_tmp      <= '0;
        		r          <= '0;
        		s          <= '0;
        		z          <= '0;
        		x_reg      <= '0;
        		byte_shift <= 6'd56;
        		approx_en  <= 1'b0;
     			end
  			endcase
  		end
		end : non_blocking_output_logic
	endmodule