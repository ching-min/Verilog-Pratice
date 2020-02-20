`include "PATTERN.v"
`include "conversion.v"

module TESTBED;

initial begin
  // $fsdbDumpfile( "conversion.fsdb" );
  // $fsdbDumpvars;
end

wire clk, reset, load, ready;
wire [7:0] infix, postfix;

conversion main( .clk( clk ), .reset( reset ), .load( load ), .infix( infix ), .ready( ready ), .postfix( postfix ) );
PATTERN pattern( .clk( clk ), .reset( reset ), .load( load ), .infix( infix ), .ready( ready ), .postfix( postfix ) );

endmodule
