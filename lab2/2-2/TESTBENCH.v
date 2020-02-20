`include "PATTERN.v"
`include "divider.v"

module TESTBENCH;

initial begin
  //$fsdbDumpfile( "divider.fsdb" );
  //$fsdbDumpvars;
end

wire clk, load, ready;
wire [7:0] d1, d2, QUOTN, REMDR;

divider main( .clk( clk ), .load( load ), .d1( d1 ), .d2( d2 ), .ready( ready ), .QUOTN( QUOTN ), .REMDR( REMDR ) );
PATTERN pattern( .clk( clk ), .load( load ), .d1( d1 ), .d2( d2 ), .ready( ready ), .QUOTN( QUOTN ), .REMDR( REMDR ) );

endmodule
