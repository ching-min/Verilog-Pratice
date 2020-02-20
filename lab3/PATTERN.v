`timescale 1ps/100fs

module PATTERN( clock, load, A, B, ready, MP );

input ready;
input [17:0] MP;
output clock, load;
output [7:0] A, B;

reg clock, load;
reg [7:0] A, B;

parameter CYCLE = 1.0;
parameter testNum = 10000;

//---------------------------------------------------------------------
//   CLOCK GENERATION
//---------------------------------------------------------------------

initial begin
  clock = 0;
end

always #(CYCLE/2.0) clock = ~clock;

//---------------------------------------------------------------------
//   MAIN FLOW
//---------------------------------------------------------------------

reg [7:0] a[0:15];
reg [7:0] b[0:15];
reg [17:0] mp[0:15];
integer i, j, run, seed;

initial begin
  load = 0;
  A = 0;
  B = 0;

  for ( i = 0 ; i < testNum ; i = i + 1 ) begin
    @( negedge clock );

    for ( j = 0 ; j < 16 ; j = j + 1 ) begin // input
      if ( ready !== 0 ) begin
        $display( "==================================================" );
        $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
        $display( "             The ready should be low!             " );
        $display( "==================================================" );
        $finish;
      end // if

      load = 1;
      A = $random(seed) % 9'd256;
      B = $random(seed) % 9'd256;
      a[j] = A;
      b[j] = B;

      @( negedge clock );
    end // for

    load = 0;
    A = 0;
    B = 0;

    // ans
    mp[0]  = a[0]  * b[0]  + a[1]  * b[4] + a[2]  * b[8]  + a[3]  * b[12];
    mp[1]  = a[0]  * b[1]  + a[1]  * b[5] + a[2]  * b[9]  + a[3]  * b[13];
    mp[2]  = a[0]  * b[2]  + a[1]  * b[6] + a[2]  * b[10] + a[3]  * b[14];
    mp[3]  = a[0]  * b[3]  + a[1]  * b[7] + a[2]  * b[11] + a[3]  * b[15];
    mp[4]  = a[4]  * b[0]  + a[5]  * b[4] + a[6]  * b[8]  + a[7]  * b[12];
    mp[5]  = a[4]  * b[1]  + a[5]  * b[5] + a[6]  * b[9]  + a[7]  * b[13];
    mp[6]  = a[4]  * b[2]  + a[5]  * b[6] + a[6]  * b[10] + a[7]  * b[14];
    mp[7]  = a[4]  * b[3]  + a[5]  * b[7] + a[6]  * b[11] + a[7]  * b[15];
    mp[8]  = a[8]  * b[0]  + a[9]  * b[4] + a[10] * b[8]  + a[11] * b[12];
    mp[9]  = a[8]  * b[1]  + a[9]  * b[5] + a[10] * b[9]  + a[11] * b[13];
    mp[10] = a[8]  * b[2]  + a[9]  * b[6] + a[10] * b[10] + a[11] * b[14];
    mp[11] = a[8]  * b[3]  + a[9]  * b[7] + a[10] * b[11] + a[11] * b[15];
    mp[12] = a[12] * b[0]  + a[13] * b[4] + a[14] * b[8]  + a[15] * b[12];
    mp[13] = a[12] * b[1]  + a[13] * b[5] + a[14] * b[9]  + a[15] * b[13];
    mp[14] = a[12] * b[2]  + a[13] * b[6] + a[14] * b[10] + a[15] * b[14];
    mp[15] = a[12] * b[3]  + a[13] * b[7] + a[14] * b[11] + a[15] * b[15];

    for ( run = 0 ; run < 101 ; run = run + 1 ) begin
      @( negedge clock );

      if ( run == 100 ) begin
        $display( "==================================================" );
        $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
        $display( "             The latency is too long!             " );
        $display( "==================================================" );
        $finish;
      end // if

      if ( ready === 1 ) begin
        for ( j = 0 ; j < 16 ; j = j + 1 ) begin
          if ( ready !== 1 ) begin
            $display( "==================================================" );
            $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
            $display( "            The ready should be high!             " );
            $display( "==================================================" );
            $finish;
          end // if

          if ( MP !== mp[j] ) begin
            $display( "==================================================" );
            $display( "              PATTERN #%d  FAILED!!!              ", i + 1 );
            $display( "         correct mp%d : %d your mp%d : %d         ", j + 1, mp[j], j + 1, MP );
            $display( "==================================================" );
            $finish;
          end // if

          @( negedge clock );
        end // for

        run = 100;
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
