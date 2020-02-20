`timescale 1ps/100fs

module PATTERN( clk, load, A, B, ready, product );

input ready;
input [15:0] product;
output clk, load;
output [7:0] A, B;

reg clk, load;
reg [7:0] A, B;
wire [15:0] P;

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

assign P = A * B;

initial begin

  load = 0;

  for ( i = 0 ; i < testNum ; i = i + 1 ) begin
    @( negedge clk ) load = 1;
    A = $random(seed) % 9'd256;
    B = $random(seed) % 9'd256;
    @( negedge clk ) load = 0;

    for ( run = 0 ; run < 21 ; run = run + 1 ) begin
      if ( run == 20 ) begin
        $display( "==================================================" );
        $display( "        Error !! The Latency is too long!         " );
        $display( "==================================================" );
        $finish;
      end // if
      if ( ready === 1 ) begin
        if ( product !== P ) begin
          $display( "==================================================" );
          $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
          $display( "                  A = %d, B = %d                  ", A, B );
          $display( "              correct : %d your : %d              ", P, product );
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
