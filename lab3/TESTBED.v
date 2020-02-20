`include "PATTERN.v"
`include "MTX_MUL.v"

module TESTBED;

initial begin
  // $fsdbDumpfile( "MTX_MUL.fsdb" );
  // $fsdbDumpvars;
end

wire clock, load, ready;
wire [7:0] A, B;
wire [17:0] MP;

MTX_MUL main( .clk( clock ), .load( load ), .m1( A ), .m2( B ), .ready( ready ), .MP( MP ) );
PATTERN pattern( .clock( clock ), .load( load ), .A( A ), .B( B ), .ready( ready ), .MP( MP ) );

endmodule
