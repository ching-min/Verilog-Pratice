`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:50:16 12/18/2014 
// Design Name: 
// Module Name:    fpga2 
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
module fpga2(
    input [3:0]SW,
    input rot_A,
    input rot_B,
    input rot_dwn,
    input BTN0,
    input BTN1,
    input BTN2,
    input reset,
    input clk,
    output reg[7:0]LED
    );
	 
reg      [23:0]    cnt24 ; 
reg deb_A,deb_B,deb_AA;   
wire [1:0]knob_status;
reg btn00,btn11,btn22;
reg rot_btn;
reg rr_set,rl_set,rr_continue,rl_continue,toggle_cnt;
always@(posedge reset or posedge clk)//
	if(reset) cnt24<= 24'h000000;
	else if(cnt24<24'ha00000)  cnt24<= cnt24+24'h000001;
	else cnt24<= 24'h000000;
assign  slowclk= (cnt24==24'ha00000)?  1'b1 : 1'b0;


always@(posedge reset or posedge clk)//
	if(reset)	begin deb_A<=1'b1;
                  deb_B<=1'b1;
            end
	else if(rot_A && rot_B) begin deb_A<=1'b1;
                               deb_B<=deb_B;
                         end
	else if(~rot_A && ~rot_B)  begin deb_A<=1'b0;
                                  deb_B<=deb_B;
                            end
	else if(~rot_A && rot_B)   begin deb_A<=deb_A;
                                  deb_B<=1'b1;
                            end
	else if(rot_A &&~ rot_B)  begin deb_A<=deb_A;
                                 deb_B<=1'b0;
                           end
always@(posedge reset or posedge clk)//
	if(reset)         deb_AA<= 1'b1;
	else           deb_AA<= deb_A;   // relationship btw
                                  // deb_A and deb_AA?
always@(posedge reset or posedge clk)
if(reset) {btn00,btn11,btn22}= 3'b000;
else 
	if(SW==4'h000||SW==4'b0111)
		if(BTN0)         {btn00, btn11, btn22}<= 3'b100;
      else if(BTN1)     {btn00, btn11, btn22}<= 3'b010;
      else if(BTN2)     {btn00, btn11, btn22}<= 3'b001;
	   else if(rot_btn)  {btn00, btn11, btn22}<= 3'b000;
	   else           {btn00, btn11, btn22}<={btn00, btn11, btn22};
	else               {btn00, btn11, btn22}<= 3'b000;


always@(posedge reset or posedge clk)
	if(reset)	rot_btn<= 1'b0;
	else 
		if(SW==4'h0)
			if(rot_dwn)	rot_btn<= 1'b1;
			else if(BTN0 || BTN1 || BTN2)	rot_btn<= 1'b0;
			else	rot_btn<= rot_btn;
		else	rot_btn<= 1'b0;

assign   knob_status[1]= deb_A & ~deb_AA;  // start turning        knob_status[0]= rot_A & rot_B;     // detent position


always@(posedge reset or negedge clk)       // why using negedge of the clock??
	if(reset)   begin  LED<= 8'h00;
						  rr_set<= 1'b0;
                    rl_set<= 1'b0;
						  rr_continue<=1'b0;
						  rl_continue<=1'b0;
           end 
	else 
	 case(SW[3:0])
	 4'b0011:   LED<={4'b0000, deb_A, deb_B, rot_A, rot_B};
	 4'b0111:   LED<={5'b00000,  btn00, btn11, btn22};
	 4'b0000:
			 case({rot_btn,btn00, btn11, btn22})
			 4'b0100:                LED<= 8'h0F;
			 4'b0010:                LED<= 8'hF0;
			 4'b0001:   if(slowclk)     LED<= ~LED;
							else         LED<= LED;
			 4'b1000:                LED<= 8'hC3;
			 default:                 LED<= LED;
			 endcase
	4'b0100:
			 if(LED!=8'h0F &&LED!=8'hF0) LED<= 8'h0F;
			 else if(slowclk)  LED<= ~LED;
			 else           LED<= LED;
	4'b1000:
			 if(LED!=8'h55 && LED!=8'haa) LED<= 8'h55;
			 else if(slowclk)  LED<= ~LED;
			 else           LED<= LED;

                // one knob-click right--> one LED shifting left
	4'b0001:        // one knob-click left --> one LED shifting right               
			case({knob_status[1], deb_B})
			 2'b10: begin                
						 if(rl_continue)   
							begin  rl_continue<=1'b0;
									 LED<= 8'h11;    // purposely set
							end
						 if(~rr_set)
							begin
									 rr_continue<= 1'b1;
									 rr_set<= 1'b1; 
							 if(LED==8'h01 || LED==8'h02 || 
								 LED==8'h04 || LED==8'h08 ||
								 LED==8'h10 || LED==8'h20 || 
								 LED==8'h40 || LED==8'h80)
									  LED= {LED[0], LED[7:1]};
							 else    LED= 8'h80; 
							end
						 else begin  rr_continue<= rr_continue;
									  rr_set<= rr_set;
									  LED<= LED;
								end
					  end
			 2'b11: begin
						 if(rr_continue)    
							begin  rr_continue<=1'b0;
									 LED<= 8'h11;      //purposely set
							end
						 if(~rl_set)
							begin
									 rl_continue<=1'b1;
									 rl_set<= 1'b1; 
							  if(LED==8'h01 || LED==8'h02 || 
									  LED==8'h04 || LED==8'h08 ||
									  LED==8'h10 || LED==8'h20 || 
									  LED==8'h40 || LED==8'h80)
									  LED= {LED[6:0], LED[7]};
							  else   LED<= 8'h01; 
							end
						 else begin  rl_continue<=rl_continue;
									  rl_set<= rl_set;
									  LED<= LED;
								end
					  end
			2'b01,
			2'b00: begin     rr_set<= 1'b0;
								  rl_set<= 1'b0;
								  LED<= LED;
					 end
			 default:          begin     rr_set<= rr_set;
												rl_set<= rl_set;
												LED<= LED;
									 end
			endcase
                  // one knob-click right--> one LED shifting left
	4'b0010:          // one knob-click left --> one LED shifting right
			case({knob_status[1], deb_B})
			 2'b10: begin
						 if(rl_continue)   
							begin       rl_continue<=1'b0;
											LED<= LED;
							end              
						 if(~rr_set)
							begin
											rr_continue<=1'b1;
								  rr_set<= 1'b1; 
							 if(LED==8'h01 || LED==8'h02 || 
								 LED==8'h04 || LED==8'h08 ||
								 LED==8'h10 || LED==8'h20 || 
								 LED==8'h40 || LED==8'h80)
											LED<= {LED[0], LED[7:1]};
							 else        LED<= 8'h80; 
							end
						 else begin     rr_continue<=rr_continue;
									rr_set<= rr_set;
										  LED<= LED;
								end
					  end
			 2'b11: begin
						if(rr_continue)    
							begin  rr_continue<=1'b0;
									 LED<= LED;
							end                
						if(~rl_set)
						  begin
									 rl_continue<=1'b1;
							  rl_set<= 1'b1; 
							if(LED==8'h01 || LED==8'h02 || 
								LED==8'h04 || LED==8'h08 ||
								LED==8'h10 || LED==8'h20 || 
								LED==8'h40 || LED==8'h80)
									 LED<= {LED[6:0], LED[7]};
							else    LED<= 8'h01; 
						  end
						else begin   rl_continue<=rl_continue;
									  rl_set<= rl_set;
											 LED<= LED;
							  end
					  end
			 2'b00,
			 2'b01: begin     rr_set<= 1'b0;
									rl_set<= 1'b0;
									LED<= LED;
					  end
			 default:          begin     rr_set<= rr_set;
												rl_set<= rl_set;
												LED<= LED;
									end
       endcase

	default:   if(toggle_cnt<=8'h08)  LED<= 8'h00;
             else               LED<= 8'hFF;
 endcase


always@(posedge reset or negedge clk)
      
// why using negedge of the clock??
	if(reset)	toggle_cnt<= 8'h00;
	else  if(slowclk && toggle_cnt<8'h11)  toggle_cnt<= toggle_cnt + 8'h01;
	else if(slowclk)	toggle_cnt<= 8'h00;
	else	toggle_cnt<= toggle_cnt;

endmodule
