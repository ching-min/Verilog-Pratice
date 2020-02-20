`include "PATTERN.v"
`include "multiplier.v"

module TESTBENCH;

initial begin
  //$fsdbDumpfile( "multiplier.fsdb" );
  //$fsdbDumpvars;
end

wire clk, load, ready;
wire [7:0] A, B;
wire [15:0] product;

multiplier main( .clk( clk ), .load( load ), .A( A ), .B( B ), .ready( ready ), .product( product ) );
PATTERN pattern( .clk( clk ), .load( load ), .A( A ), .B( B ), .ready( ready ), .product( product ) );

endmodule
