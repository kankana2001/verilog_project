`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2024 21:29:36
// Design Name: 
// Module Name: spi
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


module spi(
    input clk, start,
    input [11:0] din,
    output reg cs,
    output reg mosi, done,
    output sclk
    );
    integer count=0;
    reg sclkt=0;
    always @(posedge clk) begin
        if(count<10)
        count<=count+1;
        else
        begin 
        count<=0;
        sclkt=~sclkt;
        end
        end
        ///////////////FSM logic
        parameter idle=0, start_tx=1, send=2, end_tx=3;
        reg [1:0] state=idle;
        reg [11:0] temp;
        integer bitCount=0;
        always @(posedge sclkt) begin
        case(state)
        idle: begin 
               mosi<=1'b0;
               done<=1'b0;
               cs<=1'b1; 
               if(start) begin 
                    state<=start_tx;
                    end
               else state<=idle;
              end
        start_tx: begin 
                    cs<=0;
                    state<=send;
                    temp<=din;
                  end
        send: begin 
                if(bitCount<=11) begin
                        bitCount<=bitCount+1;
                        state<=send;
                        mosi<=temp[bitCount];
                 end
                 else begin
                    bitCount<=0;
                    state<=end_tx;
                    mosi<=1'b0;
                    end
        
                    end
        end_tx: begin 
                   done<=1'b1;
                   cs<=1'b1;
                   state<=idle; 
                 end
        default: state<=idle;
        endcase
        end
        assign sclk=sclkt;
endmodule
