`timescale 1ps/100fs

module PATTERN( clk, reset, load, infix, ready, postfix );

input ready;
input [7:0] postfix;
output clk, reset, load;
output [7:0] infix;

reg clk, reset, load;
reg [7:0] infix;

parameter CYCLE = 5.0;

reg [7:0] in[0:250];
reg [7:0] numOfIn[0:20];
reg [7:0] out[0:158];
reg [7:0] numOfOut[0:20];
integer i, j, run, seed;
integer indexIn, indexOut;

always #(CYCLE/2.0) clk = ~clk;

initial begin
  $readmemh( "in.txt", in );
  $readmemh( "numOfIn.txt", numOfIn );
  $readmemh( "out.txt", out );
  $readmemh( "numOfOut.txt", numOfOut );
end

initial begin
  clk = 0;
  reset = 0;
  load = 0;
  infix = 0;
  indexIn = 0;
  indexOut = 0;
  #(0.1) reset = 1;
  #(2.1) reset = 0;

  for ( i = 0 ; i < 21 ; i = i + 1 ) begin
    @( negedge clk );

    load = 1;
    for ( j = 0 ; j < numOfIn[i] ; j = j + 1 ) begin // input
      if ( ready !== 0 ) begin
        $display( "==================================================" );
        $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
        $display( "             The ready should be low!             " );
        $display( "==================================================" );
        $finish;
      end // if

      infix = in[indexIn];
      indexIn = indexIn + 1;

      @( negedge clk );
    end // for
    if ( ready !== 0 ) begin
      $display( "==================================================" );
      $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
      $display( "             The ready should be low!             " );
      $display( "==================================================" );
      $finish;
    end // if
    load = 0;
    infix = 0;

    for ( run = 0 ; run < 1001 ; run = run + 1 ) begin
      @( negedge clk );

      if ( run == 1000 ) begin
        $display( "==================================================" );
        $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
        $display( "             The latency is too long!             " );
        $display( "==================================================" );
        $finish;
      end // if

      if ( ready === 1 ) begin
        for ( j = 0 ; j < numOfOut[i] ; j = j + 1 ) begin
          if ( ready !== 1 ) begin
            $display( "==================================================" );
            $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
            $display( "            The ready should be high!             " );
            $display( "==================================================" );
            $finish;
          end // if

          if ( postfix !== out[indexOut] ) begin
            $display( "==================================================" );
            $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
            $display( "         correct char : %c your char : %c         ", out[indexOut], postfix );
            $display( "==================================================" );
            $finish;
          end // if
          indexOut = indexOut + 1;

          @( negedge clk );
        end // for
        if ( ready !== 0 ) begin
          $display( "==================================================" );
          $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
          $display( "             The ready should be low!             " );
          $display( "==================================================" );
          $finish;
        end // if

        run = 1000;
      end // if
    end // for

    $display( "Pattern No.%d passed", i + 1 );
  end // for

  $display("====================");
  $display(" You pass this demo ");
  $display("        ^_^         ");
  $display("====================");
  $finish;
end

endmodule
