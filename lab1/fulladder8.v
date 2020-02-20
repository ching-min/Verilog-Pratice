`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:50:24 11/06/2014 
// Design Name: 
// Module Name:    fulladder8 
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
module fulladder (a,b,c,s,cout);
    input a,b,c;
    output s,cout;
	 wire w1,w2,w3;
	 
	 xor(w1,a,b);
	 xor(s,w1,c);//sum
	 and(w2,w1,c);
	 and(w3,a,b);
	 or(cout,w2,w3);
    

endmodule


module fulladder4(a,b,c,s,cout);
    input [3:0] a;
    input [3:0] b;
    input c;
    output [3:0] s;
    output cout;
	 wire w1,w2,w3;
	 fulladder f1(a[0],b[0],1'd0,s[0],w1);
	 fulladder f2(a[1],b[1],w1,s[1],w2);
	 fulladder f3(a[2],b[2],w2,s[2],w3);
	 fulladder f4(a[3],b[3],w3,s[3],cout);
    

endmodule


module fulladder8(a,b,c,s,cout);
    input [7:0] a;
    input [7:0] b;
    input c;
    output [7:0] s;
    output cout;
	 wire w1;
	 fulladder4 f1(a[3:0],b[3:0],1'd0,s[3:0],w1);
	 fulladder4 f2(a[7:4],b[7:4],w1,s[7:4],cout);
    


endmodule
