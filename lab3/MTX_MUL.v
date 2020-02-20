`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:26:38 12/04/2014 
// Design Name: 
// Module Name:    MTX_MUL 
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
module MTX_MUL( MP, ready, m1, m2, load, clk );
	input[7:0] m1, m2;
	input load, clk;
	output reg[17:0] MP; 
	output reg ready;
	
	reg[1:0] current_state, current_col, current_row;
	wire[1:0] next_state, next_col, next_row;
	reg[127:0] A, B;
	reg[7:0] counter1, counter2;
	reg[7:0] row_1, row_2, row_3, row_4, col_1, col_2, col_3, col_4;
	wire[7:0] next_counter2;
	reg[17:0] mp11, mp12, mp13, mp14, mp21, mp22, mp23, mp24; //remember 18 bits!!
	reg[17:0] mp31, mp32, mp33, mp34, mp41, mp42, mp43, mp44; //remember 18 bits!!
	wire[17:0] rc_product;
	reg AB_load, row_switch, mp_sent;
	wire mm_done, next_rowswitch;

	assign  next_state = ( load )? 2'b00 : 
				( current_state == 2'b00 && AB_load )? 2'b01 :
            ( current_state == 2'b01 && mm_done )? 2'b10 :
				( current_state == 2'b10 && mp_sent )? 2'b11 : current_state;
				
	always@( posedge clk or posedge load )begin
		if( load )  current_state <= 2'b00;
		else  current_state <= next_state;
	end
	
	always@( posedge clk )begin
		if( load ) begin //form matrix
			A <= { A[119:0], m1 }; 
			B <= { B[119:0], m2 }; 
			counter1 <= counter1 + 8'h01; 
		end
		else begin
			{A,B} <= {A,B};
			counter1 <= 8'h00;
		end
	end
	
	always@( negedge load )begin //define matrix_done when load~L!!
		if( counter1 ==8'h10 ) AB_load <= 1'b1;
		else AB_load <= 1'b0;
	end
	//define current_col&current_row
	assign  next_row = ( load )?  2'b00 :
			( current_state==2'b01 && current_row < 2'b11 && row_switch )?  
			( current_row + 2'b01 ) : current_row;
	
	assign  next_col = ( load )? 2'b00 :
			( current_state == 2'b01 && current_row == 2'b11 && current_col == 2'b11 )? current_col : 
			( current_state == 2'b01 && current_col == 2'b11 )?  2'b00 :
			( current_state == 2'b01 )?  
			( current_col + 2'b01 ) : current_col; 

	always@( posedge clk )begin
		row_switch <= next_rowswitch;
		if( load )begin  
			current_row <= 2'b00 ;       
			current_col <= 2'b00 ;
		end
		else begin 
			current_row <= next_row;    
			current_col <= next_col;
		end
	end

	assign  next_rowswitch = ( current_state != 2'b01 )? 1'b0 :
			( current_col == 2'b10 )? 1'b1 : 1'b0;   
	//define col&row multiplier
	always@( negedge clk )begin
        case( current_row )
        2'b00:  begin row_1 <=  A[127:120];
                      row_2 <=  A[119:112];
                      row_3 <=  A[111:104];
                      row_4 <=  A[103:96];
                end
        2'b01:  begin row_1 <=  A[95:88];
                      row_2 <=  A[87:80];
                      row_3 <=  A[79:72];
                      row_4 <=  A[71:64];
                end
        2'b10:  begin row_1 <=  A[63:56];
                      row_2 <=  A[55:48];
                      row_3 <=  A[47:40];
                      row_4 <=  A[39:32];
                end
        2'b11:  begin row_1 <=  A[31:24];
                      row_2 <=  A[23:16];
                      row_3 <=  A[15:8];
                      row_4 <=  A[7:0];
                end
        default:begin row_1 <=  row_1;
                      row_2 <=  row_2;
                      row_3 <=  row_3;
                      row_4 <=  row_4;
                end
        endcase 
	end	
	
	always@( negedge clk )begin
        case( current_col )
        2'b00:  begin col_1 <=  B[127:120];
                      col_2 <=  B[95:88];
                      col_3 <=  B[63:56];
                      col_4 <=  B[31:24];
                end
        2'b01:  begin col_1 <=  B[119:112];
                      col_2 <=  B[87:80];
                      col_3 <=  B[55:48];
                      col_4 <=  B[23:16];
                end
        2'b10:  begin col_1 <=  B[111:104];
                      col_2 <=  B[79:72];
                      col_3 <=  B[47:40];
                      col_4 <=  B[15:8];
                end
        2'b11:  begin col_1 <=  B[103:96];
                      col_2 <=  B[71:64];
                      col_3 <=  B[39:32];
                      col_4 <=  B[7:0];
                end
        default:begin col_1 <=  col_1;
                      col_2 <=  col_2;
                      col_3 <=  col_3;
                      col_4 <=  col_4;
                end
        endcase
	end
	
	assign   mm_done = current_row[1] & current_row[0] & current_col[1] & current_col[0];

	assign  rc_product = row_1*col_1 + row_2*col_2 + row_3*col_3 + row_4*col_4;
	
	always@( posedge clk )begin
		if( load ) ;//mp55 <= 16'h0000;
		else begin
			case( { current_row, current_col } )
			4'b0000:  mp11 <= rc_product;
			4'b0001:  mp12 <= rc_product;
			4'b0010:  mp13 <= rc_product;
			4'b0011:  mp14 <= rc_product;
			4'b0100:  mp21 <= rc_product;
			4'b0101:  mp22 <= rc_product;
			4'b0110:  mp23 <= rc_product;
			4'b0111:  mp24 <= rc_product;  
			4'b1000:  mp31 <= rc_product;
			4'b1001:  mp32 <= rc_product;
			4'b1010:  mp33 <= rc_product;
			4'b1011:  mp34 <= rc_product;
			4'b1100:  mp41 <= rc_product;
			4'b1101:  mp42 <= rc_product;
			4'b1110:  mp43 <= rc_product;
			4'b1111:  mp44 <= rc_product;
			default:  ;//mp55 <= 16'hFFFF;
			endcase
		end
	end	

	//define end matrix
	/*always@( posedge clk )begin
		if( load )begin
			counter2 <= 8'h00;  
			mp_sent <= 1'b0;
		end
		else begin
			if( mm_done )begin
				counter2 <= 8'h01;
				mp_sent <= 1'b0;
			end
			else begin
				if( ready && counter2 < 17 )begin 
					counter2 <= counter2 + 8'h01;
					mp_sent <= 1'b0;
				end
				else begin
					counter2 <= counter2;
					mp_sent <= 1'b1;
				end
			end
		end
	end*/
	assign next_counter2 = ( load )? 8'h00:
							  ( current_row == 2'b11 && current_col == 2'b10 )? 8'h01:
							  ( ready == 1'b1 && counter2 < 8'h11 )? ( counter2 + 8'h01 ): counter2;
							  
	always@( posedge clk )begin
		if( load ) counter2 <= 8'h00;
		else counter2 <= next_counter2;
	end
	
	always@( negedge clk or posedge load )begin
		if( load ) ready <= 1'b0;
		else if( mm_done && counter2 > 8'h00 && counter2 < 8'h11 ) ready <= 1'b1;
		else ready <= 1'b0;
	end
	
	always@( negedge clk )begin
		if( load ) MP <= 16'hFFFF;//don't care~
		else if( mm_done ) begin               
			case( counter2 ) 
			8'h01: MP <= mp11;
			8'h02: MP <= mp12;
			8'h03: MP <= mp13;
			8'h04: MP <= mp14;
			8'h05: MP <= mp21;
			8'h06: MP <= mp22;
			8'h07: MP <= mp23;
			8'h08: MP <= mp24;
			8'h09: MP <= mp31;
			8'h0A: MP <= mp32;
			8'h0B: MP <= mp33;
			8'h0C: MP <= mp34;
			8'h0D: MP <= mp41;
			8'h0E: MP <= mp42;
			8'h0F: MP <= mp43;
			8'h10: MP <= mp44;
			default: MP <= 16'hFFFF;//don't care~
			endcase			
		end
		else MP <= 16'hFFFF;	//don't care~
	end	
endmodule
	
	


