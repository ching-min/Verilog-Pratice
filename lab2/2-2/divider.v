`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:30:55 01/20/2015 
// Design Name: 
// Module Name:    divider 
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
module full_adder( Cout, S, A, B, Cin );
	input A, B, Cin;
	output Cout, S;
	assign S = A ^ B ^ Cin;
	assign Cout = ( A & B )|( A & Cin )|( B & Cin );
endmodule

module full_adder4( Cout, S, A, B, Cin );
	input[3:0] A, B;
	input Cin;
	output[3:0] S;
	output Cout;
	wire w1, w2, w3;
	full_adder unit1( w1, S[0], A[0], B[0], Cin );
	full_adder unit2( w2, S[1], A[1], B[1], w1 );
	full_adder unit3( w3, S[2], A[2], B[2], w2 );
	full_adder unit4( Cout, S[3], A[3], B[3], w3 );
endmodule

module full_adder8( S, C_y, A, B, C_in );
	input[7:0] A, B;
	input C_in;
	output [7:0] S;
	output wire C_y;
	wire w;
	full_adder4 unit1( w, S[3:0], A[3:0], B[3:0], C_in );
	full_adder4 unit2( C_y, S[7:4], A[7:4], B[7:4], w );
endmodule

module subtraction( S, A, B );
	input[7:0] A, B;
   output[7:0] S;
	wire C;
	wire[7:0] _B;
	assign _B = ~B;
	full_adder8 unit1( S, C, A, _B, 1'b1 );//補數=?+1;C=0?<B; C=1?>=B;
endmodule

module divider( QUOTN, REMDR, ready, d1, d2, load, clk );
	input[7:0] d1, d2;
	input load, clk;
	output reg[7:0] QUOTN, REMDR;
    output reg ready;
	reg[15:0] p; //form the shift platform ~
	reg[7:0] D1, D2; //D1, D2 store the d1, d2 signal when load high!!
	reg[3:0] counter; //count how many times p shifts!!
	wire[7:0] sum;

	subtraction unit1( sum[7:0], p[15:8], D2[7:0] );

	always@( posedge clk )begin
		if( load )begin
			D1 <= d1;
			D2 <= d2;
			p <= { 8'h00, d1[7:0] };
			ready <= 0;
			counter <= 0;//after load
		end
		else begin
			if ( counter == 8 ) begin
				if ( p[15:8] >= D2[7:0] ) begin 					//when 被除> ?? pΥ?被除- ??後玥左shift, 裍
					p[15:0] = { sum[7:0], p[7:1], 1'b1 };
				end
				ready <= 1;
				QUOTN <= p[7:0]; //往左shift 8 次毼????//when 被除< ??
				REMDR <= p[15:8];		  // 餘數????
			end
			else  begin
				if( p[15:8] < D2[7:0] )begin //when 被除< ?? p?Υ往左shift, 裍
					p[15:0] <= { p[14:0], 1'b0 };
					counter <= counter + 4'b0001;
				end
				else begin 					//when 被除> ?? pΥ?被除- ??後玥左shift, 裍
					p[15:0] <= { sum[6:0], p[7:1], 2'b10 };
					counter <= counter + 4'b0001;
				end
			end
		end
	end
endmodule
