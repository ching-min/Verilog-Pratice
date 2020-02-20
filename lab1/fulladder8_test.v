`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:13:21 11/06/2014
// Design Name:   fulladder8
// Module Name:   D:/Users/chmhu0502/Desktop/New folder/full_adder8/fulladder8_test.v
// Project Name:  full_adder8
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fulladder8
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fulladder8_test;

	// Inputs
	reg [7:0]a;
	reg [7:0]b;
	reg c;

	// Outputs
	wire [7:0]s;
	wire cout;
	
	

	// Instantiate the Unit Under Test (UUT)
	fulladder8 uut (
		.a(a), 
		.b(b), 
		.c(c), 
		.s(s), 
		.cout(cout)
	);
	fulladder8 f(a,b,c,s,cout);
	initial c=1'b0;

	initial begin

		// Initialize Inputs
		a=8'h08;
		#5 a=8'h00;
		#17 a=8'h0C;
		#13 a=8'd242;
		#40 a=8'h07;
		#20 a=8'h09;
		#25 a=8'h05;
		end
	initial begin
		b=8'h02;
		#15 b=8'h0B;
		#35 b=8'h0F;
		#20 b=8'h08;
		#45 b=8'h07;
		end
		fulladder8 fu(a,b,c,s,cout);
		// Wait 100 ns for global reset to finish
	initial #130 $finish;
		// Add stimulus here

//	end
      
endmodule

