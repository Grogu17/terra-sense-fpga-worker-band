`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2026 10:11:44
// Design Name: 
// Module Name: sos_controller
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

module sos_controller(

    input wire clk,
    input wire rst,

    input wire sos_button,
    input wire packet_sos,

    output reg sos_active

);

    reg button_sync1;
    reg button_sync2;

    reg button_previous;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            button_sync1  <= 1'b0;
            button_sync2  <= 1'b0;
            button_previous <= 1'b0;

            sos_active <= 1'b0;

        end

        else begin

            // Synchronize physical button
            button_sync1 <= sos_button;
            button_sync2 <= button_sync1;

            // Remember previous state
            button_previous <= button_sync2;

            // Latch SOS
            if (packet_sos)
                sos_active <= 1'b1;

            else if (button_sync2 && !button_previous)
                sos_active <= 1'b1;

        end

    end

endmodule
