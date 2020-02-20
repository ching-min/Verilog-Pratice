`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:36:04 01/21/2015 
// Design Name: 
// Module Name:    multiplier 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module multiplier(clk, load, A, B, ready, product);
	input clk,load;
	input [7:0]A,B;
	output ready;
	output [15:0] product;
	reg[7:0] m1,m2,BB;
	reg [15:0] pp16;
	reg [1:0] current_state;
	reg AB_load,multiply_done;
	reg [3:0] shift_cnt;
	wire [1:0] next_state;
	wire [4:0] next_cnt;
	
	always@(load) 
		if(load)  {m1, m2}<={A, B} ;
		else      {m1, m2}<={m1, m2}; 
		
	always@(load or current_state)
			if(load)                    AB_load<= 1'b1;
			else if(current_state==2'b10)  AB_load<= 1'b0;
			else                      AB_load<= AB_load;
			
	assign  next_state= (load)? 2'b00 :
			 (current_state==2'b00 && AB_load)? 2'b01 :
          (current_state==2'b01 && multiply_done)? 2'b10 :
			 (current_state==2'b10 && multiply_done)? 2'b10 : current_state;//2'b11;
						
	always@(posedge clk or posedge load)
		if(load)  current_state <= 2'b00;
		else    current_state<= next_state;
		
	always@(posedge clk or posedge load)
		if(load)  pp16<= 16'h0000;
		else if(current_state==2'b01 && shift_cnt<4'h8)
         pp16<= (BB[7])? ( {pp16[14:0], 1'b0} + {8'h00, m1}) : {pp16[14:0], 1'b0};//
		else    pp16<=pp16;
		
	always@(posedge clk or posedge load)
		if(load)                  shift_cnt<=4'h0;
		else if(current_state==2'b01) shift_cnt<= next_cnt;
		else                    shift_cnt<= shift_cnt;
	assign  next_cnt= (load)?                 4'b0 :
                (current_state==2'b01 &&  
                 shift_cnt<4'h9)?        shift_cnt+1 :
                                       shift_cnt;
	always@(posedge clk or posedge load)
		if(load)                       BB<=m2;
		else if(current_state==2'b01 && shift_cnt>=4'h0 && shift_cnt<4'h9) BB<= {BB[6:0], 1'b0};
		else                          BB<=BB;
	always@(posedge clk or posedge load)
		if(load)   multiply_done<= 1'b0 ;
		else if (current_state==2'b01 && shift_cnt==4'h9) multiply_done<= 1'b1;
		else      multiply_done<= multiply_done;
		
	assign  ready= (load)? 1'b0 :(current_state==2'b10 && multiply_done)?  1'b1 : 1'b0;
	assign  product= (load)? 16'h0000 :(current_state==2'b10 && multiply_done)? pp16 : 16'h0000;


endmodule
