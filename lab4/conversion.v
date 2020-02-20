`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:42:57 01/21/2015 
// Design Name: 
// Module Name:    conversion 
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
/*module conversion( ready, postfix, clk, reset, load, infix );
	input clk, reset, load;
	input [7:0] infix;
	output wire ready;
	output wire [7:0] postfix;
	parameter state0= 2'b00, state1= 2'b01, state2= 2'b10, state3= 2'b11;
	reg[1:0] current_state;
	wire[1:0] next_state;
	reg[7:0] infixx_cnt, postfix_cnt;
	reg[255:0] infix_in, infixx, opnd_buf, postfix_out;
	reg[135:0] optr_buf;
	reg infix_load, postfix_done, postfix_sent;
	
    assign next_state = ( load || reset )? state0: 
						( current_state == state0 && infix_load == 1'b1 )? state1:
						( current_state == state1 && postfix_done== 1'b1 )? state2 :
						( current_state == state2 && postfix_sent== 1'b1 )? state3 : current_state;
						
	always@( reset or load or posedge clk )begin
		if( reset ) current_state <= state0;
		else current_state <= next_state;
	end

	//store infix into "infix_in" array!!~infix_in
	always@( reset or posedge clk )begin
		if( reset || postfix_sent ) infix_in <= { 32{ 8'h00 } };//||postfix_sent
		else if( load ) infix_in <= { infix_in[ 247:0 ], infix };
		else infix_in <= infix_in;
	end
	
	//define the time the "infix_in" array is completed!!~infix_load
	always@( posedge reset or negedge load )begin
		if( reset ) infix_load <= 1'b0;
		else if( ~load ) infix_load <= 1'b1;
		else infix_load <= infix_load;
	end
	
	//store "infix_in" into "infixx", "infixx" is inputing-factor array!!
	//store "0~9" into "opnd_buf", and store "+", "-", "*", "/", "(" into "optr_buf"~ 
	always@( posedge reset or posedge clk )begin
		if( reset || load )begin  
			opnd_buf <= { 32{ 8'h00 } };
            optr_buf <= { 17{ 8'h00 } };
            infixx <= { 32{ 8'h00 } };
            infixx_cnt <= 8'd33;    // purposely 1
                                    // larger than 32
            postfix_done <= 1'b0;
		end
		else begin 
			if( current_state == state1 )begin
				if( infixx_cnt == 8'd33 )begin  //first time~
					infixx <= infix_in; 
					infixx_cnt <= infixx_cnt-8'h01;
				end
				else if( infixx[ 255:248 ] == 8'h00 )begin  
					infixx <= { infixx[ 247:0 ], 8'hFF };
					infixx_cnt <= infixx_cnt-8'h01;
				end
				else if( infixx[ 255:248 ] != 8'hFF )begin   
					case( infixx[ 255:248 ] )
					8'h30, 8'h31, 8'h32, 8'h33, 8'h34, //"0~9"
					8'h35, 8'h36, 8'h37, 8'h38, 8'h39:
						begin 
							opnd_buf <= { opnd_buf[247:0], infixx[ 255:248 ] };   
							optr_buf <= optr_buf;
							infixx <= { infixx[ 247:0 ], 8'hFF };
							infixx_cnt <= infixx_cnt - 8'h01;
						end
					8'h28:                           //"(" 
						begin 
							opnd_buf <= opnd_buf;   
							optr_buf <= { optr_buf[ 127:0 ], infixx[ 255:248 ] };
							infixx <= { infixx[ 247:0 ], 8'hFF };
							infixx_cnt <= infixx_cnt - 8'h01;
						end
					8'h29:                           // ")"
						begin
							if( optr_buf[ 7:0 ] != 8'h28 )begin //left eight bits of optr_buf are not "("
								opnd_buf <= { opnd_buf[ 247:0 ], optr_buf[ 7:0 ] };
								optr_buf <= { 8'h00, optr_buf[ 135:8 ] }; //shift right
								infixx <= infixx;
							end
							else begin  //left eight bits of optr_buf are "("
								opnd_buf <= opnd_buf;
								optr_buf <= { 8'h00, optr_buf[ 135:8 ] }; //shift right  
								infixx <= { infixx[ 247:0 ], 8'hFF };
								infixx_cnt <= infixx_cnt - 8'h01;
							end
						end
					8'h2B:					// "+"
						begin
							if( optr_buf[ 7:0 ] == 8'h2A || optr_buf[ 7:0 ] == 8'h2F 
							|| optr_buf[ 7:0 ] == 8'h2B || optr_buf[ 7:0 ] == 8'h2D )begin //"+","-","*","/"
								opnd_buf <= { opnd_buf[ 247:0 ], optr_buf[ 7:0 ] };
								optr_buf <= { 8'h00, optr_buf[ 135:8 ] };
								infixx <= infixx;
								// optr_buf<= {optr[135:8]};
								// infixx<= {infixx[247:0], 8™hFF};
							end
							else begin 
								opnd_buf <= opnd_buf;
								optr_buf <= { optr_buf[ 127:0 ], infixx[ 255:248 ] };
								infixx <= { infixx[ 247:0 ], 8'hFF };
								infixx_cnt <= infixx_cnt - 8'h01;
							end
						end
					8'h2D:					// "-"
						begin
							if( optr_buf[ 7:0 ] == 8'h2A || optr_buf[ 7:0 ] == 8'h2F 
							|| optr_buf[ 7:0 ] == 8'h2B || optr_buf[ 7:0 ] == 8'h2D )begin 
								opnd_buf <= { opnd_buf[ 247:0 ], optr_buf[ 7:0 ]};
								optr_buf <= { 8'h00, optr_buf[ 135:8 ] };
								infixx <= infixx; 
								// optr_buf <= {optr[135:8], infixx[255:248]};
								// infixx <= {infixx[247:0], 8™hFF};
							end
							else begin 
								opnd_buf <= opnd_buf;
								optr_buf <= { optr_buf[ 127:0 ], infixx[ 255:248 ] };
								infixx <= { infixx[ 247:0 ], 8'hFF };
								infixx_cnt <= infixx_cnt - 8'h01;
							end
						end
					8'h2A, 8'h2F:                        //  "*","/"
						begin
							if( optr_buf[ 7:0 ] == 8'h2A || optr_buf[ 7:0 ] == 8'h2F )begin 
								opnd_buf <= { opnd_buf[ 247:0 ], optr_buf[ 7:0 ] };
								optr_buf <= { 8'h00, optr_buf[ 135:8 ] };
								infixx <= infixx;
								// optr_buf<= {optr[135:8], infixx[255:248]};
								// infixx<= {infixx[247:0], 8™hFF};
							end
							else begin 
								opnd_buf <= opnd_buf;
								optr_buf <= { optr_buf[ 127:0 ], infixx[ 255:248 ] };
								infixx <= { infixx[ 247:0 ], 8'hFF };
								infixx_cnt <= infixx_cnt-8'h01;
							end
						end
					default:                  // what to do here???
						begin 
							//!!!opnd_buf <= { opnd_buf[ 247:0 ], infixx[ 255:248 ] };
							opnd_buf <= opnd_buf;
							optr_buf <= optr_buf;
							infixx <= { infixx[ 247:0 ], 8'hFF };
							infixx_cnt <= infixx_cnt - 8'h01;
						end
					endcase
					//!!!infixx_cnt <= infixx_cnt-8'h01;
					postfix_done <= 1'b0;
				end
				else begin                    // all FFs in infixx~empty
					if( optr_buf[ 7:0 ] != 8'h00 )begin  //dump optr_buf
						opnd_buf <= { opnd_buf[ 247:0 ], optr_buf[ 7:0 ] };
						optr_buf <= { 8'h00, optr_buf[ 135:8 ] };
					end
					else postfix_done <= 1'b1;   
				end
			end
			else begin  //not in state1
				opnd_buf <= opnd_buf;  
				optr_buf <= optr_buf;
				infixx <= infixx;
				infixx_cnt <= infixx_cnt;
                postfix_done <= postfix_done;
			end
		end
	end	
	
	//store postfix into "postfix_out" array!!!~postfix_out
	always@( posedge reset or posedge load or negedge clk )begin//!!!or posedge load
		if( reset || load )begin//!!!||load  
			postfix_out <= { 32{ 8'hFF } };
			postfix_sent <= 1'b0;
            postfix_cnt <= 8'h21;   // purposely 1
                                    // larger than 32
        end
		else if( current_state == state2 )begin
			if( postfix_cnt == 8'h21 )begin	
				postfix_out <= opnd_buf;
				postfix_cnt <= postfix_cnt - 8'h01;
			end
			else if( postfix_out[ 255:247 ] == 8'h00 )begin  
				postfix_out <= { postfix_out[ 247:0 ], 8'hFF };
				postfix_cnt <= postfix_cnt - 8'h01;
			end  
			else if( postfix_cnt != 8'h01 )begin//!!!8'h01  
				postfix_out <= { postfix_out[ 247:0 ], 8'h00 };
				postfix_cnt <= postfix_cnt - 8'h01;
			end
			else  postfix_sent <= 1'b1;
		end
		else  begin  
			postfix_out <= postfix_out;
            postfix_sent <= postfix_sent;
            postfix_cnt <= postfix_cnt;
		end
	end
	
	assign postfix = ( ready )? postfix_out[ 255:248 ]: 8'hFF;
	
	assign ready = ( current_state == state2 && postfix_out[ 255:248 ] != 8'hFF //!!!8'hFF 
					&& postfix_out[ 255:248 ] != 8'h00 )?  1'b1: 1'b0; //!!!8'h00
						
endmodule*/
module conversion(
	ready,postfix,
	clk,reset,load,infix
);
input clk, reset, load;
input [7:0] infix;
output ready;
output [7:0] postfix;

wire [1:0] next_state;
reg [1:0] crnt_state;
reg [255:0] infix_in, opnd_buf, infixx, postfix_out;
reg [135:0] optr_buf;
reg infix_load, postfix_sent, postfix_done;
reg [7:0] postfix_cnt;
reg [7:0] infixx_cnt;  

wire  [7:0] postfix;
wire ready;  

//coding for  FSM block:
parameter   state0= 2'b00, state1= 2'b01, state2= 2'b10, state3= 2'b11;

assign next_state= 
			( load || reset )?            	state0 :
         (crnt_state==state0 &&
				infix_load== 1'b1)?         	state1 :
         (crnt_state==state1 &&
				postfix_done== 1'b1)?      	state2 :
         (crnt_state==state2 &&
				postfix_sent== 1'b1)?      	state3 : crnt_state;
always@(reset or posedge clk or load)
   if(reset)      crnt_state<=  state0;
   else         	crnt_state<=  next_state;
	
//coding for infix-strobing block: 
always@(reset or posedge clk)
	if(reset|| postfix_sent)       infix_in<={32{8'h00}};//////
	else if(load)    infix_in<={infix_in[247:0], infix};//¤@­Ó­Ó¿é¤J
	else          infix_in<=infix_in;
always@(posedge reset or negedge load)//¿é¤J§¹¦¨
	if(reset)         infix_load<= 1'b0;
	else if(~load)
							infix_load<= 1'b1;
	else              infix_load<= infix_load;
	
//coding for infix-postfix conversion block:
   // PUSH of opnd_statck(0~9) and PUSH/POP of optr_stack(+,-,*,/)
always@(posedge reset or posedge clk)
   if(reset || load)  begin  
		opnd_buf<= {32{8'h00}};
      optr_buf<= {17{8'h00}};
      infixx<= {32{8'h00}};
      infixx_cnt<=8'd33;   // purposely 1
                          // larger than 32
      postfix_done<= 1'b0;
   end
   else begin
		if(crnt_state==state1)
			if(infixx_cnt==8'd33) begin  
				infixx<=infix_in; 
				infixx_cnt<= infixx_cnt-8'h01;//±q33¶}©l¦©
			end
			else if(infixx[255:248]==8'h00)begin  
				infixx<={infixx[247:0], 8'hFF};//¤@ª½¿é¤J­È
				infixx_cnt<= infixx_cnt-8'h01;
			end
			else if(infixx[255:248]!=8'hFF) begin   //§ì³Ì¥ªÃä ¨ìFF§¹²¦
				case(infixx[255:248])
					8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 
					8'h35, 8'h36, 8'h37, 8'h38, 8'h39:begin  //0~9
						opnd_buf<= {opnd_buf[247:0], infixx[255:248]};   
						optr_buf<= optr_buf;//+-*/¤£°Ê
						infixx<= {infixx[247:0], 8'hFF};//¨C§ì¤@­Ó´N¥ª²¾¡A¿é¤JFF
						infixx_cnt<= infixx_cnt-8'h01;//-1
					end
					8'h28:  begin                         // "("
						opnd_buf<= opnd_buf;   //¼Æ¦r¤£°Ê
						optr_buf<= {optr_buf[127:0], infixx[255:248]};//§ì¶i(
						infixx<= {infixx[247:0], 8'hFF};//²¾°Ê
						infixx_cnt<= infixx_cnt-8'h01;//-1
					end
					8'h29:                           // ")"
						if(optr_buf[7:0]!=8'h28)  begin //­Y³Ì·s¦sªº¤£¬O(
							opnd_buf<={opnd_buf[247:0], optr_buf[7:0]};//§âoptrªº³Ì·s­Èpop¨ìopnd
							optr_buf<={8'h00, optr_buf[135:8]}; //¦]¬°[7:0]ªÅ¤F  ©Ò¥H©¹¥k²¾
							infixx<= infixx;//Ä~Äò§PÂ_ª½¨ì(
						end
						else begin //¦pªG)«eªº¬O(
							opnd_buf<= opnd_buf;//¿é¥X¤£°Ê
							optr_buf<= { 8'h00, optr_buf[135:8]};//ª½±µ²¾°Ê  
							infixx<= {infixx[247:0], 8'hFF};//infixx§ó·s
							infixx_cnt<= infixx_cnt-8'h01;
						end
					8'h2B:                        // "+"
						if(optr_buf[7:0]==8'h2A ||
							optr_buf[7:0]==8'h2F ||
							optr_buf[7:0]==8'h2B ||
							optr_buf[7:0]==8'h2D) begin 
								opnd_buf<= {opnd_buf[247:0], optr_buf[7:0]};//­Y¹J¨ìÀu¥ý§Ç¤j©óµ¥©ó¦Û¤vªº¡A«h¥ýpop¸Ì­±ªº
								optr_buf<= {8'h00, optr_buf[135:8]};//¦V¥ª²¾
								infixx<= infixx;
						// optr_buf<= {optr[135:8], infixx[255:248]};
						// infixx<= {infixx[247:0], 8'hFF};
						end
						else begin 
							opnd_buf<= opnd_buf;//Àu¥ý§Ç¤p©ó¦Û¤vªº
							optr_buf<= {optr_buf[127:0], infixx[255:248]};//§â¦Û¤v¦s¤J
							infixx<= {infixx[247:0], 8'hFF};//infixx²¾°Ê
							infixx_cnt<= infixx_cnt-8'h01;
						end
					8'h2D:                            // "-"
						if(optr_buf[7:0]==8'h2A ||
							optr_buf[7:0]==8'h2F ||
							optr_buf[7:0]==8'h2B ||
							optr_buf[7:0]==8'h2D) begin 
								opnd_buf<= {opnd_buf[247:0], optr_buf[7:0]};
								optr_buf<= {8'h00, optr_buf[135:8]};
								infixx<= infixx; 
						// optr_buf<= {optr[135:8], infixx[255:248]};
						// infixx<= {infixx[247:0], 8'hFF};
						end
						else begin 
							opnd_buf<= opnd_buf;
							optr_buf<= {optr_buf[127:0], infixx[255:248]};
							infixx<= {infixx[247:0], 8'hFF};
							infixx_cnt<= infixx_cnt-8'h01;
						end
					8'h2A,                            // "*", "/"
					8'h2F: 
						if(optr_buf[7:0]==8'h2A ||//Àu¥ýÅvµ¥©ó¦Û¤vªº(*,/) ¦]¬°¨S¦³¤j©ó¦Û¤vªº
							optr_buf[7:0]==8'h2F) begin 
								opnd_buf<= {opnd_buf[247:0], optr_buf[7:0]};
								optr_buf<= {8'h00, optr_buf[135:8]};
								infixx<= infixx;
						// optr_buf<= {optr[135:8], infixx[255:248]};
						// infixx<= {infixx[247:0], 8'hFF};
						end
						else begin //Àu¥ý§Ç<¦Û¤v(Ex.+,-)
							opnd_buf<= opnd_buf;
							optr_buf<= {optr_buf[127:0], infixx[255:248]};//¦s¶i¥h!
							infixx<= {infixx[247:0], 8'hFF};
							infixx_cnt<= infixx_cnt-8'h01;
						end
					default:    begin              // what to do here???
						//¿ù°Õ!!!!opnd_buf<= {opnd_buf[247:0], infixx[255:248]};
						opnd_buf<=opnd_buf;
						optr_buf<= optr_buf;
						infixx<= {infixx[247:0], 8'hFF};
						infixx_cnt<= infixx_cnt-8'h01;
					end
				endcase
			//¿ù°Õ!!!!!infixx_cnt<= infixx_cnt-8'h01;
			postfix_done<=1'b0;
			end
      
			else                     // all FFs in infixx
				if(optr_buf[7:0]!=8'h00) begin//dump optr_buf//§â³Ñ¤Uªºoptr¥Î¥X¨Ó
					opnd_buf<= {opnd_buf[247:0], optr_buf[7:0]};
					optr_buf<= {8'h00, optr_buf[135:8]};
				end
				else     postfix_done<= 1'b1;   //³£°µ§¹«á´N§¹¦¨°Õ!!!!
			
		else  begin  
			opnd_buf<= opnd_buf;  // not in state1
         optr_buf<= optr_buf;
         infixx<= infixx;
         infixx_cnt<=infixx_cnt;
         postfix_done<= postfix_done;
		end
	end
	
//coding for postfix output block:
always@( posedge reset or posedge load or negedge clk )begin//!!!or posedge load
	if( reset || load )begin//!!!||load  
		postfix_out <= { 32{ 8'hFF } };
		postfix_sent <= 1'b0;
      postfix_cnt <= 8'h21;   // purposely 1
                              // larger than 32
    end
	else if( crnt_state== state2 )begin
		if( postfix_cnt == 8'h21 )begin	
			postfix_out <= opnd_buf;
			postfix_cnt <= postfix_cnt - 8'h01;
		end
		else if( postfix_out[ 255:247 ] == 8'h00 )begin  
			postfix_out <= { postfix_out[ 247:0 ], 8'hFF };
			postfix_cnt <= postfix_cnt - 8'h01;
		end  
		else if( postfix_cnt != 8'h01 )begin//!!!8'h01  
			postfix_out <= { postfix_out[ 247:0 ], 8'h00 };
			postfix_cnt <= postfix_cnt - 8'h01;
			end
		else  postfix_sent <= 1'b1;
	end
	else  begin  
		postfix_out <= postfix_out;
      postfix_sent <= postfix_sent;
      postfix_cnt <= postfix_cnt;
	end
end
	
assign   postfix= (ready)? postfix_out[255:248] : 	8'hFF;
assign   ready= (crnt_state== state2 &&
						postfix_out[255:248]!=8'hFF &&
						postfix_out[255:248]!=8'h00)? 	 1'b1 : 1'b0;
						
endmodule
