`timescale 1us/1ps
module top (
    input wire clk,
    input wire rst,
    input wire signed [31:0] angle, // angle in Q16.16 format
    output reg signed [31:0] sine,  // sine in Q16.16 format
    output reg signed [31:0] cosine // cosine in Q16.16 format
);

parameter ITERATIONS = 16;
parameter [31:0] SCALE_CIRCULAR = 39815; // Precomputed scaling factor for circular mode in Q16.16 format

// Precomputed arctan values in Q16.16 format
reg [31:0] atan_table[0:15];
initial begin
    atan_table[0] = 51472;   // arctan(2^-0)
    atan_table[1] = 30386;   // arctan(2^-1)
    atan_table[2] = 16055;   // arctan(2^-2)
    atan_table[3] = 8150;    // arctan(2^-3)
    atan_table[4] = 4091;    // arctan(2^-4)
    atan_table[5] = 2047;    // arctan(2^-5)
    atan_table[6] = 1024;    // arctan(2^-6)
    atan_table[7] = 512;     // arctan(2^-7)
    atan_table[8] = 256;     // arctan(2^-8)
    atan_table[9] = 128;     // arctan(2^-9)
    atan_table[10] = 64;     // arctan(2^-10)
    atan_table[11] = 32;     // arctan(2^-11)
    atan_table[12] = 16;     // arctan(2^-12)
    atan_table[13] = 8;      // arctan(2^-13)
    atan_table[14] = 4;      // arctan(2^-14)
    atan_table[15] = 2;      // arctan(2^-15)
end

// Pipeline registers for each stage
reg signed [31:0] x[0:ITERATIONS];
reg signed [31:0] y[0:ITERATIONS];
reg signed [31:0] z[0:ITERATIONS];
reg [1:0] quadrant[0:ITERATIONS];

// Function to reduce the angle to the range -90 to 90 degrees
function [31:0] reduce_angle;
    input signed [31:0] angle;
    reg signed [31:0] angle_reduced;
    begin
        angle_reduced = angle;
        if (angle_reduced > 205887) // > 180 degrees in Q16.16
            angle_reduced = angle_reduced - 411775; // angle - 360 degrees
        if (angle_reduced < -205887) // < -180 degrees in Q16.16
            angle_reduced = angle_reduced + 411775; // angle + 360 degrees

        // Determine quadrant
        if (angle_reduced >= 0) begin
            if (angle_reduced > 102944) begin // > 90 degrees in Q16.16
                angle_reduced = 205887 - angle_reduced; // 180 degrees - angle
                quadrant[0] = 2'b01; // 2nd quadrant
            end else begin
                quadrant[0] = 2'b00; // 1st quadrant
            end
        end else begin
            if (angle_reduced < -102944) begin // < -90 degrees in Q16.16
                angle_reduced = -205887 - angle_reduced; // -180 degrees - angle
                angle_reduced = -angle_reduced;
                quadrant[0] = 2'b10; // 3rd quadrant
            end else begin
                angle_reduced = -angle_reduced;
                quadrant[0] = 2'b11; // 4th quadrant
            end
        end
        reduce_angle = angle_reduced;
    end
endfunction

integer i;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Initialize all pipeline stages on reset
        for (i = 0; i <= ITERATIONS; i = i + 1) begin
            x[i] <= 0;
            y[i] <= 0;
            z[i] <= 0;
            quadrant[i] <= 2'b00;
        end
        sine <= 32'd0;
        cosine <= 32'd0;
    end else begin
        // Initial values for the pipeline
        x[0] <= SCALE_CIRCULAR;
        y[0] <= 32'd0;
        z[0] <= reduce_angle(angle);

        // Pipeline stages
        for (i = 0; i < ITERATIONS; i = i + 1) begin
            if (z[i][31]) begin
                x[i+1] <= x[i] + (y[i] >>> i);
                y[i+1] <= y[i] - (x[i] >>> i);
                z[i+1] <= z[i] + atan_table[i];
                quadrant[i+1] <= quadrant[i];
            end else begin
                x[i+1] <= x[i] - (y[i] >>> i);
                y[i+1] <= y[i] + (x[i] >>> i);
                z[i+1] <= z[i] - atan_table[i];
                quadrant[i+1] <= quadrant[i];
            end
        end

        // Adjusting final output based on the quadrant
        case (quadrant[ITERATIONS])
            2'b00: begin // 1st quadrant
                sine <= y[ITERATIONS];
                cosine <= x[ITERATIONS];
            end
            2'b01: begin // 2nd quadrant
                sine <= y[ITERATIONS];
                cosine <= -x[ITERATIONS];
            end
            2'b10: begin // 3rd quadrant
                sine <= -y[ITERATIONS];
                cosine <= -x[ITERATIONS];
            end
            2'b11: begin // 4th quadrant
                sine <= -y[ITERATIONS];
                cosine <= x[ITERATIONS];
            end
        endcase
    end
end

endmodule
