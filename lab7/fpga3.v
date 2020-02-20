`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:54:26 12/25/2014 
// Design Name: 
// Module Name:    fpga3 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:58:45 12/22/2014 
// Design Name: 
// Module Name:    fpga3 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fpga3(SW,rot_A,rot_B,rot_dwn,BTN0,BTN1,BTN2,reset,clk,LED,R,G,B,h_sync,v_sync);
input [3:0]SW;
input rot_A,rot_B,rot_dwn;
input BTN0,BTN1,BTN2;
input reset,clk;
output [7:0]LED;
output R,G,B;
output wire h_sync,v_sync;

wire [10:0]X_pix,Y_pix;
reg RR,GG,BB;
wire R210,R212,R214,R216,R220,R230,R240,R250;
wire G210,G220,G230,G240,G250,G212,G216,G214;
wire B210,B220,B230,B240,B250,B212,B216,B214;
reg [19:0]debcnt;
wire H_on,V_on;


reg [10:0]H_scan,V_scan,X_cntr;
wire [10:0]RAD;
reg [2:0]pattn,pattn_scal;
reg [3:0]rot_indx;
reg deb_A,deb_AA,dett_A,deb_B,dett_B;
wire scal1;
reg scal2;
wire scal_change;
// block for H_scan: 1-1040 //定義座標


// block for H_scan: 1-1040 
always@(posedge reset or posedge clk)
  if(reset)                 H_scan= 11'h000;
  else if(H_scan== 11'd1040)  H_scan= 11'h001;
  else                    H_scan= H_scan+11'h001; 
// block for V_scan: 1-666 
always@(posedge reset or posedge clk)
  if(reset)                 V_scan= 11'h000;
  else if(V_scan== 11'd666 &&H_scan== 11'd1040 )  V_scan= 11'h001;
  else if(H_scan== 11'd1040)  V_scan= V_scan+11'h001; 
  else                     V_scan= V_scan;

// block for H_on and V_on
assign  H_on= (H_scan>= 11'd0105 && H_scan<= 11'd0904);
assign  V_on= (V_scan>= 11'd0023 && V_scan<= 11'd0622);

// block for h_sync and v_sync
assign  h_sync= ~(H_scan>= 11'd0921 && H_scan<= 11'd1040);
assign  v_sync= ~(V_scan>= 11'd0659 && V_scan<= 11'd0666);

// block for X_pix and Y_pix
assign  X_pix= (H_scan>11'd0104 && H_scan<11'd0905)? H_scan - 11'd0105 : 11'd0000;
assign  Y_pix= (V_scan>11'd0022 && V_scan<11'd0623)? V_scan - 11'd0023 : 11'd0000;

assign  R= RR;
assign  G= GG;            			  
assign  B= BB;

always@(*)
 if(~H_on || ~V_on || ~SW[0])                   RR=1'b0;
else if(pattn==3'b001 &&
	  (X_pix>=11'd0401 && X_pix<=11'd0800))  RR= 1'b1;
 else if(pattn==3'b010)
      case({pattn_scal, rot_indx}) 
	   7'b0010000:                           RR= R210;
	   7'b0010001:                           RR= R210; 
       7'b0010010:                           RR= R212;
		  7'b0010011:                           RR= R214;
       7'b0010100:                           RR= R214;
	   7'b0010101:                           RR= R214; 
       7'b0010110:                           RR= R216;
	   7'b0010111:                           RR= R216;
       7'b0100000,   
	   7'b0100001,    
       7'b0100010,   
	   7'b0100011,   	
       7'b0100100,   
		7'b0100101,    
        7'b0100110,   
	    7'b0100111:                          RR= R220;
        7'b0110000,   
	    7'b0110001,    
        7'b0110010,   
	    7'b0110011,   	
        7'b0110100,   
		7'b0110101,    
        7'b0110110,   
		7'b0110111:                          RR= R230;
        7'b1000000,   
		7'b1000001,    
        7'b1000010,   
		7'b1000011,   	
        7'b1000100,   
		7'b1000101,    
        7'b1000110,   
	    7'b1010111:                         RR= R240;	
        7'b1010000,   
	    7'b1010001,    
        7'b1010010,
	    7'b1010011,
        7'b1010100,   
		7'b1010101,    
        7'b1010110,   
		7'b1010111:                         RR= R250;
		default:                             RR= 1'b0;
		  endcase				
else if(pattn==3'b100 && (X_pix-X_cntr)*(X_pix-X_cntr)+3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)
			   RR = 1'b1;
else                                       RR= 1'b0;	
// - - - - - - - - - - - subfunctional modules
assign  
        R210= (-75*X_pix-29*Y_pix<=-37250 &&  
               -75*X_pix+29*Y_pix>=-22750 &&
		  			Y_pix>=250 && Y_pix<=325)?      1:0,
       /*R210= (-75*X_pix-29*Y_pix>-37250)?      0:
		     (-75*X_pix+29*Y_pix<-22750)?     0:
		     (Y_pix>325)?                    0:
		     (Y_pix<250)?                    0: 1;//頭朝下*/
/*assign*/  R220= (-150*X_pix-58*Y_pix<=-71600 &&  
             -150*X_pix+58*Y_pix>=-48400 &&
			 Y_pix>=200 && Y_pix<=350)?        1:0,//
       R230= (-225*X_pix-87*Y_pix<=-103050 &&  
              -225*X_pix+87*Y_pix>=-76950 &&
		      Y_pix>=150 && Y_pix<=375)?        1:0,
	   R240= (-300*X_pix-115*Y_pix<=-131500 &&  
             -300*X_pix+115*Y_pix>=-108500 &&
			  Y_pix>=100 && Y_pix<=400)?        1:0,
	   R250= (-375*X_pix-144*Y_pix<=-157200 &&  
             -375*X_pix+144*Y_pix>=-142800 &&
			  Y_pix>=50 && Y_pix<=425)?         1:0;
assign  
		R212= (-29*X_pix+75*Y_pix>=9450 &&  
               29*X_pix+75*Y_pix<=35550 &&X_pix>=375 && X_pix<=450)?       1:0,
		R216= (-29*X_pix-75*Y_pix<=-32650 &&  
               29*X_pix-75*Y_pix>=-12350 &&
			   X_pix>=350 && X_pix<=425)?       1:0,
		R214= (-75*X_pix+29*Y_pix<=-19850 &&  
               -75*X_pix-29*Y_pix>=-40150 &&
			   Y_pix>=275 && Y_pix<=350)?       1:0;	

always@(*)
   if(~H_on || ~V_on || ~SW[1])                    GG=1'b0;
 else if(pattn==3'b001 &&
	   ((X_pix>=11'd0101 && X_pix<=11'd0200) ||
		(X_pix>=11'd0301 && X_pix<=11'd0400)||(X_pix>=11'd0501&&X_pix<=11'd0600 )||(X_pix>=11'd0701&&X_pix<=11'd0800)))   GG= 1'b1;
 else if(pattn==3'b010 )
     case({pattn_scal,rot_indx})
	  7'b0010000,                                 
	  7'b0010001:                        GG= G210;
	  7'b0010010:                        GG= G212;
	  7'b0010011,                        
	  7'b0010100,                        
	  7'b0010101:                        GG= G214;
	  7'b0010110,                        	  
	  7'b0010111:                        GG= G216;
	  7'b0100000, 7'b0100001, 7'b0100010,  
		7'b0100011, 7'b0100100, 7'b0100101,    
      7'b0100110, 7'b0100111:               GG= G220;
		7'b0110000, 7'b0110001, 7'b0110010,   
	   7'b0110011, 7'b0110100, 7'b0110101,    
      7'b0110110, 7'b0110111:               GG= G230;
		7'b1000000, 7'b1000001, 7'b1000010,   
		7'b1000011, 7'b1000100, 7'b1000101,    
      7'b1000110, 7'b1010111:               GG= G240;
		7'b1010000, 7'b1010001, 7'b1010010,
	   7'b1010011, 7'b1010100, 7'b1010101,    
      7'b1010110, 7'b1010111:               GG= G250;
		default:                              GG= 1'b0;
    endcase
 else if(pattn==3'b100 && (X_pix-X_cntr)*(X_pix-X_cntr)+ 3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)   
			                                 GG= 1'b1;
 else                                         GG= 1'b0;
// - - - - - - - - - - - - subfunctional modules
assign  G210= (-75*X_pix-29*Y_pix<=-37250 &&  
             -75*X_pix+29*Y_pix>=-22750 &&
			 Y_pix>=250 && Y_pix<=325)?          1:0,
	   G220= (-150*X_pix-58*Y_pix<=-71600 &&  
             -150*X_pix+58*Y_pix>=-48400 &&
			  Y_pix>=200 && Y_pix<=350)?         1:0,
	 G230= (-225*X_pix-87*Y_pix<=-103050 &&  
             -225*X_pix+87*Y_pix>=-76950 &&
			  Y_pix>=150 && Y_pix<=375)?         1:0,
	   G240= (-300*X_pix-115*Y_pix<=-131500 &&  
             -300*X_pix+115*Y_pix>=-108500 &&
			  Y_pix>=100 && Y_pix<=400)?         1:0,
	   G250= (-375*X_pix-144*Y_pix<=-157200 &&  
             -375*X_pix+144*Y_pix>=-142800 &&
			  Y_pix>=50 && Y_pix<=425)?          1:0;

assign  
		G212= (-29*X_pix+75*Y_pix>=9450 &&  
               29*X_pix+75*Y_pix<=35550 &&X_pix>=375 && X_pix<=450)?       1:0,
		G216= (-29*X_pix-75*Y_pix<=-32650 &&  
               29*X_pix-75*Y_pix>=-12350 &&
			   X_pix>=350 && X_pix<=425)?       1:0,
		G214= (-75*X_pix+29*Y_pix<=-19850 &&  
               -75*X_pix-29*Y_pix>=-40150 &&
			   Y_pix>=275 && Y_pix<=350)?       1:0;	

		
always@(*)
 if(~H_on || ~V_on || ~SW[2])                   BB=1'b0;
else if(pattn==3'b001 && 
	  ((X_pix>=11'd0201 && X_pix<=11'd0400)||
	   (X_pix>=11'd0601 && X_pix<=11'd0800)))   BB= 1'b1;
 else if(pattn==3'b010)
    case({pattn_scal,rot_indx})
	  7'b0010000,                                 
	  7'b0010001:                        BB= B210;
	  7'b0010010:                        BB= B212;
	  7'b0010011,                        
	  7'b0010100,                        
	  7'b0010101:                        BB= B214;
	  7'b0010110,                        	  
	  7'b0010111:                        BB= B216;
	  7'b0100000, 7'b0100001, 7'b0100010,  
		7'b0100011, 7'b0100100, 7'b0100101,    
      7'b0100110, 7'b0100111:               BB= B220;
		7'b0110000, 7'b0110001, 7'b0110010,   
	   7'b0110011, 7'b0110100, 7'b0110101,    
      7'b0110110, 7'b0110111:               BB= B230;
		7'b1000000, 7'b1000001, 7'b1000010,   
		7'b1000011, 7'b1000100, 7'b1000101,    
      7'b1000110, 7'b1010111:               BB= B240;
		7'b1010000, 7'b1010001, 7'b1010010,
	   7'b1010011, 7'b1010100, 7'b1010101,    
      7'b1010110, 7'b1010111:               BB= B250;
		default:                              BB= 1'b0;
    endcase
  else if(pattn==3'b100 && (X_pix-X_cntr)*(X_pix-X_cntr)+3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)   
			                                BB= 1'b1;
  else                                        BB= 1'b0;
// - - - - - - - - subfunctional modules
assign  B210= (-75*X_pix-29*Y_pix<=-37250 &&  
             -75*X_pix+29*Y_pix>=-22750 &&
			  Y_pix>=250 && Y_pix<=325)?        1:0,
	   B220= (-150*X_pix-58*Y_pix<=-71600 &&  
             -150*X_pix+58*Y_pix>=-48400 &&
			  Y_pix>=200 && Y_pix<=350)?        1:0,
       B230= (-225*X_pix-87*Y_pix<=-103050 &&  
             -225*X_pix+87*Y_pix>=-76950 &&
				 	  Y_pix>=150 && Y_pix<=375)?        1:0,
	   B240= (-300*X_pix-115*Y_pix<=-131500 &&  
             -300*X_pix+115*Y_pix>=-108500 &&
			  Y_pix>=100 && Y_pix<=400)?        1:0,
	   B250= (-375*X_pix-144*Y_pix<=-157200 &&  
             -375*X_pix+144*Y_pix>=-142800 &&
			  Y_pix>=50 && Y_pix<=425)?         1:0;

	assign	B212= (-29*X_pix+75*Y_pix>=9450 &&  
					29*X_pix+75*Y_pix<=35550 &&
					X_pix>=375 && X_pix<=450)?        1'b1:1'b0;
assign	B214= (-75*X_pix+29*Y_pix<=-19850 &&  
					-75*X_pix-29*Y_pix>=-40150 &&
					Y_pix>=275 && Y_pix<=350)?        1'b1:1'b0;	

assign	B216= (-29*X_pix-75*Y_pix<=-32650 &&  
					29*X_pix-75*Y_pix>=-12350 &&
				   X_pix>=350 && X_pix<=425)?        1'b1:1'b0;
always@(posedge reset or posedge clk)
  if(reset)      pattn<= 3'b000;           
  else if(BTN0)  pattn<= 3'b001;      // display of 8 vertical bars
  else if(BTN1)  pattn<= 3'b010;      // display of triangle 
  else if(BTN2)  pattn<= 3'b100;      // display of circles
  else         pattn<= pattn;
// block for pattn-scaling settings
always@(posedge reset or posedge clk)
 if(reset)                               debcnt= 20'h00000; 
 else if(rot_dwn && debcnt<20'hFFFFE)    debcnt= debcnt+20'h00001;
 else if(~rot_dwn && debcnt==20'hffffe)  debcnt= 20'h00000;
 else if(~rot_dwn && debcnt!=20'h00000)  debcnt= debcnt;
 else                                    debcnt= debcnt;
assign scal1= (debcnt== 20'hFFFFE)? 1 : 0;
always@(posedge reset or posedge clk)
 if(reset)         scal2= 1'b0;
 else              scal2= scal1; 
assign scal_change= scal1 && ~scal2;
 
always@(posedge reset or negedge clk)
 if(reset)                           pattn_scal= 3'b000;
 else if(scal_change && 
        SW[3] && pattn_scal<3'h5)   pattn_scal= pattn_scal+3'b001;
 else if(scal_change &&  ~SW[3] && pattn_scal>3'h1)  pattn_scal= pattn_scal-3'b001;
 else                                pattn_scal= pattn_scal;
always@(posedge reset or negedge clk)
 if(reset)  rot_indx= 4'h0;
 else if(deb_A & ~deb_AA)
       if(deb_B)    
		 begin
		 if(rot_indx==4'h0)
		      rot_indx= 
				      4'h7 ;
						else rot_indx=rot_indx- 4'h1;
				end
       else rot_indx= (rot_indx==4'h7)?  
		            4'h0 : rot_indx+ 4'h1;
 else       rot_indx= rot_indx;				

always@(posedge reset or posedge clk)
 if(reset)   begin dett_A=1'b1;
                  dett_B=1'b1;
            end
 else        begin dett_A=rot_A;
                  dett_B=rot_B;
            end 
									 
									 
always@(posedge reset or posedge clk) 
 if(reset)                   begin deb_A=1'b1;
                                   deb_B=1'b1;
                             end
 else if(dett_A && dett_B)   begin deb_A=1'b1;
                                   deb_B=deb_B;
                             end
 else if(~dett_A && ~dett_B) begin deb_A=1'b0;
                                   deb_B=deb_B;
                             end
 else if(~dett_A && dett_B)  begin deb_A=deb_A;
                                 deb_B=1'b1;
                             end
 else if(dett_A && ~dett_B)  begin deb_A=deb_A; 
                                   deb_B=1'b0;
                             end
									  
always@(posedge reset or posedge clk)
 if(reset)       deb_AA= 1'b1;
 else            deb_AA= deb_A;    // relationship btw deb_A and deb_AA?
 
 assign   RAD= (pattn_scal== 3'b000)?  11'd000 :
              (pattn_scal== 3'b001)?  11'd050 :
				  (pattn_scal== 3'b010)?  11'd100 :
				  (pattn_scal== 3'b011)?  11'd150 :
				  (pattn_scal== 3'b100)?  11'd200 :
				  (pattn_scal== 3'b101)?  11'd250 : 
				                       11'd000;
always@(*)
case({SW[3], rot_indx})
 5'h11:  X_cntr= 11'd430;
 5'h12:  X_cntr= 11'd450;
 5'h13:  X_cntr= 11'd470;
 5'h14:  X_cntr= 11'd500;
 5'h15:  X_cntr= 11'd530;
 5'h16:  X_cntr= 11'd550;
 5'h17:  X_cntr= 11'd570;
 5'h01:  X_cntr= 11'd370;
 5'h02:  X_cntr= 11'd350;
 5'h03:  X_cntr= 11'd330;
 5'h04:  X_cntr= 11'd300;
 5'h05:  X_cntr= 11'd270;
 5'h06:  X_cntr= 11'd250;
 5'h07:  X_cntr= 11'd230;
  default:    X_cntr= 11'd400;
endcase
 assign   LED[7:0]= {rot_indx, 1'b0, pattn};
 
 endmodule 