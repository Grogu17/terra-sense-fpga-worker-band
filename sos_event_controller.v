`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2026 17:43:35
// Design Name: 
// Module Name: sos_event_controller
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

// Generates a one-clock SOS event.
// sos_active remains latched for the local alarm.
// sos_event is only a pulse, so the ESP32 receives ONE SOS report per event.
module sos_event_controller(
    input  wire clk,
    input  wire rst,
    input  wire sos_button,
    input  wire packet_sos,

    output reg  sos_active,
    output reg  sos_event
);

    reg button_sync1;
    reg button_sync2;
    reg button_previous;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            button_sync1    <= 1'b0;
            button_sync2    <= 1'b0;
            button_previous <= 1'b0;
            sos_active      <= 1'b0;
            sos_event       <= 1'b0;
        end
        else begin
            button_sync1    <= sos_button;
            button_sync2    <= button_sync1;
            button_previous <= button_sync2;

            // Default: event is a one-clock pulse.
            sos_event <= 1'b0;

            // Network-generated SOS
            if (packet_sos) begin
                sos_active <= 1'b1;
                sos_event  <= 1'b1;
            end

            // Local physical SOS button rising edge
            else if (button_sync2 && !button_previous) begin
                sos_active <= 1'b1;
                sos_event  <= 1'b1;
            end
        end
    end

endmodule


