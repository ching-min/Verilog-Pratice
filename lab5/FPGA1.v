`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:33:19 12/11/2014 
// Design Name: 
// Module Name:    FPGA1 
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
module FPGA1(SW,clk,LED
    );
input [3:0] SW;
input clk;
output reg [7:0] LED;
reg      [23:0]    cnt24;         // why 24bit in length?
reg      [7:0]  toggle_cnt;
always@(posedge clk)
   if(cnt24<24'ha00000) cnt24<= cnt24+24'h000001;
   else               cnt24<= 24'h000000;
assign  slowclk= (cnt24==24'ha00000)?  1'b1 : 1'b0;
always@(negedge clk)       // why using negedge of the clock??
 case({slowclk, SW[3:0]})
  5'b00001,
  5'b00010,
  5'b00100,
  5'b01000:         LED<= LED;
  5'b10001:         LED<= 8'h01;
  5'b10010:  if(LED==8'h01 || LED==8'h02 || 
                LED==8'h04 || LED==8'h08 ||
                LED==8'h10 || LED==8'h20 || 
                LED==8'h40 || LED==8'h80)
                   LED<= {LED[6:0], 1'b0};
             else   LED<= 8'h01;
  5'b10100:  if(LED==8'h01 || LED==8'h02 || 
                LED==8'h04 || LED==8'h08 ||
                LED==8'h10 || LED==8'h20 || 
                LED==8'h40 || LED==8'h80)
                   LED<= {1'b0, LED[7:1]};
             else   LED<= 8'h80;
  5'b11000:  if(toggle_cnt<8'h08)   LED<= 8'h55;
             else               LED<= 8'haa;
  default:                       LED<= 8'h00;
 endcase

always@(negedge clk)      // why using negedge of the clock??
if(slowclk && toggle_cnt<8'h11)  toggle_cnt<= toggle_cnt + 8'h01;
else if(slowclk)                toggle_cnt<= 8'h00;
else                         toggle_cnt<= toggle_cnt;


endmodule
