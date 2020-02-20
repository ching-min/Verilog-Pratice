`include "PATTERN.v"
`include "multiply8.v"

module TESTBED();

wire [7:0] A, B;
wire load, done, busy;
wire [15:0] P;

multiply8 main( .A( A ), .B( B ), .load( load ), .P( P ), .done( done ), .busy( busy ) );
PATTERN pattern( .A( A ), .B( B ), .load( load ), .P( P ), .done( done ), .busy( busy ) );

endmodule
