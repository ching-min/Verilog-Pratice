`timescale 1ns/100ps

module PATTERN( A, B, load, P, done, busy );

input [15:0] P;
input done, busy;
output [7:0] A, B;
output load;

reg [7:0] A, B;
reg load;
reg [15:0] ans;

always @( * ) begin
  ans = A * B;
end

initial begin
  A = 8;
  B = 2;
  load = 0;
  #5 // 5
  A = 0;

  #2 // t1 = 7
  load = 1;
  #1 // 8
  CheckBusy;
  load = 0;
  #1 // 9
  CheckAns;

  #6 // 15
  B = 11;

  #3 // t2 = 18
  load = 1;
  #1 // 19
  CheckBusy;
  load = 0;
  #1 // 20
  CheckAns;

  #2 // 22
  A = 12;

  #4 // t3 = 26
  load = 1;
  #1 // 27
  CheckBusy;
  load = 0;
  #1 // 28
  CheckAns;

  #7 // 35
  A = 13;

  #6 // t4 = 41
  load = 1;
  #1 // 42
  CheckBusy;
  load = 0;
  #1 // 43
  CheckAns;

  #7 // 50
  B = 15;

  #8 // t5 = 58
  load = 1;
  #1 // 59
  CheckBusy;
  load = 0;
  #1 // 60
  CheckAns;

  #10 // 70
  B = 8;
  #5 // 75
  A = 7;

  #4 // t6 = 79
  load = 1;
  #1 // 80
  CheckBusy;
  load = 0;
  #1 // 81
  CheckAns;

  #14 // 95
  A = 9;
  #20 // 115
  B = 7;
  #5 // 120
  A = 5;

  #3 // t7 = 123
  load = 1;
  #1 // 124
  CheckBusy;
  load = 0;
  #1 // 125
  CheckAns;

  #5 // 130
  $display("====================");
  $display(" You pass this demo ");
  $display("        ^_^         ");
  $display("====================");
  $finish;
end

task CheckBusy; begin
  if ( busy !== 1 ) begin
    $display( "==================================================" );
    $display( "        Error !! The busy should be high!         " );
    $display( "==================================================" );
    $finish;
  end
end
endtask

task CheckAns; begin
  if ( busy !== 0 ) begin
    $display( "==================================================" );
    $display( "         Error !! The busy should be low!         " );
    $display( "==================================================" );
    $finish;
  end
  if ( done !== 1 ) begin
    $display( "==================================================" );
    $display( "        Error !! The done should be high!         " );
    $display( "==================================================" );
    $finish;
  end
  if ( P !== ans ) begin
    $display( "==================================================" );
    $display( "                     Error!!                      " );
    $display( "            correct P : %d your P : %d            ", ans, P );
    $display( "==================================================" );
    $finish;
  end
end
endtask

endmodule
