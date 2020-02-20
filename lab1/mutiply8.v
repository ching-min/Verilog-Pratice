`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:48:26 11/13/2014 
// Design Name: 
// Module Name:    mutiply 
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
module halfadder(A,B,S,C);
input A,B;
output S,C;
xor(S,A,B);
and(C,A,B);
endmodule

module fulladder(A,B,C,S,C_y);
    input A,B,C;
    output S,C_y;
	assign S=A^B^C;
	assign C_y=(A&B)|(A&C)|(B&C);
endmodule

module fulladder2(a,b,c,s,c_y);
	input[1:0] a,b;
	input c;
	output [1:0]s;
	output c_y;
	wire w1;
	fulladder f1(a[0],b[0],c,w1,c_y);
	fulladder f2(a[1],b[1],w,s[1],cout);
endmodule

module fulladder4(a,b,c,s,c_y);
    input [3:0] a;
    input [3:0] b;
    input c;
    output [3:0] s;
    output c_y;
	 wire w1,w2,w3;
	 fulladder f1(a[0],b[0],1'd0,s[0],w1);
	 fulladder f2(a[1],b[1],w1,s[1],w2);
	 fulladder f3(a[2],b[2],w2,s[2],w3);
	 fulladder f4(a[3],b[3],w3,s[3],c_y);
endmodule

module fulladder8(a,b,c,s,c_y);
    input [7:0] a;
    input [7:0] b;
    input c;
    output [7:0] s;
    output c_y;
	 wire w1;
	 fulladder4 f1(a[3:0],b[3:0],c,s[3:0],w1);
	 fulladder4 f2(a[7:4],b[7:4],w1,s[7:4],c_y);
endmodule

module mutiply2(A,B,P);
	input [1:0]A,B;
	output [3:0]P;
	wire w1,w2,w3,w4;
	assign P[0]=A[0]&B[0];
	assign w1=A[0]&B[1];
	assign w2=A[1]&B[0];
	assign w3=A[1]&B[1];
	fulladder f1(w1,w2,0,P[1],w4);
	halfadder h1(w4,w3,P[2],P[3]);
endmodule

module multiply4(A,B,load,P,ready);
    input [3:0] A,B;
	 input load;
    output wire [7:0] P;
	 output ready;
	 wire[3:0] ll,lh,hl,hh;//存mul的結果
	 wire c1,c2,c3,c4,c5,c6;
	 wire[1:0] sum1,sum2,C7;
	mutiply2 m1(A[1:0],B[1:0],ll);
	mutiply2 m2(A[3:2],B[1:0],hl);
	mutiply2 m3(A[1:0],B[3:2],lh);
	mutiply2 m4(A[3:2],B[3:2],hh);
	
	fulladder2 f1(ll[1:0],1'b0,1'b0,P[1:0],c1);
	fulladder2 f2(ll[3:2],lh[1:0],c1,sum1,c2);
	fulladder2 f3(sum1,hl[1:0],0,P[3:2],c3);
	fulladder2 f4(lh[3:2],hl[3:2],c2,sum2,c4);
	fulladder2 f5(hh[1:0],s2,c3,P[5:4],c5);
	assign C7={1'b0,c4};
	fulladder2 f6(hh[3:2],C7,c5,P[7:6],c6);//c6=0
	assign ready=(load)?1'b0:1'b1;
endmodule

module multiply8(A,B,load,P,done,busy);
	input [7:0] A, B;
	input load;
	output reg[15:0] P;
	wire [15:0]p_wire;
	output  done, busy;
	wire [7:0] ll,lh,hl,hh;//multiply4的結果
	wire w1,w2,w3,w4,w5,w6;//mul4相加的carry
	wire [3:0] s1,s2,W7;
	reg[15:0]p_reg;
	wire ready1,ready2,ready3,ready4;
	
	multiply4 m1(A[3:0],B[3:0],load,ll[7:0],ready1);
	multiply4 m2(A[7:4],B[3:0],load,hl[7:0],ready2);
	multiply4 m3(A[3:0],B[7:4],load,lh[7:0],ready3);
   multiply4 m4(A[7:4],B[7:4],load,hh[7:0],ready4);
	
	fulladder4 f1(ll[3:0],1'b0,1'b0,p_wire[3:0],w1);
	fulladder4 f2(lh[3:0],ll[7:4],w1,s1[3:0],w2);
	fulladder4 f3(hl[3:0],s1,1'b0,p_wire[7:4],w3);
	fulladder4 f4(lh[7:4],hl[7:4],w2,s2[3:0],w4);
	fulladder4 f5(hh[3:0],s2,w3,p_wire[11:8],w5);
	assign W7={0,0,0,w4};
	fulladder4 f6(hh[7:4],W7[3:0],w5,p_wire[15:12],w6);//w6=0
	assign done=(load)? 0:ready1&ready2&ready3&ready4 ;
	assign busy=(load)?1:(done)?0:1 ;
	always@(done)
	begin 
		if(done) P[15:0]<=p_wire[15:0];
			else P[15:0]<=P[15:0];
	end
//	assign P[15:0]=p_reg[15:0];
endmodule

