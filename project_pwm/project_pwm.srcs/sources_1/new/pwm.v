`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2024 22:36:35
// Design Name: 
// Module Name: pwm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pwm(
    input clk, rst,
    output reg dout
    );
    parameter period=100;
    integer count=0;
    integer ton=0;
    reg ncyc=1'b0;
    reg direction=1'b1;
    always @(posedge clk) begin 
           if(rst) begin 
            ncyc<=1'b0;
            count<=0;
            ton<=0;
           end
           else begin if(count<=ton) begin
             ncyc<=1'b0;
             count<=count+1;
             dout<=1'b1;
             end
           else if(count<period) begin
             ncyc<=1'b0;
             dout<=1'b0;
             count<=count+1;
            end
           else begin 
             ncyc<=1'b1;
             count<=0;
             //count<=count-1;
           end
           end
            
    end
    
    always @(posedge clk) begin 
             if(!rst) begin 
                if(ncyc==1'b1)begin
                    if(direction==1'b1) begin
                    if(ton<period)
                        ton<=ton+5;
                    
                    else
                        direction<=1'b0;
                  end
                    else if(direction==1'b0) begin
                      if(ton>0)
                        ton<=ton-5;
                    
                    else
                        direction<=1'b1;
                     end
                        
                        end

             end
                 end
endmodule
