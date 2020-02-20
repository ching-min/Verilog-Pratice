`timescale 1ps/100fs

module PATTERN( clk, load, d1, d2, ready, QUOTN, REMDR );

input ready;
input [7:0] QUOTN, REMDR;
output clk, load;
output [7:0] d1, d2;

reg clk, load;
reg [7:0] d1, d2;
wire [7:0] Q, R;

parameter CYCLE = 1.0;
parameter testNum = 7;

//---------------------------------------------------------------------
//   CLOCK GENERATION
//---------------------------------------------------------------------

initial begin
  clk = 0;
end

always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//   MAIN FLOW
//---------------------------------------------------------------------

integer i, run, seed;

assign Q = d1 / d2;
assign R = d1 % d2;

initial begin

  load = 0;

  for ( i = 0 ; i < testNum ; i = i + 1 ) begin
    @( negedge clk ) load = 1;
    d1 = $random(seed) % 9'd256;
    d2 = $random(seed) % 9'd256;
    @( negedge clk ) load = 0;

    for ( run = 0 ; run < 21 ; run = run + 1 ) begin
      if ( run == 20 ) begin
        $display( "==================================================" );
        $display( "        Error !! The Latency is too long!         " );
        $display( "==================================================" );
        $finish;
      end // if
      if ( ready === 1 ) begin
        if ( QUOTN !== Q || REMDR !== R ) begin
          $display( "==================================================" );
          $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
          $display( "                 d1 = %d, d2 = %d                 ", d1, d2 );
          $display( "        correct QUOTN : %d your QUOTN : %d        ", Q, QUOTN );
          $display( "        correct REMDR : %d your REMDR : %d        ", R, REMDR );
          $display( "==================================================" );
          $finish;
        end // if
        run = 20;
      end // if
      @( negedge clk );
    end // for

    $display( "Pattern No.%d passed", i + 1 );
  end // for

  $display( "====================" );
  $display( " You pass this demo " );
  $display( "        ^_^         " );
  $display( "====================" );
  $finish;
end

endmodule
