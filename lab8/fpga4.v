`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:42:13 01/08/2015 
// Design Name: 
// Module Name:    fpga4 
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
module fpga4(SW,rot_A,rot_B,rot_dwn,BTN0,BTN1,BTN2,reset,CLK,LED,R,G,B,
				h_sync,v_sync);
	 input [3:0] SW;
	input rot_A, rot_B, rot_dwn, BTN0, BTN1, BTN2, reset,CLK;
	output [7:0] LED;
	output R, G, B, h_sync, v_sync;
	 reg [19:0]debcnt0,debcnt1,debcnt2,debcnt,slow_clk;
	 reg gostop,gostop2;
	 reg [15:0]Rmvbody,Lmvbody,Rmvjaw0,Rmvjaw1,Rmvjaw2,Lmvjaw0,Lmvjaw1,Lmvjaw2;
	 reg [15:0]Umvbdy00,Umvbdy10,Umvbdy01,Umvbdy11,Umvbdy02,Umvbdy12;
	 reg [15:0]Dmvbdy00,Dmvbdy10,Dmvbdy01,Dmvbdy11,Dmvbdy02,Dmvbdy12;
	 reg pattn_scal;
	 reg [31:0] MNSTR_row;
	 reg [1:0] mvdir_indx;
	 wire[10:0] X_pix,Y_pix,MNSTR_y,delta_x,delta_y;
	 wire H_on,V_on,mvclk,gostop1,gostop3;
	 reg [2:0]act_cnt;
	 reg [10:0] H_scan,V_scan,body_x,body_y;
	 reg RR,GG,BB;
	 reg dett_A,dett_B,deb_A,deb_B,deb_AA;
	 reg [3:0] rot_indx;
	 wire MNSTR_on;
	 wire R_MNSTR,G_MNSTR,B_MNSTR;
	 
//coding for VGA H_sync/V_sync and display coordinates:
// block for H_scan: 1-1040 
	always@(posedge reset or posedge CLK)
	  if(reset)                 H_scan<= 11'h000;
	  else if(H_scan== 11'd1040)  H_scan<= 11'h001;
	  else                    H_scan<= H_scan+11'h001; 
	// block for V_scan: 1-666 
	always@(posedge reset or posedge CLK)
	  if(reset)                 V_scan<= 11'h000;
	  else if(V_scan== 11'd666 &&H_scan== 11'd1040 )  V_scan<= 11'h001;
	  else if(H_scan== 11'd1040)  V_scan<= V_scan+11'h001; 
	  else                     V_scan<= V_scan;

	// block for H_on and V_on
	assign  H_on= (H_scan>= 11'd0105 && H_scan<= 11'd0904);
	assign  V_on= (V_scan>= 11'd0024 && V_scan<= 11'd0623);

	// block for h_sync and v_sync
	assign  h_sync=~(H_scan>= 11'd0921 && H_scan<= 11'd1040);
	assign  v_sync=~(V_scan>= 11'd0661 && V_scan<= 11'd0666);

	// block for X_pix and Y_pix
	assign  X_pix= (H_scan>11'd0104 && H_scan<11'd0905)? H_scan - 11'd0104 : 11'd0000;
	assign  Y_pix= (V_scan>11'd0023 && V_scan<11'd0624)? V_scan - 11'd0023 : 11'd0000;

//coding for RGB control block:
	assign  R= RR;
	assign  G= GG;            			  
	assign  B= BB;
	
//coding for BTN0/1/2 debouncing block:
	always@(posedge reset or posedge CLK)
	 if(reset)      debcnt0<= 20'h00000; 
	 else if(BTN0 && debcnt0<20'hFFFFE)   debcnt0<= debcnt0+20'h00001;
	 else if(~BTN0 && debcnt0==20'hffffe) debcnt0<= 20'h00000;
	 else if(~BTN0 && debcnt0!=20'h00000) debcnt0<= debcnt0;
	 else          debcnt0<= debcnt0;

	always@(posedge reset or posedge CLK)
	 if(reset)      debcnt1<= 20'h00000; 
	 else if(BTN1 && debcnt1<20'hFFFFE)   debcnt1<= debcnt1+20'h00001;
	 else if(~BTN1 && debcnt1==20'hffffe) debcnt1<= 20'h00000;
	 else if(~BTN1 && debcnt1!=20'h00000) debcnt1<= debcnt1;
	 else        debcnt1<= debcnt1;

	always@(posedge reset or posedge CLK)
	 if(reset)     debcnt2<= 20'h00000; 
	 else if(BTN2 && debcnt2<20'hFFFFE)  debcnt2<= debcnt2+20'h00001;
	 else if(~BTN2 && debcnt2==20'hffffe) debcnt2<= 20'h00000;
	 else if(~BTN2 && debcnt2!=20'h00000) debcnt2<= debcnt2;
	 else        debcnt2<= debcnt2;
	 
//coding for block for MONSTER movement triggering block:
	always@(posedge reset or posedge CLK)
	 if(reset)      slow_clk<= 20'h00000; 
	 else if(slow_clk==20'hFFFFE) slow_clk<=20'h00000;//
	 else         slow_clk<= slow_clk+20'h00001;
	 
	assign  mvclk= (slow_clk==20'hFFFFE)? 1:0;

// block for act_cnt control: 0-1-2
	always@(posedge reset or negedge CLK)  
	  if(reset)              act_cnt<= 3'b000;
	  else if(~mvclk)         act_cnt<= act_cnt; 
	  else if(act_cnt==3'b100)  act_cnt<=3'b000;
	  else 				   act_cnt<= act_cnt+3'b001;

// block for MONSTER moving “direction” control
// mvdir_indx:         10: leftward   11: rightward
//                   00: upward    01: downward
	always@(posedge reset or negedge CLK)        
		if(reset)                   mvdir_indx<= 2'b11; 
		else if(debcnt0==20'h2FFFE)  mvdir_indx<={mvdir_indx[1], ~mvdir_indx[0]};
		else if(debcnt1==20'h2FFFE)  mvdir_indx<= ~mvdir_indx;
		else if(debcnt2==20'h2FFFE)  mvdir_indx<= {~mvdir_indx[1], mvdir_indx[0]};
		else                      mvdir_indx<= mvdir_indx;
// block for MONSTER moving “location” control
//	parameter   
	always@(posedge reset or posedge CLK)
	  if(reset)       {body_x, body_y}<= {11'd0400, 11'd0300};
	  else if(~gostop) {body_x, body_y}<= {body_x, body_y};
	  else if(mvclk)// begin 
		 if(mvdir_indx==2'b11) body_x<= (body_x+11'd0032+delta_x<11'd0800)?body_x+delta_x :  body_x;// moving right 
		 else if(mvdir_indx==2'b10) body_x<= (body_x>delta_x)? body_x-delta_x :  body_x;// moving left
		 else if(mvdir_indx==2'b00) body_y<= (body_y>delta_y)? body_y-delta_y :  body_y;// moving up
		 else if(mvdir_indx==2'b01) body_y<= (body_y+11'd32+delta_y<11'd0600)? body_y+delta_y :  body_y;// moving down
	 else {body_x, body_y}<={body_x, body_y};	

//coding for 'start-stop" block
	always@(posedge reset or posedge CLK)
	 if(reset)            debcnt<= 20'h00000; 
	 else if(rot_dwn && debcnt<20'hFFFFE) debcnt<= debcnt+20'h00001;
	 else if(~rot_dwn && debcnt==20'hffffe) debcnt<= 20'h00000;
	 else if(~rot_dwn && debcnt!=20'h00000) debcnt<= debcnt;
	 else              debcnt<= debcnt;
	assign gostop1=(debcnt== 20'hFFFFE||debcnt== 20'hFFFFD)? 1 : 0;
	always@(posedge reset or posedge CLK)
	 if(reset)    gostop2<= 1'b0;
	 else       gostop2<= gostop1; 
	assign      gostop3= gostop1 && ~gostop2;
	always@(posedge reset or negedge CLK)
	if(reset)         gostop<= 1'b0;
	else if(gostop3)  gostop<= ~gostop;
	else           gostop<= gostop; 
assign delta_x=rot_indx*11'd0001, delta_y=rot_indx*11'd0001;
	
	always@(posedge reset or negedge CLK)
		if(reset) rot_indx<=4'h0;
		else if(deb_A &~deb_AA)
			if(deb_B)
				if(rot_indx==4'h0) rot_indx<=rot_indx;
				else rot_indx<=rot_indx-4'h1;
			else
				if(rot_indx==4'h7) rot_indx<=rot_indx;
				else rot_indx<=rot_indx+4'h1;
		else rot_indx<=rot_indx;
	always@(posedge reset or posedge CLK)
		if(reset) begin dett_A<=1'b1;
							 dett_B<=1'b1;
					end
		else begin dett_A<=rot_A;
					  dett_B<=rot_B;
			end
	always@(posedge reset or posedge CLK)
		if(reset) begin deb_A<=1'b1;
							 deb_B<=1'b1;
							 end
		else if(dett_A&&dett_B) begin deb_A<=1'b1;
												deb_B<=deb_B;
										end
		else if(~dett_A&&~dett_B)begin deb_A<=1'b0;
												deb_B<=deb_B;	
										end
		else if(~dett_A&& dett_B)begin deb_A<=deb_A;
												deb_B<=deb_B;	
										end
		else if(dett_A&&~dett_B)begin deb_A<=deb_A;
												deb_B<=1'b0;	
										end
	always@(posedge reset or posedge CLK)
	 if(reset) deb_AA<=1'b1;
	 else deb_AA<=deb_A;
//coding for MNSTR pattern H-moving block
// 32x32 MNSTR
//  moving rightward:  
//     Rmvbody : Rmvjaw0  …act0 in a sequence of 5 flicks
//             : Rmvjaw1  …act1 in a sequence of 5 flicks
//             : Rmvjaw2  …act2 in a sequence of 5 flicks
//  moving leftward:  
//     Lmvbody : Lmvjaw0  …act0 in a sequence of 5 flicks
//             : Lmvjaw1  …act1 in a sequence of 5 flicks
//             : Lmvjaw2  …act2 in a sequence of 5 flicks
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Rmvbody<= 16'h000F;
	  5'h01:   Rmvbody<= 16'h007F;
	  5'h02:   Rmvbody<= 16'h00FF;
	  5'h03:   Rmvbody<= 16'h03FF;
	  5'h04:   Rmvbody<= 16'h07FF;
	  5'h05:   Rmvbody<= 16'h0FFF;
	  5'h06:   Rmvbody<= 16'h1FFF;
	  5'h07:   Rmvbody<= 16'h3FFF;
	  5'h08:   Rmvbody<= 16'h3FFF;
	  5'h09:   Rmvbody<= 16'h3FFF;
	  5'h0A:   Rmvbody<= 16'h7FFF;
	  5'h0B:   Rmvbody<= 16'h7FFF;
	  5'h0C:   Rmvbody<= 16'h7FFF;
	  5'h0D:   Rmvbody<= 16'hFFFF;
	  5'h0E:   Rmvbody<= 16'hFFFF;
	  5'h0F:   Rmvbody<= 16'hFFFF;
	  5'h1F:   Rmvbody<= 16'h000F;
	  5'h1E:   Rmvbody<= 16'h007F;
	  5'h1D:   Rmvbody<= 16'h00FF;
	  5'h1C:   Rmvbody<= 16'h03FF;
	  5'h1B:   Rmvbody<= 16'h07FF;
	  5'h1A:   Rmvbody<= 16'h0FFF;
	  5'h19:   Rmvbody<= 16'h1FFF;
	  5'h18:   Rmvbody<= 16'h3FFF;
	  5'h17:   Rmvbody<= 16'h3FFF;
	  5'h16:   Rmvbody<= 16'h3FFF;
	  5'h15:   Rmvbody<= 16'h7FFF;
	  5'h14:   Rmvbody<= 16'h7FFF;
	  5'h13:   Rmvbody<= 16'h7FFF;
	  5'h12:   Rmvbody<= 16'hFFFF;
	  5'h11:   Rmvbody<= 16'hFFFF;
	  5'h10:   Rmvbody<= 16'hFFFF;
	  default:  Rmvbody<= 16'h0000;
	  endcase

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Lmvbody<= 16'hF000;
	  5'h01:   Lmvbody<= 16'hFE00;
	  5'h02:   Lmvbody<= 16'hFF00;
	  5'h03:   Lmvbody<= 16'hFFC0;
	  5'h04:   Lmvbody<= 16'hFFE0;
	  5'h05:   Lmvbody<= 16'hFFF0;
	  5'h06:   Lmvbody<= 16'hFFF8;
	  5'h07:   Lmvbody<= 16'hFFFC;
	  5'h08:   Lmvbody<= 16'hFFFC;
	  5'h09:   Lmvbody<= 16'hFFFC;
	  5'h0A:   Lmvbody<= 16'hFFFE;
	  5'h0B:   Lmvbody<= 16'hFFFE;
	  5'h0C:   Lmvbody<= 16'hFFFE;
	  5'h0D:   Lmvbody<= 16'hFFFF;
	  5'h0E:   Lmvbody<= 16'hFFFF;
	  5'h0F:   Lmvbody<= 16'hFFFF;
	  5'h1F:   Lmvbody<= 16'hF000;
	  5'h1E:   Lmvbody<= 16'hFE00;
	  5'h1D:   Lmvbody<= 16'hFF00;
	  5'h1C:   Lmvbody<= 16'hFFC0;
	  5'h1B:   Lmvbody<= 16'hFFE0;
	  5'h1A:   Lmvbody<= 16'hFFF0;
	  5'h19:   Lmvbody<= 16'hFFF8;
	  5'h18:   Lmvbody<= 16'hFFFC;
	  5'h17:   Lmvbody<= 16'hFFFC;
	  5'h16:   Lmvbody<= 16'hFFFC;
	  5'h15:   Lmvbody<= 16'hFFFE;
	  5'h14:   Lmvbody<= 16'hFFFE;
	  5'h13:   Lmvbody<= 16'hFFFE;
	  5'h12:   Lmvbody<= 16'hFFFF;
	  5'h11:   Lmvbody<= 16'hFFFF;
	  5'h10:   Lmvbody<= 16'hFFFF;
	  default: Lmvbody<= 16'h0000;
	  endcase

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Rmvjaw0<= 16'hE000;
	  5'h01:   Rmvjaw0<= 16'hF800;
	  5'h02:   Rmvjaw0<= 16'hFE00;
	  5'h03:   Rmvjaw0<= 16'hFC00;
	  5'h04:   Rmvjaw0<= 16'hFFC0;
	  5'h05:   Rmvjaw0<= 16'hFFE0;
	  5'h06:   Rmvjaw0<= 16'hFFC0;
	  5'h07:   Rmvjaw0<= 16'hFF80;
	  5'h08:   Rmvjaw0<= 16'hFF00;
	  5'h09:   Rmvjaw0<= 16'hFE00;
	  5'h0A:   Rmvjaw0<= 16'hFC00;
	  5'h0B:   Rmvjaw0<= 16'hF800;
	  5'h0C:   Rmvjaw0<= 16'hF000;
	  5'h0D:   Rmvjaw0<= 16'hE000;
	  5'h0E:   Rmvjaw0<= 16'hC000;
	  5'h0F:   Rmvjaw0<= 16'h8000;
	  5'h1F:   Rmvjaw0<= 16'hE000;
	  5'h1E:   Rmvjaw0<= 16'hF800;
	  5'h1D:   Rmvjaw0<= 16'hFE00;
	  5'h1C:   Rmvjaw0<= 16'hFC00;
	  5'h1B:   Rmvjaw0<= 16'hFFC0;
	  5'h1A:   Rmvjaw0<= 16'hFFE0;
	  5'h19:   Rmvjaw0<= 16'hFFC0;
	  5'h18:   Rmvjaw0<= 16'hFF80;
	  5'h17:   Rmvjaw0<= 16'hFF00;
	  5'h16:   Rmvjaw0<= 16'hFE00;
	  5'h15:   Rmvjaw0<= 16'hFC00;
	  5'h14:   Rmvjaw0<= 16'hF800;
	  5'h13:   Rmvjaw0<= 16'hF000;
	  5'h12:   Rmvjaw0<= 16'hE000;
	  5'h11:   Rmvjaw0<= 16'hC000;
	  5'h10:   Rmvjaw0<= 16'h8000;
	  default: Rmvjaw0<= 16'h0000;
	  endcase
	  
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Rmvjaw1<= 16'hE000;
	  5'h01:   Rmvjaw1<= 16'hF800;
	  5'h02:   Rmvjaw1<= 16'hFE00;
	  5'h03:   Rmvjaw1<= 16'hFF00;
	  5'h04:   Rmvjaw1<= 16'hFF80;
	  5'h05:   Rmvjaw1<= 16'hFFC0;
	  5'h06:   Rmvjaw1<= 16'hFFE0;
	  5'h07:   Rmvjaw1<= 16'hFFF0;
	  5'h08:   Rmvjaw1<= 16'hFFF0;
	  5'h09:   Rmvjaw1<= 16'hFFF8;
	  5'h0A:   Rmvjaw1<= 16'hFFE0;
	  5'h0B:   Rmvjaw1<= 16'hFFC0;
	  5'h0C:   Rmvjaw1<= 16'hFF00;
	  5'h0D:   Rmvjaw1<= 16'hF800;
	  5'h0E:   Rmvjaw1<= 16'hE000;
	  5'h0F:   Rmvjaw1<= 16'hC000;
	  5'h1F:   Rmvjaw1<= 16'hE000;
	  5'h1E:   Rmvjaw1<= 16'hF800;
	  5'h1D:   Rmvjaw1<= 16'hFE00;
	  5'h1C:   Rmvjaw1<= 16'hFF00;
	  5'h1B:   Rmvjaw1<= 16'hFF80;
	  5'h1A:   Rmvjaw1<= 16'hFFC0;
	  5'h19:   Rmvjaw1<= 16'hFFE0;
	  5'h18:   Rmvjaw1<= 16'hFFF0;
	  5'h17:   Rmvjaw1<= 16'hFFF0;
	  5'h16:   Rmvjaw1<= 16'hFFF8;
	  5'h15:   Rmvjaw1<= 16'hFFE0;
	  5'h14:   Rmvjaw1<= 16'hFFC0;
	  5'h13:   Rmvjaw1<= 16'hFF00;
	  5'h12:   Rmvjaw1<= 16'hF800;
	  5'h11:   Rmvjaw1<= 16'hE000;
	  5'h10:   Rmvjaw1<= 16'hC000;
	  default: Rmvjaw1<= 16'h0000;
	  endcase
	 
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Rmvjaw2<= 16'hE000;
	  5'h01:   Rmvjaw2<= 16'hF800;
	  5'h02:   Rmvjaw2<= 16'hFE00;
	  5'h03:   Rmvjaw2<= 16'hFF00;
	  5'h04:   Rmvjaw2<= 16'hFF80;
	  5'h05:   Rmvjaw2<= 16'hFFC0;
	  5'h06:   Rmvjaw2<= 16'hFFE0;
	  5'h07:   Rmvjaw2<= 16'hFFF0;
	  5'h08:   Rmvjaw2<= 16'hFFF8;
	  5'h09:   Rmvjaw2<= 16'hFFFC;
	  5'h0A:   Rmvjaw2<= 16'hFFFE;
	  5'h0B:   Rmvjaw2<= 16'hFFFF;
	  5'h0C:   Rmvjaw2<= 16'hFFFF;
	  5'h0D:   Rmvjaw2<= 16'hFFFF;
	  5'h0E:   Rmvjaw2<= 16'hFFC0;
	  5'h0F:   Rmvjaw2<= 16'hD000;
	  5'h1F:   Rmvjaw2<= 16'hE000;
	  5'h1E:   Rmvjaw2<= 16'hF800;
	  5'h1D:   Rmvjaw2<= 16'hFE00;
	  5'h1C:   Rmvjaw2<= 16'hFF00;
	  5'h1B:   Rmvjaw2<= 16'hFF80;
	  5'h1A:   Rmvjaw2<= 16'hFFC0;
	  5'h19:   Rmvjaw2<= 16'hFFE0;
	  5'h18:   Rmvjaw2<= 16'hFFF0;
	  5'h17:   Rmvjaw2<= 16'hFFF8;
	  5'h16:   Rmvjaw2<= 16'hFFFC;
	  5'h15:   Rmvjaw2<= 16'hFFFE;
	  5'h14:   Rmvjaw2<= 16'hFFFF;
	  5'h13:   Rmvjaw2<= 16'hFFFF;
	  5'h12:   Rmvjaw2<= 16'hFFFF;
	  5'h11:   Rmvjaw2<= 16'hFFC0;
	  5'h10:   Rmvjaw2<= 16'hD000;
	  default: Rmvjaw2<= 16'h0000;
	  endcase

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Lmvjaw0<= 16'h0007;
	  5'h01:   Lmvjaw0<= 16'h001F;
	  5'h02:   Lmvjaw0<= 16'h007F;
	  5'h03:   Lmvjaw0<= 16'h00FF;
	  5'h04:   Lmvjaw0<= 16'h03FF;
	  5'h05:   Lmvjaw0<= 16'h07FF;
	  5'h06:   Lmvjaw0<= 16'h03FF;
	  5'h07:   Lmvjaw0<= 16'h01FF;
	  5'h08:   Lmvjaw0<= 16'h00FF;
	  5'h09:   Lmvjaw0<= 16'h007F;
	  5'h0A:   Lmvjaw0<= 16'h003F;
	  5'h0B:   Lmvjaw0<= 16'h001F;
	  5'h0C:   Lmvjaw0<= 16'h000F;
	  5'h0D:   Lmvjaw0<= 16'h0007;
	  5'h0E:   Lmvjaw0<= 16'h0003;
	  5'h0F:   Lmvjaw0<= 16'h0001;
	  5'h1F:   Lmvjaw0<= 16'h0007;
	  5'h1E:   Lmvjaw0<= 16'h001F;
	  5'h1D:   Lmvjaw0<= 16'h007F;
	  5'h1C:   Lmvjaw0<= 16'h00FF;
	  5'h1B:   Lmvjaw0<= 16'h03FF;
	  5'h1A:   Lmvjaw0<= 16'h07FF;
	  5'h19:   Lmvjaw0<= 16'h03FF;
	  5'h18:   Lmvjaw0<= 16'h01FF;
	  5'h17:   Lmvjaw0<= 16'h00FF;
	  5'h16:   Lmvjaw0<= 16'h007F;
	  5'h15:   Lmvjaw0<= 16'h003F;
	  5'h14:   Lmvjaw0<= 16'h001F;
	  5'h13:   Lmvjaw0<= 16'h000F;
	  5'h12:   Lmvjaw0<= 16'h0007;
	  5'h11:   Lmvjaw0<= 16'h0003;
	  5'h10:   Lmvjaw0<= 16'h0001;
	  default: Lmvjaw0<= 16'h0000;
	  endcase

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Lmvjaw1<= 16'h0007;
	  5'h01:   Lmvjaw1<= 16'h001F;
	  5'h02:   Lmvjaw1<= 16'h007F;
	  5'h03:   Lmvjaw1<= 16'h00FF;
	  5'h04:   Lmvjaw1<= 16'h01FF;
	  5'h05:   Lmvjaw1<= 16'h03FF;
	  5'h06:   Lmvjaw1<= 16'h07FF;
	  5'h07:   Lmvjaw1<= 16'h0FFF;
	  5'h08:   Lmvjaw1<= 16'h0FFF;
	  5'h09:   Lmvjaw1<= 16'h1FFF;
	  5'h0A:   Lmvjaw1<= 16'h07FF;
	  5'h0B:   Lmvjaw1<= 16'h03FF;
	  5'h0C:   Lmvjaw1<= 16'h00FF;
	  5'h0D:   Lmvjaw1<= 16'h001F;
	  5'h0E:   Lmvjaw1<= 16'h0007;
	  5'h0F:   Lmvjaw1<= 16'h0003;
	  5'h1F:   Lmvjaw1<= 16'h0007;
	  5'h1E:   Lmvjaw1<= 16'h001F;
	  5'h1D:   Lmvjaw1<= 16'h007F;
	  5'h1C:   Lmvjaw1<= 16'h00FF;
	  5'h1B:   Lmvjaw1<= 16'h01FF;
	  5'h1A:   Lmvjaw1<= 16'h03FF;
	  5'h19:   Lmvjaw1<= 16'h07FF;
	  5'h18:   Lmvjaw1<= 16'h0FFF;
	  5'h17:   Lmvjaw1<= 16'h0FFF;
	  5'h16:   Lmvjaw1<= 16'h1FFF;
	  5'h15:   Lmvjaw1<= 16'h07FF;
	  5'h14:   Lmvjaw1<= 16'h03FF;
	  5'h13:   Lmvjaw1<= 16'h00FF;
	  5'h12:   Lmvjaw1<= 16'h001F;
	  5'h11:   Lmvjaw1<= 16'h0007;
	  5'h10:   Lmvjaw1<= 16'h0003;  
	  default: Lmvjaw1<= 16'h0000;
	  endcase
	  
	  always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Lmvjaw2<= 16'h0007;
	  5'h01:   Lmvjaw2<= 16'h001F;
	  5'h02:   Lmvjaw2<= 16'h007F;
	  5'h03:   Lmvjaw2<= 16'h00FF;
	  5'h04:   Lmvjaw2<= 16'h01FF;
	  5'h05:   Lmvjaw2<= 16'h03FF;
	  5'h06:   Lmvjaw2<= 16'h07FF;
	  5'h07:   Lmvjaw2<= 16'h0FFF;
	  5'h08:   Lmvjaw2<= 16'h1FFF;
	  5'h09:   Lmvjaw2<= 16'h3FFF;
	  5'h0A:   Lmvjaw2<= 16'h7FFF;
	  5'h0B:   Lmvjaw2<= 16'hFFFF;
	  5'h0C:   Lmvjaw2<= 16'hFFFF;
	  5'h0D:   Lmvjaw2<= 16'hFFFF;
	  5'h0E:   Lmvjaw2<= 16'h03FF;
	  5'h0F:   Lmvjaw2<= 16'h0007;
	  5'h1F:   Lmvjaw2<= 16'h0007;
	  5'h1E:   Lmvjaw2<= 16'h001F;
	  5'h1D:   Lmvjaw2<= 16'h007F;
	  5'h1C:   Lmvjaw2<= 16'h00FF;
	  5'h1B:   Lmvjaw2<= 16'h01FF;
	  5'h1A:   Lmvjaw2<= 16'h03FF;
	  5'h19:   Lmvjaw2<= 16'h07FF;
	  5'h18:   Lmvjaw2<= 16'h0FFF;
	  5'h17:   Lmvjaw2<= 16'h1FFF;
	  5'h16:   Lmvjaw2<= 16'h3FFF;
	  5'h15:   Lmvjaw2<= 16'h7FFF;
	  5'h14:   Lmvjaw2<= 16'hFFFF;
	  5'h13:   Lmvjaw2<= 16'hFFFF;
	  5'h12:   Lmvjaw2<= 16'hFFFF;
	  5'h11:   Lmvjaw2<= 16'h03FF;
	  5'h10:   Lmvjaw2<= 16'h0007; 
	  default: Lmvjaw2<= 16'h0000;
	  endcase

//coding for MNSTR pattern V-moving block:
// 32x32 MNSTR
//  moving upward:  
//     Umvbdy00 : Umvbdy10  …act0 in a sequence of 5 flicks
//     Umvbdy01 : Umvbdy11  …act1 in a sequence of 5 flicks
//     Umvbdy02 : Umvbdy12  …act2 in a sequence of 5 flicks
//  moving downward:  
//     Dmvbdy00 : Dmvbdy10  …act0 in a sequence of 5 flicks
//     Dmvbdy01 : Dmvbdy11  …act1 in a sequence of 5 flicks
//     Dmvbdy02 : Dmvbdy12  …act2 in a sequence of 5 flicks
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Umvbdy00<= 16'h0000;    //00: up-left  act0
	  5'h01:   Umvbdy00<= 16'h0000;
	  5'h02:   Umvbdy00<= 16'h0000;
	  5'h03:   Umvbdy00<= 16'h0000;
	  5'h04:   Umvbdy00<= 16'h0000;
	  5'h05:   Umvbdy00<= 16'h0400;
	  5'h06:   Umvbdy00<= 16'h0E00;
	  5'h07:   Umvbdy00<= 16'h0F00;
	  5'h08:   Umvbdy00<= 16'h1F80;
	  5'h09:   Umvbdy00<= 16'h3FC0;
	  5'h0A:   Umvbdy00<= 16'h3FE0;
	  5'h0B:   Umvbdy00<= 16'h7FF0;
	  5'h0C:   Umvbdy00<= 16'h7FF8;
	  5'h0D:   Umvbdy00<= 16'hFFFC;
	  5'h0E:   Umvbdy00<= 16'hFFFE;
	  5'h0F:   Umvbdy00<= 16'hFFFF;
	  5'h10:   Umvbdy00<= 16'hFFFF;
	  5'h11:   Umvbdy00<= 16'hFFFF;
	  5'h12:   Umvbdy00<= 16'hFFFF;
	  5'h13:   Umvbdy00<= 16'hFFFF;
	  5'h14:   Umvbdy00<= 16'h7FFF;
	  5'h15:   Umvbdy00<= 16'h7FFF;
	  5'h16:   Umvbdy00<= 16'h7FFF;
	  5'h17:   Umvbdy00<= 16'h3FFF;
	  5'h18:   Umvbdy00<= 16'h1FFF;
	  5'h19:   Umvbdy00<= 16'h1FFF;
	  5'h1A:   Umvbdy00<= 16'h0FFF;
	  5'h1B:   Umvbdy00<= 16'h07FF;
	  5'h1C:   Umvbdy00<= 16'h03FF;
	  5'h1D:   Umvbdy00<= 16'h01FF;
	  5'h1E:   Umvbdy00<= 16'h003F;
	  5'h1F:   Umvbdy00<= 16'h0007;
	  default: Umvbdy00<= 16'h0000;
	  endcase
	  
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Umvbdy10<= 16'h0000;      //10:  up_right act0
	  5'h01:   Umvbdy10<= 16'h0000;
	  5'h02:   Umvbdy10<= 16'h0000;
	  5'h03:   Umvbdy10<= 16'h0000;
	  5'h04:   Umvbdy10<= 16'h0000;
	  5'h05:   Umvbdy10<= 16'h0020;
	  5'h06:   Umvbdy10<= 16'h0070;
	  5'h07:   Umvbdy10<= 16'h00F0;
	  5'h08:   Umvbdy10<= 16'h01F8;
	  5'h09:   Umvbdy10<= 16'h03FC;
	  5'h0A:   Umvbdy10<= 16'h07FE;
	  5'h0B:   Umvbdy10<= 16'h0FFE;
	  5'h0C:   Umvbdy10<= 16'h1FFE;
	  5'h0D:   Umvbdy10<= 16'h3FFE;
	  5'h0E:   Umvbdy10<= 16'h7FFE;
	  5'h0F:   Umvbdy10<= 16'hFFFF;
	  5'h10:   Umvbdy10<= 16'hFFFF;
	  5'h11:   Umvbdy10<= 16'hFFFF;
	  5'h12:   Umvbdy10<= 16'hFFFF;
	  5'h13:   Umvbdy10<= 16'hFFFF;
	  5'h14:   Umvbdy10<= 16'hFFFE;
	  5'h15:   Umvbdy10<= 16'hFFFE;
	  5'h16:   Umvbdy10<= 16'hFFFE;
	  5'h17:   Umvbdy10<= 16'hFFFC;
	  5'h18:   Umvbdy10<= 16'hFFF8;
	  5'h19:   Umvbdy10<= 16'hFFF8;
	  5'h1A:   Umvbdy10<= 16'hFFF0;
	  5'h1B:   Umvbdy10<= 16'hFFE0;
	  5'h1C:   Umvbdy10<= 16'hFFC0;
	  5'h1D:   Umvbdy10<= 16'hFF80;
	  5'h1E:   Umvbdy10<= 16'hFC00;
	  5'h1F:   Umvbdy10<= 16'hE000;
	  default: Umvbdy10<= 16'h0000;
	  endcase

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Umvbdy01<= 16'h0000;    //01: up-left act1
	  5'h01:   Umvbdy01<= 16'h0000;
	  5'h02:   Umvbdy01<= 16'h0000;
	  5'h03:   Umvbdy01<= 16'h0040;
	  5'h04:   Umvbdy01<= 16'h01C0;
	  5'h05:   Umvbdy01<= 16'h03E0;
	  5'h06:   Umvbdy01<= 16'h07F0;
	  5'h07:   Umvbdy01<= 16'h0FF0;
	  5'h08:   Umvbdy01<= 16'h1FF8;
	  5'h09:   Umvbdy01<= 16'h3FF8;
	  5'h0A:   Umvbdy01<= 16'h3FF8;
	  5'h0B:   Umvbdy01<= 16'h7FFC;
	  5'h0C:   Umvbdy01<= 16'h7FFC;
	  5'h0D:   Umvbdy01<= 16'hFFFE;
	  5'h0E:   Umvbdy01<= 16'hFFFF;
	  5'h0F:   Umvbdy01<= 16'hFFFF;
	  5'h10:   Umvbdy01<= 16'hFFFF;
	  5'h11:   Umvbdy01<= 16'hFFFF;
	  5'h12:   Umvbdy01<= 16'hFFFF;
	  5'h13:   Umvbdy01<= 16'hFFFF;
	  5'h14:   Umvbdy01<= 16'h7FFF;
	  5'h15:   Umvbdy01<= 16'h7FFF;
	  5'h16:   Umvbdy01<= 16'h7FFF;
	  5'h17:   Umvbdy01<= 16'h3FFF;
	  5'h18:   Umvbdy01<= 16'h1FFF;
	  5'h19:   Umvbdy01<= 16'h1FFF;
	  5'h1A:   Umvbdy01<= 16'h0FFF;
	  5'h1B:   Umvbdy01<= 16'h07FF;
	  5'h1C:   Umvbdy01<= 16'h03FF;
	  5'h1D:   Umvbdy01<= 16'h01FF;
	  5'h1E:   Umvbdy01<= 16'h003F;
	  5'h1F:   Umvbdy01<= 16'h0007;
	  default: Umvbdy01<= 16'h0000;
	  endcase
	  
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Umvbdy11<= 16'h0000;      //11:  up_right act1
	  5'h01:   Umvbdy11<= 16'h0000;
	  5'h02:   Umvbdy11<= 16'h0000;
	  5'h03:   Umvbdy11<= 16'h0200;
	  5'h04:   Umvbdy11<= 16'h0380;
	  5'h05:   Umvbdy11<= 16'h07C0;
	  5'h06:   Umvbdy11<= 16'h0FE0;
	  5'h07:   Umvbdy11<= 16'h0FF0;
	  5'h08:   Umvbdy11<= 16'h1FF8;
	  5'h09:   Umvbdy11<= 16'h1FFC;
	  5'h0A:   Umvbdy11<= 16'h1FFC;
	  5'h0B:   Umvbdy11<= 16'h3FFE;
	  5'h0C:   Umvbdy11<= 16'h3FFE;
	  5'h0D:   Umvbdy11<= 16'h7FFF;
	  5'h0E:   Umvbdy11<= 16'hFFFF;
	  5'h0F:   Umvbdy11<= 16'hFFFF;
	  5'h10:   Umvbdy11<= 16'hFFFF;
	  5'h11:   Umvbdy11<= 16'hFFFF;
	  5'h12:   Umvbdy11<= 16'hFFFF;
	  5'h13:   Umvbdy11<= 16'hFFFF;
	  5'h14:   Umvbdy11<= 16'hFFFE;
	  5'h15:   Umvbdy11<= 16'hFFFE;
	  5'h16:   Umvbdy11<= 16'hFFFE;
	  5'h17:   Umvbdy11<= 16'hFFFC;
	  5'h18:   Umvbdy11<= 16'hFFF8;
	  5'h19:   Umvbdy11<= 16'hFFF8;
	  5'h1A:   Umvbdy11<= 16'hFFF0;
	  5'h1B:   Umvbdy11<= 16'hFFE0;
	  5'h1C:   Umvbdy11<= 16'hFFC0;
	  5'h1D:   Umvbdy11<= 16'hFF80;
	  5'h1E:   Umvbdy11<= 16'hFC00;
	  5'h1F:   Umvbdy11<= 16'hE000;
	  default: Umvbdy11<= 16'h0000;
	  endcase

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Umvbdy02<= 16'h001C;    //02: up-left act2
	  5'h01:   Umvbdy02<= 16'h003C;
	  5'h02:   Umvbdy02<= 16'h007C;
	  5'h03:   Umvbdy02<= 16'h00FC;
	  5'h04:   Umvbdy02<= 16'h01FC;
	  5'h05:   Umvbdy02<= 16'h03FC;
	  5'h06:   Umvbdy02<= 16'h07FE;
	  5'h07:   Umvbdy02<= 16'h0FFE;
	  5'h08:   Umvbdy02<= 16'h1FFE;
	  5'h09:   Umvbdy02<= 16'h3FFE;
	  5'h0A:   Umvbdy02<= 16'h3FFE;
	  5'h0B:   Umvbdy02<= 16'h7FFE;
	  5'h0C:   Umvbdy02<= 16'h7FFE;
	  5'h0D:   Umvbdy02<= 16'hFFFF;
	  5'h0E:   Umvbdy02<= 16'hFFFF;
	  5'h0F:   Umvbdy02<= 16'hFFFF;
	  5'h10:   Umvbdy02<= 16'hFFFF;
	  5'h11:   Umvbdy02<= 16'hFFFF;
	  5'h12:   Umvbdy02<= 16'hFFFF;
	  5'h13:   Umvbdy02<= 16'hFFFF;
	  5'h14:   Umvbdy02<= 16'h7FFF;
	  5'h15:   Umvbdy02<= 16'h7FFF;
	  5'h16:   Umvbdy02<= 16'h7FFF;
	  5'h17:   Umvbdy02<= 16'h3FFF;
	  5'h18:   Umvbdy02<= 16'h1FFF;
	  5'h19:   Umvbdy02<= 16'h1FFF;
	  5'h1A:   Umvbdy02<= 16'h0FFF;
	  5'h1B:   Umvbdy02<= 16'h07FF;
	  5'h1C:   Umvbdy02<= 16'h03FF;
	  5'h1D:   Umvbdy02<= 16'h01FF;
	  5'h1E:   Umvbdy02<= 16'h003F;
	  5'h1F:   Umvbdy02<= 16'h0007;
	  default: Umvbdy02<= 16'h0000;
	  endcase
	  
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h00:   Umvbdy12<= 16'h7000;      //12:  up_right act2
	  5'h01:   Umvbdy12<= 16'h7C00;
	  5'h02:   Umvbdy12<= 16'h7E00;
	  5'h03:   Umvbdy12<= 16'h7F00;
	  5'h04:   Umvbdy12<= 16'h7F80;
	  5'h05:   Umvbdy12<= 16'h7FC0;
	  5'h06:   Umvbdy12<= 16'hFFE0;
	  5'h07:   Umvbdy12<= 16'hFFF0;
	  5'h08:   Umvbdy12<= 16'hFFF8;
	  5'h09:   Umvbdy12<= 16'hFFFC;
	  5'h0A:   Umvbdy12<= 16'hFFFC;
	  5'h0B:   Umvbdy12<= 16'hFFFE;
	  5'h0C:   Umvbdy12<= 16'hFFFE;
	  5'h0D:   Umvbdy12<= 16'h7FFF;
	  5'h0E:   Umvbdy12<= 16'hFFFF;
	  5'h0F:   Umvbdy12<= 16'hFFFF;
	  5'h10:   Umvbdy12<= 16'hFFFF;
	  5'h11:   Umvbdy12<= 16'hFFFF;
	  5'h12:   Umvbdy12<= 16'hFFFF;
	  5'h13:   Umvbdy12<= 16'hFFFF;
	  5'h14:   Umvbdy12<= 16'hFFFE;
	  5'h15:   Umvbdy12<= 16'hFFFE;
	  5'h16:   Umvbdy12<= 16'hFFFE;
	  5'h17:   Umvbdy12<= 16'hFFFC;
	  5'h18:   Umvbdy12<= 16'hFFF8;
	  5'h19:   Umvbdy12<= 16'hFFF8;
	  5'h1A:   Umvbdy12<= 16'hFFF0;
	  5'h1B:   Umvbdy12<= 16'hFFE0;
	  5'h1C:   Umvbdy12<= 16'hFFC0;
	  5'h1D:   Umvbdy12<= 16'hFF80;
	  5'h1E:   Umvbdy12<= 16'hFC00;
	  5'h1F:   Umvbdy12<= 16'hE000;
	  default: Umvbdy12<= 16'h0000;
	  endcase

	// = = = = = = = = = = =

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h1F:   Dmvbdy00<= 16'h0000;    //00: down-left  act0
	  5'h1E:   Dmvbdy00<= 16'h0000;
	  5'h1D:   Dmvbdy00<= 16'h0000;
	  5'h1C:   Dmvbdy00<= 16'h0000;
	  5'h1B:   Dmvbdy00<= 16'h0000;
	  5'h1A:   Dmvbdy00<= 16'h0400;
	  5'h19:   Dmvbdy00<= 16'h0E00;
	  5'h18:   Dmvbdy00<= 16'h0F00;
	  5'h17:   Dmvbdy00<= 16'h1F80;
	  5'h16:   Dmvbdy00<= 16'h3FC0;
	  5'h15:   Dmvbdy00<= 16'h3FE0;
	  5'h14:   Dmvbdy00<= 16'h7FF0;
	  5'h13:   Dmvbdy00<= 16'h7FF8;
	  5'h12:   Dmvbdy00<= 16'hFFFC;
	  5'h11:   Dmvbdy00<= 16'hFFFE;
	  5'h10:   Dmvbdy00<= 16'hFFFF;
	  5'h0F:   Dmvbdy00<= 16'hFFFF;
	  5'h0E:   Dmvbdy00<= 16'hFFFF;
	  5'h0D:   Dmvbdy00<= 16'hFFFF;
	  5'h0C:   Dmvbdy00<= 16'hFFFF;
	  5'h0B:   Dmvbdy00<= 16'h7FFF;
	  5'h0A:   Dmvbdy00<= 16'h7FFF;
	  5'h09:   Dmvbdy00<= 16'h7FFF;
	  5'h08:   Dmvbdy00<= 16'h3FFF;
	  5'h07:   Dmvbdy00<= 16'h1FFF;
	  5'h06:   Dmvbdy00<= 16'h1FFF;
	  5'h05:   Dmvbdy00<= 16'h0FFF;
	  5'h04:   Dmvbdy00<= 16'h07FF;
	  5'h03:   Dmvbdy00<= 16'h03FF;
	  5'h02:   Dmvbdy00<= 16'h01FF;
	  5'h01:   Dmvbdy00<= 16'h003F;
	  5'h00:   Dmvbdy00<= 16'h0007;
	  default: Dmvbdy00<= 16'h0000;
	  endcase
	  
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h1F:   Dmvbdy10<= 16'h0000;      //10:  down_right act0
	  5'h1E:   Dmvbdy10<= 16'h0000;
	  5'h1D:   Dmvbdy10<= 16'h0000;
	  5'h1C:   Dmvbdy10<= 16'h0000;
	  5'h1B:   Dmvbdy10<= 16'h0000;
	  5'h1A:   Dmvbdy10<= 16'h0020;
	  5'h19:   Dmvbdy10<= 16'h0070;
	  5'h18:   Dmvbdy10<= 16'h00F0;
	  5'h17:   Dmvbdy10<= 16'h01F8;
	  5'h16:   Dmvbdy10<= 16'h03FC;
	  5'h15:   Dmvbdy10<= 16'h07FE;
	  5'h14:   Dmvbdy10<= 16'h0FFE;
	  5'h13:   Dmvbdy10<= 16'h1FFE;
	  5'h12:   Dmvbdy10<= 16'h3FFE;
	  5'h11:   Dmvbdy10<= 16'h7FFE;
	  5'h10:   Dmvbdy10<= 16'hFFFF;
	  5'h0F:   Dmvbdy10<= 16'hFFFF;
	  5'h0E:   Dmvbdy10<= 16'hFFFF;
	  5'h0D:   Dmvbdy10<= 16'hFFFF;
	  5'h0C:   Dmvbdy10<= 16'hFFFF;
	  5'h0B:   Dmvbdy10<= 16'hFFFE;
	  5'h0A:   Dmvbdy10<= 16'hFFFE;
	  5'h09:   Dmvbdy10<= 16'hFFFE;
	  5'h08:   Dmvbdy10<= 16'hFFFC;
	  5'h07:   Dmvbdy10<= 16'hFFF8;
	  5'h06:   Dmvbdy10<= 16'hFFF8;
	  5'h05:   Dmvbdy10<= 16'hFFF0;
	  5'h04:   Dmvbdy10<= 16'hFFE0;
	  5'h03:   Dmvbdy10<= 16'hFFC0;
	  5'h02:   Dmvbdy10<= 16'hFF80;
	  5'h01:   Dmvbdy10<= 16'hFC00;
	  5'h00:   Dmvbdy10<= 16'hE000;
	  default: Dmvbdy10<= 16'h0000;
	  endcase

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h1F:   Dmvbdy01<= 16'h0000;    //01: down-left act1
	  5'h1E:   Dmvbdy01<= 16'h0000;
	  5'h1D:   Dmvbdy01<= 16'h0000;
	  5'h1C:   Dmvbdy01<= 16'h0040;
	  5'h1B:   Dmvbdy01<= 16'h01C0;
	  5'h1A:   Dmvbdy01<= 16'h03E0;
	  5'h19:   Dmvbdy01<= 16'h07F0;
	  5'h18:   Dmvbdy01<= 16'h0FF0;
	  5'h17:   Dmvbdy01<= 16'h1FF8;
	  5'h16:   Dmvbdy01<= 16'h3FF8;
	  5'h15:   Dmvbdy01<= 16'h3FF8;
	  5'h14:   Dmvbdy01<= 16'h7FFC;
	  5'h13:   Dmvbdy01<= 16'h7FFC;
	  5'h12:   Dmvbdy01<= 16'hFFFE;
	  5'h11:   Dmvbdy01<= 16'hFFFF;
	  5'h10:   Dmvbdy01<= 16'hFFFF;
	  5'h0F:   Dmvbdy01<= 16'hFFFF;
	  5'h0E:   Dmvbdy01<= 16'hFFFF;
	  5'h0D:   Dmvbdy01<= 16'hFFFF;
	  5'h0C:   Dmvbdy01<= 16'hFFFF;
	  5'h0B:   Dmvbdy01<= 16'h7FFF;
	  5'h0A:   Dmvbdy01<= 16'h7FFF;
	  5'h09:   Dmvbdy01<= 16'h7FFF;
	  5'h08:   Dmvbdy01<= 16'h3FFF;
	  5'h07:   Dmvbdy01<= 16'h1FFF;
	  5'h06:   Dmvbdy01<= 16'h1FFF;
	  5'h05:   Dmvbdy01<= 16'h0FFF;
	  5'h04:   Dmvbdy01<= 16'h07FF;
	  5'h03:   Dmvbdy01<= 16'h03FF;
	  5'h02:   Dmvbdy01<= 16'h01FF;
	  5'h01:   Dmvbdy01<= 16'h003F;
	  5'h00:   Dmvbdy01<= 16'h0007;
	  default: Dmvbdy01<= 16'h0000;
	  endcase
	  
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h1F:   Dmvbdy11<= 16'h0000;      //11:  down_right act1
	  5'h1E:   Dmvbdy11<= 16'h0000;
	  5'h1D:   Dmvbdy11<= 16'h0000;
	  5'h1C:   Dmvbdy11<= 16'h0200;
	  5'h1B:   Dmvbdy11<= 16'h0380;
	  5'h1A:   Dmvbdy11<= 16'h07C0;
	  5'h19:   Dmvbdy11<= 16'h0FE0;
	  5'h18:   Dmvbdy11<= 16'h0FF0;
	  5'h17:   Dmvbdy11<= 16'h1FF8;
	  5'h16:   Dmvbdy11<= 16'h1FFC;
	  5'h15:   Dmvbdy11<= 16'h1FFC;
	  5'h14:   Dmvbdy11<= 16'h3FFE;
	  5'h13:   Dmvbdy11<= 16'h3FFE;
	  5'h12:   Dmvbdy11<= 16'h7FFF;
	  5'h11:   Dmvbdy11<= 16'hFFFF;
	  5'h10:   Dmvbdy11<= 16'hFFFF;
	  5'h0F:   Dmvbdy11<= 16'hFFFF;
	  5'h0E:   Dmvbdy11<= 16'hFFFF;
	  5'h0D:   Dmvbdy11<= 16'hFFFF;
	  5'h0C:   Dmvbdy11<= 16'hFFFF;
	  5'h0B:   Dmvbdy11<= 16'hFFFE;
	  5'h0A:   Dmvbdy11<= 16'hFFFE;
	  5'h09:   Dmvbdy11<= 16'hFFFE;
	  5'h08:   Dmvbdy11<= 16'hFFFC;
	  5'h07:   Dmvbdy11<= 16'hFFF8;
	  5'h06:   Dmvbdy11<= 16'hFFF8;
	  5'h05:   Dmvbdy11<= 16'hFFF0;
	  5'h04:   Dmvbdy11<= 16'hFFE0;
	  5'h03:   Dmvbdy11<= 16'hFFC0;
	  5'h02:   Dmvbdy11<= 16'hFF80;
	  5'h01:   Dmvbdy11<= 16'hFC00;
	  5'h00:   Dmvbdy11<= 16'hE000;
	  default: Dmvbdy11<= 16'h0000;
	  endcase

	always@(*)
	  case(MNSTR_y[4:0])
	  5'h1F:   Dmvbdy02<= 16'h001C;    //02: down-left act2
	  5'h1E:   Dmvbdy02<= 16'h003C;
	  5'h1D:   Dmvbdy02<= 16'h007C;
	  5'h1C:   Dmvbdy02<= 16'h00FC;
	  5'h1B:   Dmvbdy02<= 16'h01FC;
	  5'h1A:   Dmvbdy02<= 16'h03FC;
	  5'h19:   Dmvbdy02<= 16'h07FE;
	  5'h18:   Dmvbdy02<= 16'h0FFE;
	  5'h17:   Dmvbdy02<= 16'h1FFE;
	  5'h16:   Dmvbdy02<= 16'h3FFE;
	  5'h15:   Dmvbdy02<= 16'h3FFE;
	  5'h14:   Dmvbdy02<= 16'h7FFE;
	  5'h13:   Dmvbdy02<= 16'h7FFE;
	  5'h12:   Dmvbdy02<= 16'hFFFF;
	  5'h11:   Dmvbdy02<= 16'hFFFF;
	  5'h10:   Dmvbdy02<= 16'hFFFF;
	  5'h0F:   Dmvbdy02<= 16'hFFFF;
	  5'h0E:   Dmvbdy02<= 16'hFFFF;
	  5'h0D:   Dmvbdy02<= 16'hFFFF;
	  5'h0C:   Dmvbdy02<= 16'hFFFF;
	  5'h0B:   Dmvbdy02<= 16'h7FFF;
	  5'h0A:   Dmvbdy02<= 16'h7FFF;
	  5'h09:   Dmvbdy02<= 16'h7FFF;
	  5'h08:   Dmvbdy02<= 16'h3FFF;
	  5'h07:   Dmvbdy02<= 16'h1FFF;
	  5'h06:   Dmvbdy02<= 16'h1FFF;
	  5'h05:   Dmvbdy02<= 16'h0FFF;
	  5'h04:   Dmvbdy02<= 16'h07FF;
	  5'h03:   Dmvbdy02<= 16'h03FF;
	  5'h02:   Dmvbdy02<= 16'h01FF;
	  5'h01:   Dmvbdy02<= 16'h003F;
	  5'h00:   Dmvbdy02<= 16'h0007;
	  default: Dmvbdy02<= 16'h0000;
	  endcase
	  
	always@(*)
	  case(MNSTR_y[4:0])
	  5'h1F:   Dmvbdy12<= 16'h7000;      //12:  down_right act2
	  5'h1E:   Dmvbdy12<= 16'h7C00;
	  5'h1D:   Dmvbdy12<= 16'h7E00;
	  5'h1C:   Dmvbdy12<= 16'h7F00;
	  5'h1B:   Dmvbdy12<= 16'h7F80;
	  5'h1A:   Dmvbdy12<= 16'h7FC0;
	  5'h19:   Dmvbdy12<= 16'hFFE0;
	  5'h18:   Dmvbdy12<= 16'hFFF0;
	  5'h17:   Dmvbdy12<= 16'hFFF8;
	  5'h16:   Dmvbdy12<= 16'hFFFC;
	  5'h15:   Dmvbdy12<= 16'hFFFC;
	  5'h14:   Dmvbdy12<= 16'hFFFE;
	  5'h13:   Dmvbdy12<= 16'hFFFE;
	  5'h12:   Dmvbdy12<= 16'h7FFF;
	  5'h11:   Dmvbdy12<= 16'hFFFF;
	  5'h10:   Dmvbdy12<= 16'hFFFF;
	  5'h0F:   Dmvbdy12<= 16'hFFFF;
	  5'h0E:   Dmvbdy12<= 16'hFFFF;
	  5'h0D:   Dmvbdy12<= 16'hFFFF;
	  5'h0C:   Dmvbdy12<= 16'hFFFF;
	  5'h0B:   Dmvbdy12<= 16'hFFFE;
	  5'h0A:   Dmvbdy12<= 16'hFFFE;
	  5'h09:   Dmvbdy12<= 16'hFFFE;
	  5'h08:   Dmvbdy12<= 16'hFFFC;
	  5'h07:   Dmvbdy12<= 16'hFFF8;
	  5'h06:   Dmvbdy12<= 16'hFFF0;
	  5'h04:   Dmvbdy12<= 16'hFFE0;
	  5'h03:   Dmvbdy12<= 16'hFFC0;
	  5'h02:   Dmvbdy12<= 16'hFF80;
	  5'h01:   Dmvbdy12<= 16'hFC00;
	  5'h00:   Dmvbdy12<= 16'hE000; 
	  default: Dmvbdy12<= 16'h0000;
	  endcase

//coding for MNSTR display block
// region of MNSTR in 800x600 visible zone
	assign MNSTR_on=(X_pix>=body_x && X_pix<body_x+11'd0032 &&Y_pix>=body_y && Y_pix<body_y+11'd0032)?   1:0;

	// active row of the MNSTR pattern (1x32 in 32x32) associated with
	// the active H-scan line
	assign  MNSTR_y=(Y_pix>=body_y&&Y_pix<=body_y+11'd0031 )? Y_pix-body_y : 11'd0000;	
	always@(posedge reset or posedge CLK)
	 if(reset)     MNSTR_row<= 32'h000FE000;
	 else if(X_pix+11'h001==body_x)
	  case({mvdir_indx, act_cnt})
	  5'b11000:   MNSTR_row<= {Rmvbody, Rmvjaw0};   //mv-right
	  5'b11001:   MNSTR_row<= {Rmvbody, Rmvjaw1};
	  5'b11010:   MNSTR_row<= {Rmvbody, Rmvjaw1};
	  5'b11011:   MNSTR_row<= {Rmvbody, Rmvjaw2};
	  5'b11100:   MNSTR_row<= {Rmvbody, Rmvjaw2};
	  5'b10000:   MNSTR_row<= {Lmvjaw0, Lmvbody};    //mv-left
	  5'b10001:   MNSTR_row<= {Lmvjaw1, Lmvbody};
	  5'b10010:   MNSTR_row<= {Lmvjaw1, Lmvbody};
	  5'b10011:   MNSTR_row<= {Lmvjaw2, Lmvbody};
	  5'b10100:   MNSTR_row<= {Lmvjaw2, Lmvbody};
	  5'b01000:  MNSTR_row<= {Dmvbdy00, Dmvbdy10};  //mv-dwn
	  5'b01001:  MNSTR_row<= {Dmvbdy01, Dmvbdy11};
	  5'b01010:  MNSTR_row<= {Dmvbdy01, Dmvbdy11};
	  5'b01011:  MNSTR_row<= {Dmvbdy02, Dmvbdy12};
	  5'b01100:  MNSTR_row<= {Dmvbdy02, Dmvbdy12};
	  5'b00000:  MNSTR_row<= {Umvbdy00, Umvbdy10};  //mv-up
	  5'b00001:  MNSTR_row<= {Umvbdy01, Umvbdy11};
	  5'b00010:  MNSTR_row<= {Umvbdy01, Umvbdy11};
	  5'b00011:  MNSTR_row<= {Umvbdy02, Umvbdy12};
	  5'b00100:  MNSTR_row<= {Umvbdy02, Umvbdy12};
	  default:   MNSTR_row<= 32'h00000000;     
	  endcase
	 else if(MNSTR_on) MNSTR_row<= {MNSTR_row[30:0], MNSTR_row[31]};
	 else     MNSTR_row<= 32'h00000000;     //=MNSTR_row;???

//coding for MNSTR RGB control block
	assign   R_mnstr=(MNSTR_on && MNSTR_row[31] && SW[0])? 1:0;
	assign   G_mnstr=(MNSTR_on && MNSTR_row[31] && SW[1])? 1:0;
	assign   B_mnstr=(MNSTR_on && MNSTR_row[31] && SW[2])? 1:0;

	always@(posedge reset or posedge CLK)
	 if(reset) 
		begin GG<= 1'b0;
				BB<= 1'b0;
				RR<= 1'b0;
		end
	 else if(MNSTR_on)
		begin RR<= R_mnstr;
			 GG<= G_mnstr;
			  BB<= B_mnstr;
	end
	 else begin RR<= 1'b0;
				GG<= 1'b0;
				 BB<= 1'b0;
		 end
	assign   R=RR, G= GG, B= BB;

//coding for internal status probing block
	assign   LED[7:0]= {gostop, 1'b0, mvdir_indx,1'b0,rot_indx[2:0]};


endmodule
/*
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:39:20 01/08/2015 
// Design Name: 
// Module Name:    fpga4 
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
module fpga4(SW, rot_A, rot_B, rot_dwn, BTN0, BTN1, BTN2, reset, clk, LED, R, G, B, h_sync, v_sync
    );
input [3:0] SW;
input rot_A, rot_B, rot_dwn, BTN0, BTN1, BTN2, reset, clk;
output [7:0] LED;
output R, G, B, h_sync, v_sync;

wire [10:0] X_pix, Y_pix;			//跑座標
reg [10:0] H_scan, V_scan;
wire H_on, V_on;

reg RR, GG, BB;		

reg [19:0] debcnt0, debcnt1, debcnt2;			//抓BTN0~2

wire mvclk;			//move clock
reg [19:0] slow_clk;
reg [2:0] act_cnt;			//決定圖形
reg [1:0] mvdir_indx;			//決定方向
reg [10:0] body_x, body_y;			//圖形左上點

reg [19:0] debcnt;			//抓rot_dwn
reg gostop,gostop2;			//決定動靜
wire gostop1, gostop3;

wire [10:0] delta_x, delta_y;			//決定單位變化量(速度)
reg dett_A, dett_B, deb_A, deb_B, deb_AA;			//抓轉扭
reg [3:0] rot_indx;			//操控delta_a,delta_b

reg [31:0] MNSTR_row;			//整排亮燈情況
wire [10:0] MNSTR_y;			//跟Y座標的距離，用來區分每一整排
wire MNSTR_on;				//body_x,body_y往右下拉32*32的範圍
wire R_mnstr, G_mnstr, B_mnstr;

reg [15:0] Rmvbody, Rmvjaw0, Rmvjaw1, Rmvjaw2,
			  Lmvbody, Lmvjaw0, Lmvjaw1, Lmvjaw2,
			  Umvbdy00, Umvbdy10, Umvbdy01, Umvbdy11, Umvbdy02, Umvbdy12,
			  Dmvbdy00, Dmvbdy10, Dmvbdy01, Dmvbdy11, Dmvbdy02, Dmvbdy12;

////////coding for VGA H_sync/V_sync and display coordinates////////
// block for H_scan: 1-1040 
always@(posedge reset or posedge clk)
	if(reset)                 								H_scan <= 11'h000;
	else if(H_scan==11'd1040)  							H_scan <= 11'h001;
	else                    								H_scan <= H_scan+11'h001; 
// block for V_scan: 1-666 
always@(posedge reset or posedge clk)
	if(reset)                 								V_scan <= 11'h000;
	else if(V_scan==11'd666 && H_scan == 11'd1040 ) V_scan <= 11'h001;
	else if(H_scan==11'd1040)  							V_scan <= V_scan+11'h001; 
	else                     								V_scan <= V_scan;

// block for H_on and V_on
assign  H_on = (H_scan>=11'd0105 && H_scan<=11'd0904);
assign  V_on = (V_scan>=11'd0024 && V_scan<=11'd0623);

// block for h_sync and v_sync
assign  h_sync = ~(H_scan>= 11'd0921 && H_scan<= 11'd1040);
assign  v_sync = ~(V_scan>= 11'd0661 && V_scan<= 11'd0666);

// block for X_pix and Y_pix
assign  X_pix = (H_scan>11'd0104 && H_scan<11'd0905)? H_scan - 11'd0104 : 11'd0000;
assign  Y_pix = (V_scan>11'd0023 && V_scan<11'd0624)? V_scan - 11'd0023 : 11'd0000;

////////coding for RGB control block////////
assign  R = RR;
assign  G = GG;            			  
assign  B = BB;

////////coding for BTN0/1/2 debouncing block////////

always@(posedge reset or posedge clk)
	if(reset)      								debcnt0 <= 20'h00000; 
	else if(BTN0 && debcnt0<20'hFFFFE)   	debcnt0 <= debcnt0+20'h00001;
	else if(~BTN0 && debcnt0==20'hffffe) 	debcnt0 <= 20'h00000;
	else if(~BTN0 && debcnt0!=20'h00000) 	debcnt0 <= debcnt0;
	else          									debcnt0 <= debcnt0;

always@(posedge reset or posedge clk)
	if(reset)      								debcnt1 <= 20'h00000; 
	else if(BTN1 && debcnt1<20'hFFFFE)   	debcnt1 <= debcnt1+20'h00001;
	else if(~BTN1 && debcnt1==20'hffffe) 	debcnt1 <= 20'h00000;
	else if(~BTN1 && debcnt1!=20'h00000) 	debcnt1 <= debcnt1;
	else        									debcnt1 <= debcnt1;

always@(posedge reset or posedge clk)
	if(reset)     									debcnt2 <= 20'h00000; 
	else if(BTN2 && debcnt2<20'hFFFFE)  	debcnt2 <= debcnt2+20'h00001;
	else if(~BTN2 && debcnt2==20'hffffe) 	debcnt2 <= 20'h00000;
	else if(~BTN2 && debcnt2!=20'h00000) 	debcnt2 <= debcnt2;
	else        									debcnt2 <= debcnt2;

////////coding for block for MONSTER movement triggering block////////

always@(posedge reset or posedge clk)
	if(reset)      						slow_clk <= 20'h00000;
	else if(slow_clk==20'hFFFFE)		slow_clk <= 20'h00000;
	else         							slow_clk <= slow_clk+20'h00001;

assign  				mvclk = (slow_clk==20'hFFFFE)? 1:0;

// block for act_cnt control: 0-1-2
always@(posedge reset or negedge clk)  
	if(reset)              			act_cnt <= 3'b000;
	else if(~mvclk)         		act_cnt <= act_cnt; 
	else if(act_cnt==3'b100)  		act_cnt <= 3'b000;
	else 				   				act_cnt <= act_cnt+3'b001;

// block for MONSTER moving "direction" control
// mvdir_indx:         10: leftward   11: rightward
//                   00: upward    01: downward
always@(posedge reset or negedge clk)        
	if(reset)                   		mvdir_indx <= 2'b11; 
	else if(debcnt0==20'h2FFFE)  		mvdir_indx <= {mvdir_indx[1], ~mvdir_indx[0]};
	else if(debcnt1==20'h2FFFE)  		mvdir_indx <= ~mvdir_indx;
	else if(debcnt2==20'h2FFFE)  		mvdir_indx <= {~mvdir_indx[1], mvdir_indx[0]};
	else                      			mvdir_indx <= mvdir_indx;
// block for MONSTER moving "location" control
always@(posedge reset or posedge clk)
	if(reset)       	{body_x, body_y} <= {11'd0400, 11'd0300};
	else if(~gostop) 	{body_x, body_y} <= {body_x, body_y};
	else if(mvclk)
      // begin 
		if(mvdir_indx==2'b11)           // moving right 
			body_x <= (body_x+11'd0032+delta_x<11'd0800)? 	body_x+delta_x :  body_x;
		else if(mvdir_indx==2'b10)      // moving left
			body_x <= (body_x>delta_x)?                     body_x-delta_x :  body_x;
		else if(mvdir_indx==2'b00)      // moving up
			body_y <= (body_y>delta_y)?                     body_y-delta_y :  body_y;
		else if(mvdir_indx==2'b01)      // moving down
			body_y <= (body_y+11'd32+delta_y<11'd0600)?     body_y+delta_y :  body_y;
	else {body_x, body_y} <= {body_x, body_y};
 
////////coding for 'start-stop" block////////

always@(posedge reset or posedge clk)
	if(reset)            							debcnt <= 20'h00000; 
	else if(rot_dwn && debcnt<20'hFFFFE)    	debcnt <= debcnt+20'h00001;
	else if(~rot_dwn && debcnt==20'hffffe)  	debcnt <= 20'h00000;
	else if(~rot_dwn && debcnt!=20'h00000)  	debcnt <= debcnt;
	else             						 			debcnt <= debcnt;
assign gostop1 = (debcnt==20'hFFFFE || debcnt==20'hFFFFD)? 1 : 0;
always@(posedge reset or posedge clk)
	if(reset)    	gostop2 <= 1'b0;
	else       		gostop2 <= gostop1; 
assign	gostop3 = gostop1 && ~gostop2;
always@(posedge reset or negedge clk)
	if(reset)         gostop <= 1'b0;
	else if(gostop3)  gostop <= ~gostop;
	else           	gostop <= gostop; 

////////coding for rotation-index block////////
assign delta_x = rot_indx*11'd0001,
		 delta_y = rot_indx*11'd0001;

always@(posedge reset or negedge clk)
	if(reset)	rot_indx <= 4'h0;
	else if(deb_A & ~deb_AA)
		if(deb_B)
			if(rot_indx==4'h0) rot_indx <= rot_indx;
			else					 rot_indx <= rot_indx - 4'h1;
		else
			if(rot_indx==4'h7) rot_indx <= rot_indx;
			else					 rot_indx <= rot_indx + 4'h1;
	else       					 rot_indx <= rot_indx;

always@(posedge reset or posedge clk)
if(reset)   begin dett_A <= 1'b1;
                  dett_B <= 1'b1;
            end
else        begin dett_A <= rot_A;
                  dett_B <= rot_B;
            end 
									 
									 
always@(posedge reset or posedge clk) 
 if(reset)                   begin deb_A <= 1'b1;
                                   deb_B <= 1'b1;
                             end
 else if(dett_A && dett_B)   begin deb_A <= 1'b1;
                                   deb_B <= deb_B;
                             end
 else if(~dett_A && ~dett_B) begin deb_A <= 1'b0;
                                   deb_B <= deb_B;
                             end
 else if(~dett_A && dett_B)  begin deb_A <= deb_A;
                                   deb_B <= 1'b1;
                             end
 else if(dett_A && ~dett_B)  begin deb_A <= deb_A; 
                                   deb_B <= 1'b0;
                             end
									  
always@(posedge reset or posedge clk)
 if(reset)       deb_AA <= 1'b1;
 else            deb_AA <= deb_A;    // relationship btw deb_A and deb_AA?

////////coding for MNSTR pattern H-moving block////////
// 32x32 MNSTR
//  moving rightward:  
//     Rmvbody : Rmvjaw0  …act0 in a sequence of 5 flicks
//             : Rmvjaw1  …act1 in a sequence of 5 flicks
//             : Rmvjaw2  …act2 in a sequence of 5 flicks
//  moving leftward:  
//     Lmvbody : Lmvjaw0  …act0 in a sequence of 5 flicks
//             : Lmvjaw1  …act1 in a sequence of 5 flicks
//             : Lmvjaw2  …act2 in a sequence of 5 flicks
always@*
  case(MNSTR_y[4:0])
  5'h00:   Rmvbody <= 16'h000F;
  5'h01:   Rmvbody <= 16'h007F;
  5'h02:   Rmvbody <= 16'h00FF;
  5'h03:   Rmvbody <= 16'h03FF;
  5'h04:   Rmvbody <= 16'h07FF;
  5'h05:   Rmvbody <= 16'h0FFF;
  5'h06:   Rmvbody <= 16'h1FFF;
  5'h07:   Rmvbody <= 16'h3FFF;
  5'h08:   Rmvbody <= 16'h3FFF;
  5'h09:   Rmvbody <= 16'h3FFF;
  5'h0A:   Rmvbody <= 16'h7FFF;
  5'h0B:   Rmvbody <= 16'h7FFF;
  5'h0C:   Rmvbody <= 16'h7FFF;
  5'h0D:   Rmvbody <= 16'hFFFF;
  5'h0E:   Rmvbody <= 16'hFFFF;
  5'h0F:   Rmvbody <= 16'hFFFF;
  5'h1F:   Rmvbody <= 16'h000F;
  5'h1E:   Rmvbody <= 16'h007F;
  5'h1D:   Rmvbody <= 16'h00FF;
  5'h1C:   Rmvbody <= 16'h03FF;
  5'h1B:   Rmvbody <= 16'h07FF;
  5'h1A:   Rmvbody <= 16'h0FFF;
  5'h19:   Rmvbody <= 16'h1FFF;
  5'h18:   Rmvbody <= 16'h3FFF;
  5'h17:   Rmvbody <= 16'h3FFF;
  5'h16:   Rmvbody <= 16'h3FFF;
  5'h15:   Rmvbody <= 16'h7FFF;
  5'h14:   Rmvbody <= 16'h7FFF;
  5'h13:   Rmvbody <= 16'h7FFF;
  5'h12:   Rmvbody <= 16'hFFFF;
  5'h11:   Rmvbody <= 16'hFFFF;
  5'h10:   Rmvbody <= 16'hFFFF;
  default: Rmvbody <= 16'h0000;
  endcase

always@*
  case(MNSTR_y[4:0])
  5'h00:   Lmvbody <= 16'hF000;
  5'h01:   Lmvbody <= 16'hFE00;
  5'h02:   Lmvbody <= 16'hFF00;
  5'h03:   Lmvbody <= 16'hFFC0;
  5'h04:   Lmvbody <= 16'hFFE0;
  5'h05:   Lmvbody <= 16'hFFF0;
  5'h06:   Lmvbody <= 16'hFFF8;
  5'h07:   Lmvbody <= 16'hFFFC;
  5'h08:   Lmvbody <= 16'hFFFC;
  5'h09:   Lmvbody <= 16'hFFFC;
  5'h0A:   Lmvbody <= 16'hFFFE;
  5'h0B:   Lmvbody <= 16'hFFFE;
  5'h0C:   Lmvbody <= 16'hFFFE;
  5'h0D:   Lmvbody <= 16'hFFFF;
  5'h0E:   Lmvbody <= 16'hFFFF;
  5'h0F:   Lmvbody <= 16'hFFFF;
  5'h1F:   Lmvbody <= 16'hF000;
  5'h1E:   Lmvbody <= 16'hFE00;
  5'h1D:   Lmvbody <= 16'hFF00;
  5'h1C:   Lmvbody <= 16'hFFC0;
  5'h1B:   Lmvbody <= 16'hFFE0;
  5'h1A:   Lmvbody <= 16'hFFF0;
  5'h19:   Lmvbody <= 16'hFFF8;
  5'h18:   Lmvbody <= 16'hFFFC;
  5'h17:   Lmvbody <= 16'hFFFC;
  5'h16:   Lmvbody <= 16'hFFFC;
  5'h15:   Lmvbody <= 16'hFFFE;
  5'h14:   Lmvbody <= 16'hFFFE;
  5'h13:   Lmvbody <= 16'hFFFE;
  5'h12:   Lmvbody <= 16'hFFFF;
  5'h11:   Lmvbody <= 16'hFFFF;
  5'h10:   Lmvbody <= 16'hFFFF;
  default: Lmvbody <= 16'h0000;
  endcase

always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Rmvjaw0 <= 16'hE000;
  5'h01:   Rmvjaw0 <= 16'hF800;
  5'h02:   Rmvjaw0 <= 16'hFE00;
  5'h03:   Rmvjaw0 <= 16'hFC00;
  5'h04:   Rmvjaw0 <= 16'hFFC0;
  5'h05:   Rmvjaw0 <= 16'hFFE0;
  5'h06:   Rmvjaw0 <= 16'hFFC0;
  5'h07:   Rmvjaw0 <= 16'hFF80;
  5'h08:   Rmvjaw0 <= 16'hFF00;
  5'h09:   Rmvjaw0 <= 16'hFE00;
  5'h0A:   Rmvjaw0 <= 16'hFC00;
  5'h0B:   Rmvjaw0 <= 16'hF800;
  5'h0C:   Rmvjaw0 <= 16'hF000;
  5'h0D:   Rmvjaw0 <= 16'hE000;
  5'h0E:   Rmvjaw0 <= 16'hC000;
  5'h0F:   Rmvjaw0 <= 16'h8000;
  5'h1F:   Rmvjaw0 <= 16'hE000;
  5'h1E:   Rmvjaw0 <= 16'hF800;
  5'h1D:   Rmvjaw0 <= 16'hFE00;
  5'h1C:   Rmvjaw0 <= 16'hFC00;
  5'h1B:   Rmvjaw0 <= 16'hFFC0;
  5'h1A:   Rmvjaw0 <= 16'hFFE0;
  5'h19:   Rmvjaw0 <= 16'hFFC0;
  5'h18:   Rmvjaw0 <= 16'hFF80;
  5'h17:   Rmvjaw0 <= 16'hFF00;
  5'h16:   Rmvjaw0 <= 16'hFE00;
  5'h15:   Rmvjaw0 <= 16'hFC00;
  5'h14:   Rmvjaw0 <= 16'hF800;
  5'h13:   Rmvjaw0 <= 16'hF000;
  5'h12:   Rmvjaw0 <= 16'hE000;
  5'h11:   Rmvjaw0 <= 16'hC000;
  5'h10:   Rmvjaw0 <= 16'h8000;
  default: Rmvjaw0 <= 16'h0000;
  endcase
  
always@*
  case(MNSTR_y[4:0])
  5'h00:   Rmvjaw1 <= 16'hE000;
  5'h01:   Rmvjaw1 <= 16'hF800;
  5'h02:   Rmvjaw1 <= 16'hFE00;
  5'h03:   Rmvjaw1 <= 16'hFF00;
  5'h04:   Rmvjaw1 <= 16'hFF80;
  5'h05:   Rmvjaw1 <= 16'hFFC0;
  5'h06:   Rmvjaw1 <= 16'hFFE0;
  5'h07:   Rmvjaw1 <= 16'hFFF0;
  5'h08:   Rmvjaw1 <= 16'hFFF0;
  5'h09:   Rmvjaw1 <= 16'hFFF8;
  5'h0A:   Rmvjaw1 <= 16'hFFE0;
  5'h0B:   Rmvjaw1 <= 16'hFFC0;
  5'h0C:   Rmvjaw1 <= 16'hFF00;
  5'h0D:   Rmvjaw1 <= 16'hF800;
  5'h0E:   Rmvjaw1 <= 16'hE000;
  5'h0F:   Rmvjaw1 <= 16'hC000;
  5'h1F:   Rmvjaw1 <= 16'hE000;
  5'h1E:   Rmvjaw1 <= 16'hF800;
  5'h1D:   Rmvjaw1 <= 16'hFE00;
  5'h1C:   Rmvjaw1 <= 16'hFF00;
  5'h1B:   Rmvjaw1 <= 16'hFF80;
  5'h1A:   Rmvjaw1 <= 16'hFFC0;
  5'h19:   Rmvjaw1 <= 16'hFFE0;
  5'h18:   Rmvjaw1 <= 16'hFFF0;
  5'h17:   Rmvjaw1 <= 16'hFFF0;
  5'h16:   Rmvjaw1 <= 16'hFFF8;
  5'h15:   Rmvjaw1 <= 16'hFFE0;
  5'h14:   Rmvjaw1 <= 16'hFFC0;
  5'h13:   Rmvjaw1 <= 16'hFF00;
  5'h12:   Rmvjaw1 <= 16'hF800;
  5'h11:   Rmvjaw1 <= 16'hE000;
  5'h10:   Rmvjaw1 <= 16'hC000;
  default: Rmvjaw1 <= 16'h0000;
  endcase
 
always@*
  case(MNSTR_y[4:0])
  5'h00:   Rmvjaw2 <= 16'hE000;
  5'h01:   Rmvjaw2 <= 16'hF800;
  5'h02:   Rmvjaw2 <= 16'hFE00;
  5'h03:   Rmvjaw2 <= 16'hFF00;
  5'h04:   Rmvjaw2 <= 16'hFF80;
  5'h05:   Rmvjaw2 <= 16'hFFC0;
  5'h06:   Rmvjaw2 <= 16'hFFE0;
  5'h07:   Rmvjaw2 <= 16'hFFF0;
  5'h08:   Rmvjaw2 <= 16'hFFF8;
  5'h09:   Rmvjaw2 <= 16'hFFFC;
  5'h0A:   Rmvjaw2 <= 16'hFFFE;
  5'h0B:   Rmvjaw2 <= 16'hFFFF;
  5'h0C:   Rmvjaw2 <= 16'hFFFF;
  5'h0D:   Rmvjaw2 <= 16'hFFFF;
  5'h0E:   Rmvjaw2 <= 16'hFFC0;
  5'h0F:   Rmvjaw2 <= 16'hD000;
  5'h1F:   Rmvjaw2 <= 16'hE000;
  5'h1E:   Rmvjaw2 <= 16'hF800;
  5'h1D:   Rmvjaw2 <= 16'hFE00;
  5'h1C:   Rmvjaw2 <= 16'hFF00;
  5'h1B:   Rmvjaw2 <= 16'hFF80;
  5'h1A:   Rmvjaw2 <= 16'hFFC0;
  5'h19:   Rmvjaw2 <= 16'hFFE0;
  5'h18:   Rmvjaw2 <= 16'hFFF0;
  5'h17:   Rmvjaw2 <= 16'hFFF8;
  5'h16:   Rmvjaw2 <= 16'hFFFC;
  5'h15:   Rmvjaw2 <= 16'hFFFE;
  5'h14:   Rmvjaw2 <= 16'hFFFF;
  5'h13:   Rmvjaw2 <= 16'hFFFF;
  5'h12:   Rmvjaw2 <= 16'hFFFF;
  5'h11:   Rmvjaw2 <= 16'hFFC0;
  5'h10:   Rmvjaw2 <= 16'hD000;
  default: Rmvjaw2 <= 16'h0000;
  endcase

always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Lmvjaw0 <= 16'h0007;
  5'h01:   Lmvjaw0 <= 16'h001F;
  5'h02:   Lmvjaw0 <= 16'h007F;
  5'h03:   Lmvjaw0 <= 16'h00FF;
  5'h04:   Lmvjaw0 <= 16'h03FF;
  5'h05:   Lmvjaw0 <= 16'h07FF;
  5'h06:   Lmvjaw0 <= 16'h03FF;
  5'h07:   Lmvjaw0 <= 16'h01FF;
  5'h08:   Lmvjaw0 <= 16'h00FF;
  5'h09:   Lmvjaw0 <= 16'h007F;
  5'h0A:   Lmvjaw0 <= 16'h003F;
  5'h0B:   Lmvjaw0 <= 16'h001F;
  5'h0C:   Lmvjaw0 <= 16'h000F;
  5'h0D:   Lmvjaw0 <= 16'h0007;
  5'h0E:   Lmvjaw0 <= 16'h0003;
  5'h0F:   Lmvjaw0 <= 16'h0001;
  5'h1F:   Lmvjaw0 <= 16'h0007;
  5'h1E:   Lmvjaw0 <= 16'h001F;
  5'h1D:   Lmvjaw0 <= 16'h007F;
  5'h1C:   Lmvjaw0 <= 16'h00FF;
  5'h1B:   Lmvjaw0 <= 16'h03FF;
  5'h1A:   Lmvjaw0 <= 16'h07FF;
  5'h19:   Lmvjaw0 <= 16'h03FF;
  5'h18:   Lmvjaw0 <= 16'h01FF;
  5'h17:   Lmvjaw0 <= 16'h00FF;
  5'h16:   Lmvjaw0 <= 16'h007F;
  5'h15:   Lmvjaw0 <= 16'h003F;
  5'h14:   Lmvjaw0 <= 16'h001F;
  5'h13:   Lmvjaw0 <= 16'h000F;
  5'h12:   Lmvjaw0 <= 16'h0007;
  5'h11:   Lmvjaw0 <= 16'h0003;
  5'h10:   Lmvjaw0 <= 16'h0001;
  default: Lmvjaw0 <= 16'h0000;
  endcase

always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Lmvjaw1 <= 16'h0007;
  5'h01:   Lmvjaw1 <= 16'h001F;
  5'h02:   Lmvjaw1 <= 16'h007F;
  5'h03:   Lmvjaw1 <= 16'h00FF;
  5'h04:   Lmvjaw1 <= 16'h01FF;
  5'h05:   Lmvjaw1 <= 16'h03FF;
  5'h06:   Lmvjaw1 <= 16'h07FF;
  5'h07:   Lmvjaw1 <= 16'h0FFF;
  5'h08:   Lmvjaw1 <= 16'h0FFF;
  5'h09:   Lmvjaw1 <= 16'h1FFF;
  5'h0A:   Lmvjaw1 <= 16'h07FF;
  5'h0B:   Lmvjaw1 <= 16'h03FF;
  5'h0C:   Lmvjaw1 <= 16'h00FF;
  5'h0D:   Lmvjaw1 <= 16'h001F;
  5'h0E:   Lmvjaw1 <= 16'h0007;
  5'h0F:   Lmvjaw1 <= 16'h0003;
  5'h1F:   Lmvjaw1 <= 16'h0007;
  5'h1E:   Lmvjaw1 <= 16'h001F;
  5'h1D:   Lmvjaw1 <= 16'h007F;
  5'h1C:   Lmvjaw1 <= 16'h00FF;
  5'h1B:   Lmvjaw1 <= 16'h01FF;
  5'h1A:   Lmvjaw1 <= 16'h03FF;
  5'h19:   Lmvjaw1 <= 16'h07FF;
  5'h18:   Lmvjaw1 <= 16'h0FFF;
  5'h17:   Lmvjaw1 <= 16'h0FFF;
  5'h16:   Lmvjaw1 <= 16'h1FFF;
  5'h15:   Lmvjaw1 <= 16'h07FF;
  5'h14:   Lmvjaw1 <= 16'h03FF;
  5'h13:   Lmvjaw1 <= 16'h00FF;
  5'h12:   Lmvjaw1 <= 16'h001F;
  5'h11:   Lmvjaw1 <= 16'h0007;
  5'h10:   Lmvjaw1 <= 16'h0003;  
  default: Lmvjaw1 <= 16'h0000;
  endcase
  
  always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Lmvjaw2 <= 16'h0007;
  5'h01:   Lmvjaw2 <= 16'h001F;
  5'h02:   Lmvjaw2 <= 16'h007F;
  5'h03:   Lmvjaw2 <= 16'h00FF;
  5'h04:   Lmvjaw2 <= 16'h01FF;
  5'h05:   Lmvjaw2 <= 16'h03FF;
  5'h06:   Lmvjaw2 <= 16'h07FF;
  5'h07:   Lmvjaw2 <= 16'h0FFF;
  5'h08:   Lmvjaw2 <= 16'h1FFF;
  5'h09:   Lmvjaw2 <= 16'h3FFF;
  5'h0A:   Lmvjaw2 <= 16'h7FFF;
  5'h0B:   Lmvjaw2 <= 16'hFFFF;
  5'h0C:   Lmvjaw2 <= 16'hFFFF;
  5'h0D:   Lmvjaw2 <= 16'hFFFF;
  5'h0E:   Lmvjaw2 <= 16'h03FF;
  5'h0F:   Lmvjaw2 <= 16'h0007;
  5'h1F:   Lmvjaw2 <= 16'h0007;
  5'h1E:   Lmvjaw2 <= 16'h001F;
  5'h1D:   Lmvjaw2 <= 16'h007F;
  5'h1C:   Lmvjaw2 <= 16'h00FF;
  5'h1B:   Lmvjaw2 <= 16'h01FF;
  5'h1A:   Lmvjaw2 <= 16'h03FF;
  5'h19:   Lmvjaw2 <= 16'h07FF;
  5'h18:   Lmvjaw2 <= 16'h0FFF;
  5'h17:   Lmvjaw2 <= 16'h1FFF;
  5'h16:   Lmvjaw2 <= 16'h3FFF;
  5'h15:   Lmvjaw2 <= 16'h7FFF;
  5'h14:   Lmvjaw2 <= 16'hFFFF;
  5'h13:   Lmvjaw2 <= 16'hFFFF;
  5'h12:   Lmvjaw2 <= 16'hFFFF;
  5'h11:   Lmvjaw2 <= 16'h03FF;
  5'h10:   Lmvjaw2 <= 16'h0007; 
  default: Lmvjaw2 <= 16'h0000;
  endcase

////////coding for MNSTR pattern V-moving block////////
// 32x32 MNSTR
//  moving upward:  
//     Umvbdy00 : Umvbdy10  …act0 in a sequence of 5 flicks
//     Umvbdy01 : Umvbdy11  …act1 in a sequence of 5 flicks
//     Umvbdy02 : Umvbdy12  …act2 in a sequence of 5 flicks
//  moving downward:  
//     Dmvbdy00 : Dmvbdy10  …act0 in a sequence of 5 flicks
//     Dmvbdy01 : Dmvbdy11  …act1 in a sequence of 5 flicks
//     Dmvbdy02 : Dmvbdy12  …act2 in a sequence of 5 flicks
always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Umvbdy00 <= 16'h0000;    //00: up-left  act0
  5'h01:   Umvbdy00 <= 16'h0000;
  5'h02:   Umvbdy00 <= 16'h0000;
  5'h03:   Umvbdy00 <= 16'h0000;
  5'h04:   Umvbdy00 <= 16'h0000;
  5'h05:   Umvbdy00 <= 16'h0400;
  5'h06:   Umvbdy00 <= 16'h0E00;
  5'h07:   Umvbdy00 <= 16'h0F00;
  5'h08:   Umvbdy00 <= 16'h1F80;
  5'h09:   Umvbdy00 <= 16'h3FC0;
  5'h0A:   Umvbdy00 <= 16'h3FE0;
  5'h0B:   Umvbdy00 <= 16'h7FF0;
  5'h0C:   Umvbdy00 <= 16'h7FF8;
  5'h0D:   Umvbdy00 <= 16'hFFFC;
  5'h0E:   Umvbdy00 <= 16'hFFFE;
  5'h0F:   Umvbdy00 <= 16'hFFFF;
  5'h10:   Umvbdy00 <= 16'hFFFF;
  5'h11:   Umvbdy00 <= 16'hFFFF;
  5'h12:   Umvbdy00 <= 16'hFFFF;
  5'h13:   Umvbdy00 <= 16'hFFFF;
  5'h14:   Umvbdy00 <= 16'h7FFF;
  5'h15:   Umvbdy00 <= 16'h7FFF;
  5'h16:   Umvbdy00 <= 16'h7FFF;
  5'h17:   Umvbdy00 <= 16'h3FFF;
  5'h18:   Umvbdy00 <= 16'h1FFF;
  5'h19:   Umvbdy00 <= 16'h1FFF;
  5'h1A:   Umvbdy00 <= 16'h0FFF;
  5'h1B:   Umvbdy00 <= 16'h07FF;
  5'h1C:   Umvbdy00 <= 16'h03FF;
  5'h1D:   Umvbdy00 <= 16'h01FF;
  5'h1E:   Umvbdy00 <= 16'h003F;
  5'h1F:   Umvbdy00 <= 16'h0007;
  default: Umvbdy00 <= 16'h0000;
  endcase
  
always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Umvbdy10 <= 16'h0000;      //10:  up_right act0
  5'h01:   Umvbdy10 <= 16'h0000;
  5'h02:   Umvbdy10 <= 16'h0000;
  5'h03:   Umvbdy10 <= 16'h0000;
  5'h04:   Umvbdy10 <= 16'h0000;
  5'h05:   Umvbdy10 <= 16'h0020;
  5'h06:   Umvbdy10 <= 16'h0070;
  5'h07:   Umvbdy10 <= 16'h00F0;
  5'h08:   Umvbdy10 <= 16'h01F8;
  5'h09:   Umvbdy10 <= 16'h03FC;
  5'h0A:   Umvbdy10 <= 16'h07FE;
  5'h0B:   Umvbdy10 <= 16'h0FFE;
  5'h0C:   Umvbdy10 <= 16'h1FFE;
  5'h0D:   Umvbdy10 <= 16'h3FFE;
  5'h0E:   Umvbdy10 <= 16'h7FFE;
  5'h0F:   Umvbdy10 <= 16'hFFFF;
  5'h10:   Umvbdy10 <= 16'hFFFF;
  5'h11:   Umvbdy10 <= 16'hFFFF;
  5'h12:   Umvbdy10 <= 16'hFFFF;
  5'h13:   Umvbdy10 <= 16'hFFFF;
  5'h14:   Umvbdy10 <= 16'hFFFE;
  5'h15:   Umvbdy10 <= 16'hFFFE;
  5'h16:   Umvbdy10 <= 16'hFFFE;
  5'h17:   Umvbdy10 <= 16'hFFFC;
  5'h18:   Umvbdy10 <= 16'hFFF8;
  5'h19:   Umvbdy10 <= 16'hFFF8;
  5'h1A:   Umvbdy10 <= 16'hFFF0;
  5'h1B:   Umvbdy10 <= 16'hFFE0;
  5'h1C:   Umvbdy10 <= 16'hFFC0;
  5'h1D:   Umvbdy10 <= 16'hFF80;
  5'h1E:   Umvbdy10 <= 16'hFC00;
  5'h1F:   Umvbdy10 <= 16'hE000;
  default: Umvbdy10 <= 16'h0000;
  endcase

always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Umvbdy01 <= 16'h0000;    //01: up-left act1
  5'h01:   Umvbdy01 <= 16'h0000;
  5'h02:   Umvbdy01 <= 16'h0000;
  5'h03:   Umvbdy01 <= 16'h0040;
  5'h04:   Umvbdy01 <= 16'h01C0;
  5'h05:   Umvbdy01 <= 16'h03E0;
  5'h06:   Umvbdy01 <= 16'h07F0;
  5'h07:   Umvbdy01 <= 16'h0FF0;
  5'h08:   Umvbdy01 <= 16'h1FF8;
  5'h09:   Umvbdy01 <= 16'h3FF8;
  5'h0A:   Umvbdy01 <= 16'h3FF8;
  5'h0B:   Umvbdy01 <= 16'h7FFC;
  5'h0C:   Umvbdy01 <= 16'h7FFC;
  5'h0D:   Umvbdy01 <= 16'hFFFE;
  5'h0E:   Umvbdy01 <= 16'hFFFF;
  5'h0F:   Umvbdy01 <= 16'hFFFF;
  5'h10:   Umvbdy01 <= 16'hFFFF;
  5'h11:   Umvbdy01 <= 16'hFFFF;
  5'h12:   Umvbdy01 <= 16'hFFFF;
  5'h13:   Umvbdy01 <= 16'hFFFF;
  5'h14:   Umvbdy01 <= 16'h7FFF;
  5'h15:   Umvbdy01 <= 16'h7FFF;
  5'h16:   Umvbdy01 <= 16'h7FFF;
  5'h17:   Umvbdy01 <= 16'h3FFF;
  5'h18:   Umvbdy01 <= 16'h1FFF;
  5'h19:   Umvbdy01 <= 16'h1FFF;
  5'h1A:   Umvbdy01 <= 16'h0FFF;
  5'h1B:   Umvbdy01 <= 16'h07FF;
  5'h1C:   Umvbdy01 <= 16'h03FF;
  5'h1D:   Umvbdy01 <= 16'h01FF;
  5'h1E:   Umvbdy01 <= 16'h003F;
  5'h1F:   Umvbdy01 <= 16'h0007;
  default: Umvbdy01 <= 16'h0000;
  endcase
  
always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Umvbdy11 <= 16'h0000;      //11:  up_right act1
  5'h01:   Umvbdy11 <= 16'h0000;
  5'h02:   Umvbdy11 <= 16'h0000;
  5'h03:   Umvbdy11 <= 16'h0200;
  5'h04:   Umvbdy11 <= 16'h0380;
  5'h05:   Umvbdy11 <= 16'h07C0;
  5'h06:   Umvbdy11 <= 16'h0FE0;
  5'h07:   Umvbdy11 <= 16'h0FF0;
  5'h08:   Umvbdy11 <= 16'h1FF8;
  5'h09:   Umvbdy11 <= 16'h1FFC;
  5'h0A:   Umvbdy11 <= 16'h1FFC;
  5'h0B:   Umvbdy11 <= 16'h3FFE;
  5'h0C:   Umvbdy11 <= 16'h3FFE;
  5'h0D:   Umvbdy11 <= 16'h7FFF;
  5'h0E:   Umvbdy11 <= 16'hFFFF;
  5'h0F:   Umvbdy11 <= 16'hFFFF;
  5'h10:   Umvbdy11 <= 16'hFFFF;
  5'h11:   Umvbdy11 <= 16'hFFFF;
  5'h12:   Umvbdy11 <= 16'hFFFF;
  5'h13:   Umvbdy11 <= 16'hFFFF;
  5'h14:   Umvbdy11 <= 16'hFFFE;
  5'h15:   Umvbdy11 <= 16'hFFFE;
  5'h16:   Umvbdy11 <= 16'hFFFE;
  5'h17:   Umvbdy11 <= 16'hFFFC;
  5'h18:   Umvbdy11 <= 16'hFFF8;
  5'h19:   Umvbdy11 <= 16'hFFF8;
  5'h1A:   Umvbdy11 <= 16'hFFF0;
  5'h1B:   Umvbdy11 <= 16'hFFE0;
  5'h1C:   Umvbdy11 <= 16'hFFC0;
  5'h1D:   Umvbdy11 <= 16'hFF80;
  5'h1E:   Umvbdy11 <= 16'hFC00;
  5'h1F:   Umvbdy11 <= 16'hE000;
  default: Umvbdy11 <= 16'h0000;
  endcase

always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Umvbdy02 <= 16'h001C;    //02: up-left act2
  5'h01:   Umvbdy02 <= 16'h003C;
  5'h02:   Umvbdy02 <= 16'h007C;
  5'h03:   Umvbdy02 <= 16'h00FC;
  5'h04:   Umvbdy02 <= 16'h01FC;
  5'h05:   Umvbdy02 <= 16'h03FC;
  5'h06:   Umvbdy02 <= 16'h07FE;
  5'h07:   Umvbdy02 <= 16'h0FFE;
  5'h08:   Umvbdy02 <= 16'h1FFE;
  5'h09:   Umvbdy02 <= 16'h3FFE;
  5'h0A:   Umvbdy02 <= 16'h3FFE;
  5'h0B:   Umvbdy02 <= 16'h7FFE;
  5'h0C:   Umvbdy02 <= 16'h7FFE;
  5'h0D:   Umvbdy02 <= 16'hFFFF;
  5'h0E:   Umvbdy02 <= 16'hFFFF;
  5'h0F:   Umvbdy02 <= 16'hFFFF;
  5'h10:   Umvbdy02 <= 16'hFFFF;
  5'h11:   Umvbdy02 <= 16'hFFFF;
  5'h12:   Umvbdy02 <= 16'hFFFF;
  5'h13:   Umvbdy02 <= 16'hFFFF;
  5'h14:   Umvbdy02 <= 16'h7FFF;
  5'h15:   Umvbdy02 <= 16'h7FFF;
  5'h16:   Umvbdy02 <= 16'h7FFF;
  5'h17:   Umvbdy02 <= 16'h3FFF;
  5'h18:   Umvbdy02 <= 16'h1FFF;
  5'h19:   Umvbdy02 <= 16'h1FFF;
  5'h1A:   Umvbdy02 <= 16'h0FFF;
  5'h1B:   Umvbdy02 <= 16'h07FF;
  5'h1C:   Umvbdy02 <= 16'h03FF;
  5'h1D:   Umvbdy02 <= 16'h01FF;
  5'h1E:   Umvbdy02 <= 16'h003F;
  5'h1F:   Umvbdy02 <= 16'h0007;
  default: Umvbdy02 <= 16'h0000;
  endcase
  
always@(*)
  case(MNSTR_y[4:0])
  5'h00:   Umvbdy12 <= 16'h7000;      //12:  up_right act2
  5'h01:   Umvbdy12 <= 16'h7C00;
  5'h02:   Umvbdy12 <= 16'h7E00;
  5'h03:   Umvbdy12 <= 16'h7F00;
  5'h04:   Umvbdy12 <= 16'h7F80;
  5'h05:   Umvbdy12 <= 16'h7FC0;
  5'h06:   Umvbdy12 <= 16'hFFE0;
  5'h07:   Umvbdy12 <= 16'hFFF0;
  5'h08:   Umvbdy12 <= 16'hFFF8;
  5'h09:   Umvbdy12 <= 16'hFFFC;
  5'h0A:   Umvbdy12 <= 16'hFFFC;
  5'h0B:   Umvbdy12 <= 16'hFFFE;
  5'h0C:   Umvbdy12 <= 16'hFFFE;
  5'h0D:   Umvbdy12 <= 16'h7FFF;
  5'h0E:   Umvbdy12 <= 16'hFFFF;
  5'h0F:   Umvbdy12 <= 16'hFFFF;
  5'h10:   Umvbdy12 <= 16'hFFFF;
  5'h11:   Umvbdy12 <= 16'hFFFF;
  5'h12:   Umvbdy12 <= 16'hFFFF;
  5'h13:   Umvbdy12 <= 16'hFFFF;
  5'h14:   Umvbdy12 <= 16'hFFFE;
  5'h15:   Umvbdy12 <= 16'hFFFE;
  5'h16:   Umvbdy12 <= 16'hFFFE;
  5'h17:   Umvbdy12 <= 16'hFFFC;
  5'h18:   Umvbdy12 <= 16'hFFF8;
  5'h19:   Umvbdy12 <= 16'hFFF8;
  5'h1A:   Umvbdy12 <= 16'hFFF0;
  5'h1B:   Umvbdy12 <= 16'hFFE0;
  5'h1C:   Umvbdy12 <= 16'hFFC0;
  5'h1D:   Umvbdy12 <= 16'hFF80;
  5'h1E:   Umvbdy12 <= 16'hFC00;
  5'h1F:   Umvbdy12 <= 16'hE000;
  default: Umvbdy12 <= 16'h0000;
  endcase

// = = = = = = = = = = =

always@(*)
  case(MNSTR_y[4:0])
  5'h1F:   Dmvbdy00 <= 16'h0000;    //00: down-left  act0
  5'h1E:   Dmvbdy00 <= 16'h0000;
  5'h1D:   Dmvbdy00 <= 16'h0000;
  5'h1C:   Dmvbdy00 <= 16'h0000;
  5'h1B:   Dmvbdy00 <= 16'h0000;
  5'h1A:   Dmvbdy00 <= 16'h0400;
  5'h19:   Dmvbdy00 <= 16'h0E00;
  5'h18:   Dmvbdy00 <= 16'h0F00;
  5'h17:   Dmvbdy00 <= 16'h1F80;
  5'h16:   Dmvbdy00 <= 16'h3FC0;
  5'h15:   Dmvbdy00 <= 16'h3FE0;
  5'h14:   Dmvbdy00 <= 16'h7FF0;
  5'h13:   Dmvbdy00 <= 16'h7FF8;
  5'h12:   Dmvbdy00 <= 16'hFFFC;
  5'h11:   Dmvbdy00 <= 16'hFFFE;
  5'h10:   Dmvbdy00 <= 16'hFFFF;
  5'h0F:   Dmvbdy00 <= 16'hFFFF;
  5'h0E:   Dmvbdy00 <= 16'hFFFF;
  5'h0D:   Dmvbdy00 <= 16'hFFFF;
  5'h0C:   Dmvbdy00 <= 16'hFFFF;
  5'h0B:   Dmvbdy00 <= 16'h7FFF;
  5'h0A:   Dmvbdy00 <= 16'h7FFF;
  5'h09:   Dmvbdy00 <= 16'h7FFF;
  5'h08:   Dmvbdy00 <= 16'h3FFF;
  5'h07:   Dmvbdy00 <= 16'h1FFF;
  5'h06:   Dmvbdy00 <= 16'h1FFF;
  5'h05:   Dmvbdy00 <= 16'h0FFF;
  5'h04:   Dmvbdy00 <= 16'h07FF;
  5'h03:   Dmvbdy00 <= 16'h03FF;
  5'h02:   Dmvbdy00 <= 16'h01FF;
  5'h01:   Dmvbdy00 <= 16'h003F;
  5'h00:   Dmvbdy00 <= 16'h0007;
  default: Dmvbdy00 <= 16'h0000;
  endcase
  
always@(*)
  case(MNSTR_y[4:0])
  5'h1F:   Dmvbdy10 <= 16'h0000;      //10:  down_right act0
  5'h1E:   Dmvbdy10 <= 16'h0000;
  5'h1D:   Dmvbdy10 <= 16'h0000;
  5'h1C:   Dmvbdy10 <= 16'h0000;
  5'h1B:   Dmvbdy10 <= 16'h0000;
  5'h1A:   Dmvbdy10 <= 16'h0020;
  5'h19:   Dmvbdy10 <= 16'h0070;
  5'h18:   Dmvbdy10 <= 16'h00F0;
  5'h17:   Dmvbdy10 <= 16'h01F8;
  5'h16:   Dmvbdy10 <= 16'h03FC;
  5'h15:   Dmvbdy10 <= 16'h07FE;
  5'h14:   Dmvbdy10 <= 16'h0FFE;
  5'h13:   Dmvbdy10 <= 16'h1FFE;
  5'h12:   Dmvbdy10 <= 16'h3FFE;
  5'h11:   Dmvbdy10 <= 16'h7FFE;
  5'h10:   Dmvbdy10 <= 16'hFFFF;
  5'h0F:   Dmvbdy10 <= 16'hFFFF;
  5'h0E:   Dmvbdy10 <= 16'hFFFF;
  5'h0D:   Dmvbdy10 <= 16'hFFFF;
  5'h0C:   Dmvbdy10 <= 16'hFFFF;
  5'h0B:   Dmvbdy10 <= 16'hFFFE;
  5'h0A:   Dmvbdy10 <= 16'hFFFE;
  5'h09:   Dmvbdy10 <= 16'hFFFE;
  5'h08:   Dmvbdy10 <= 16'hFFFC;
  5'h07:   Dmvbdy10 <= 16'hFFF8;
  5'h06:   Dmvbdy10 <= 16'hFFF8;
  5'h05:   Dmvbdy10 <= 16'hFFF0;
  5'h04:   Dmvbdy10 <= 16'hFFE0;
  5'h03:   Dmvbdy10 <= 16'hFFC0;
  5'h02:   Dmvbdy10 <= 16'hFF80;
  5'h01:   Dmvbdy10 <= 16'hFC00;
  5'h00:   Dmvbdy10 <= 16'hE000;
  default: Dmvbdy10 <= 16'h0000;
  endcase

always@(*)
  case(MNSTR_y[4:0])
  5'h1F:   Dmvbdy01 <= 16'h0000;    //01: down-left act1
  5'h1E:   Dmvbdy01 <= 16'h0000;
  5'h1D:   Dmvbdy01 <= 16'h0000;
  5'h1C:   Dmvbdy01 <= 16'h0040;
  5'h1B:   Dmvbdy01 <= 16'h01C0;
  5'h1A:   Dmvbdy01 <= 16'h03E0;
  5'h19:   Dmvbdy01 <= 16'h07F0;
  5'h18:   Dmvbdy01 <= 16'h0FF0;
  5'h17:   Dmvbdy01 <= 16'h1FF8;
  5'h16:   Dmvbdy01 <= 16'h3FF8;
  5'h15:   Dmvbdy01 <= 16'h3FF8;
  5'h14:   Dmvbdy01 <= 16'h7FFC;
  5'h13:   Dmvbdy01 <= 16'h7FFC;
  5'h12:   Dmvbdy01 <= 16'hFFFE;
  5'h11:   Dmvbdy01 <= 16'hFFFF;
  5'h10:   Dmvbdy01 <= 16'hFFFF;
  5'h0F:   Dmvbdy01 <= 16'hFFFF;
  5'h0E:   Dmvbdy01 <= 16'hFFFF;
  5'h0D:   Dmvbdy01 <= 16'hFFFF;
  5'h0C:   Dmvbdy01 <= 16'hFFFF;
  5'h0B:   Dmvbdy01 <= 16'h7FFF;
  5'h0A:   Dmvbdy01 <= 16'h7FFF;
  5'h09:   Dmvbdy01 <= 16'h7FFF;
  5'h08:   Dmvbdy01 <= 16'h3FFF;
  5'h07:   Dmvbdy01 <= 16'h1FFF;
  5'h06:   Dmvbdy01 <= 16'h1FFF;
  5'h05:   Dmvbdy01 <= 16'h0FFF;
  5'h04:   Dmvbdy01 <= 16'h07FF;
  5'h03:   Dmvbdy01 <= 16'h03FF;
  5'h02:   Dmvbdy01 <= 16'h01FF;
  5'h01:   Dmvbdy01 <= 16'h003F;
  5'h00:   Dmvbdy01 <= 16'h0007;
  default: Dmvbdy01 <= 16'h0000;
  endcase
  
always@(*)
  case(MNSTR_y[4:0])
  5'h1F:   Dmvbdy11 <= 16'h0000;      //11:  down_right act1
  5'h1E:   Dmvbdy11 <= 16'h0000;
  5'h1D:   Dmvbdy11 <= 16'h0000;
  5'h1C:   Dmvbdy11 <= 16'h0200;
  5'h1B:   Dmvbdy11 <= 16'h0380;
  5'h1A:   Dmvbdy11 <= 16'h07C0;
  5'h19:   Dmvbdy11 <= 16'h0FE0;
  5'h18:   Dmvbdy11 <= 16'h0FF0;
  5'h17:   Dmvbdy11 <= 16'h1FF8;
  5'h16:   Dmvbdy11 <= 16'h1FFC;
  5'h15:   Dmvbdy11 <= 16'h1FFC;
  5'h14:   Dmvbdy11 <= 16'h3FFE;
  5'h13:   Dmvbdy11 <= 16'h3FFE;
  5'h12:   Dmvbdy11 <= 16'h7FFF;
  5'h11:   Dmvbdy11 <= 16'hFFFF;
  5'h10:   Dmvbdy11 <= 16'hFFFF;
  5'h0F:   Dmvbdy11 <= 16'hFFFF;
  5'h0E:   Dmvbdy11 <= 16'hFFFF;
  5'h0D:   Dmvbdy11 <= 16'hFFFF;
  5'h0C:   Dmvbdy11 <= 16'hFFFF;
  5'h0B:   Dmvbdy11 <= 16'hFFFE;
  5'h0A:   Dmvbdy11 <= 16'hFFFE;
  5'h09:   Dmvbdy11 <= 16'hFFFE;
  5'h08:   Dmvbdy11 <= 16'hFFFC;
  5'h07:   Dmvbdy11 <= 16'hFFF8;
  5'h06:   Dmvbdy11 <= 16'hFFF8;
  5'h05:   Dmvbdy11 <= 16'hFFF0;
  5'h04:   Dmvbdy11 <= 16'hFFE0;
  5'h03:   Dmvbdy11 <= 16'hFFC0;
  5'h02:   Dmvbdy11 <= 16'hFF80;
  5'h01:   Dmvbdy11 <= 16'hFC00;
  5'h00:   Dmvbdy11 <= 16'hE000;
  default: Dmvbdy11 <= 16'h0000;
  endcase

always@(*)
  case(MNSTR_y[4:0])
  5'h1F:   Dmvbdy02 <= 16'h001C;    //02: down-left act2
  5'h1E:   Dmvbdy02 <= 16'h003C;
  5'h1D:   Dmvbdy02 <= 16'h007C;
  5'h1C:   Dmvbdy02 <= 16'h00FC;
  5'h1B:   Dmvbdy02 <= 16'h01FC;
  5'h1A:   Dmvbdy02 <= 16'h03FC;
  5'h19:   Dmvbdy02 <= 16'h07FE;
  5'h18:   Dmvbdy02 <= 16'h0FFE;
  5'h17:   Dmvbdy02 <= 16'h1FFE;
  5'h16:   Dmvbdy02 <= 16'h3FFE;
  5'h15:   Dmvbdy02 <= 16'h3FFE;
  5'h14:   Dmvbdy02 <= 16'h7FFE;
  5'h13:   Dmvbdy02 <= 16'h7FFE;
  5'h12:   Dmvbdy02 <= 16'hFFFF;
  5'h11:   Dmvbdy02 <= 16'hFFFF;
  5'h10:   Dmvbdy02 <= 16'hFFFF;
  5'h0F:   Dmvbdy02 <= 16'hFFFF;
  5'h0E:   Dmvbdy02 <= 16'hFFFF;
  5'h0D:   Dmvbdy02 <= 16'hFFFF;
  5'h0C:   Dmvbdy02 <= 16'hFFFF;
  5'h0B:   Dmvbdy02 <= 16'h7FFF;
  5'h0A:   Dmvbdy02 <= 16'h7FFF;
  5'h09:   Dmvbdy02 <= 16'h7FFF;
  5'h08:   Dmvbdy02 <= 16'h3FFF;
  5'h07:   Dmvbdy02 <= 16'h1FFF;
  5'h06:   Dmvbdy02 <= 16'h1FFF;
  5'h05:   Dmvbdy02 <= 16'h0FFF;
  5'h04:   Dmvbdy02 <= 16'h07FF;
  5'h03:   Dmvbdy02 <= 16'h03FF;
  5'h02:   Dmvbdy02 <= 16'h01FF;
  5'h01:   Dmvbdy02 <= 16'h003F;
  5'h00:   Dmvbdy02 <= 16'h0007;
  default: Dmvbdy02 <= 16'h0000;
  endcase
  
always@(*)
  case(MNSTR_y[4:0])
  5'h1F:   Dmvbdy12 <= 16'h7000;      //12:  down_right act2
  5'h1E:   Dmvbdy12 <= 16'h7C00;
  5'h1D:   Dmvbdy12 <= 16'h7E00;
  5'h1C:   Dmvbdy12 <= 16'h7F00;
  5'h1B:   Dmvbdy12 <= 16'h7F80;
  5'h1A:   Dmvbdy12 <= 16'h7FC0;
  5'h19:   Dmvbdy12 <= 16'hFFE0;
  5'h18:   Dmvbdy12 <= 16'hFFF0;
  5'h17:   Dmvbdy12 <= 16'hFFF8;
  5'h16:   Dmvbdy12 <= 16'hFFFC;
  5'h15:   Dmvbdy12 <= 16'hFFFC;
  5'h14:   Dmvbdy12 <= 16'hFFFE;
  5'h13:   Dmvbdy12 <= 16'hFFFE;
  5'h12:   Dmvbdy12 <= 16'h7FFF;
  5'h11:   Dmvbdy12 <= 16'hFFFF;
  5'h10:   Dmvbdy12 <= 16'hFFFF;
  5'h0F:   Dmvbdy12 <= 16'hFFFF;
  5'h0E:   Dmvbdy12 <= 16'hFFFF;
  5'h0D:   Dmvbdy12 <= 16'hFFFF;
  5'h0C:   Dmvbdy12 <= 16'hFFFF;
  5'h0B:   Dmvbdy12 <= 16'hFFFE;
  5'h0A:   Dmvbdy12 <= 16'hFFFE;
  5'h09:   Dmvbdy12 <= 16'hFFFE;
  5'h08:   Dmvbdy12 <= 16'hFFFC;
  5'h07:   Dmvbdy12 <= 16'hFFF8;
  5'h06:   Dmvbdy12 <= 16'hFFF0;
  5'h04:   Dmvbdy12 <= 16'hFFE0;
  5'h03:   Dmvbdy12 <= 16'hFFC0;
  5'h02:   Dmvbdy12 <= 16'hFF80;
  5'h01:   Dmvbdy12 <= 16'hFC00;
  5'h00:   Dmvbdy12 <= 16'hE000; 
  default: Dmvbdy12 <= 16'h0000;
  endcase

////////coding for MNSTR display block////////

// region of MNSTR in 800x600 visible zone
assign MNSTR_on = (X_pix<body_x)? 0: (X_pix>=body_x+11'd0032)? 0: (Y_pix<body_y)? 0: (Y_pix>=body_y+11'd0032)?   0:1;

// active row of the MNSTR pattern (1x32 in 32x32) associated with
// the active H-scan line
assign  MNSTR_y = (Y_pix<body_y)? 0: (Y_pix>body_y+11'd0031)? 0:Y_pix-body_y;	
always@(posedge reset or posedge clk)
	if(reset)    				MNSTR_row <= 32'h000FE000;
	else if(X_pix+11'h001==body_x)
		case({mvdir_indx, act_cnt})
		5'b11000:   			MNSTR_row <= {Rmvbody, Rmvjaw0};   //mv-right
		5'b11001:   			MNSTR_row <= {Rmvbody, Rmvjaw1};
		5'b11010:   			MNSTR_row <= {Rmvbody, Rmvjaw1};
		5'b11011:   			MNSTR_row <= {Rmvbody, Rmvjaw2};
		5'b11100:   			MNSTR_row <= {Rmvbody, Rmvjaw2};
		5'b10000:   			MNSTR_row <= {Lmvjaw0, Lmvbody};    //mv-left
		5'b10001:   			MNSTR_row <= {Lmvjaw1, Lmvbody};
		5'b10010:   			MNSTR_row <= {Lmvjaw1, Lmvbody};
		5'b10011:   			MNSTR_row <= {Lmvjaw2, Lmvbody};
		5'b10100:   			MNSTR_row <= {Lmvjaw2, Lmvbody};
		5'b01000:   			MNSTR_row <= {Dmvbdy00, Dmvbdy10};  //mv-dwn
		5'b01001:   			MNSTR_row <= {Dmvbdy01, Dmvbdy11};
		5'b01010:   			MNSTR_row <= {Dmvbdy01, Dmvbdy11};
		5'b01011:   			MNSTR_row <= {Dmvbdy02, Dmvbdy12};
		5'b01100:   			MNSTR_row <= {Dmvbdy02, Dmvbdy12};
		5'b00000:   			MNSTR_row <= {Umvbdy00, Umvbdy10};  //mv-up
		5'b00001:   			MNSTR_row <= {Umvbdy01, Umvbdy11};
		5'b00010:   			MNSTR_row <= {Umvbdy01, Umvbdy11};
		5'b00011:   			MNSTR_row <= {Umvbdy02, Umvbdy12};
		5'b00100:   			MNSTR_row <= {Umvbdy02, Umvbdy12};
		default:    			MNSTR_row <= 32'h00000000;     
		endcase
	else if(MNSTR_on) 		MNSTR_row <= {MNSTR_row[30:0], MNSTR_row[31]};
	else     					MNSTR_row <= 32'h00000000;     //=MNSTR_row;???

////////coding for MNSTR RGB control block////////

assign   R_mnstr = (MNSTR_on && MNSTR_row[31] && SW[0])?  1:0;
assign   G_mnstr = (MNSTR_on && MNSTR_row[31] && SW[1])?  1:0;
assign   B_mnstr = (MNSTR_on && MNSTR_row[31] && SW[2])?  1:0;

always@(posedge reset or posedge clk)
	if(reset) 
		begin GG <= 1'b0;
				BB <= 1'b0;
				RR <= 1'b0;
		end
	else if(MNSTR_on)
		begin RR <= R_mnstr;
				GG <= G_mnstr;
				BB <= B_mnstr;
		end
	else 
		begin RR <= 1'b0;
				GG <= 1'b0;
				BB <= 1'b0;
		end
assign   R = RR, G = GG, B = BB;

////////coding for internal status probing block////////
assign   LED[7:0] = {gostop, 1'b0, mvdir_indx, 1'b0, rot_indx[2:0]};

endmodule*/

