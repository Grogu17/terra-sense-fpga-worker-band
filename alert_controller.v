`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2026 10:10:15
// Design Name: 
// Module Name: alert_controller
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

module alert_controller(

    input wire [2:0] state,

    output reg led_r,
    output reg led_g,
    output reg led_b,

    output reg buzzer

);

    localparam SAFE      = 3'd0;
    localparam WATCH     = 3'd1;
    localparam WARNING   = 3'd2;
    localparam CRITICAL  = 3'd3;
    localparam COMM_LOSS = 3'd4;
    localparam SOS       = 3'd5;

    always @(*) begin

        led_r  = 1'b0;
        led_g  = 1'b0;
        led_b  = 1'b0;
        buzzer = 1'b0;

        case (state)

            SAFE: begin
                led_g = 1'b1;
            end

            WATCH: begin
                led_r = 1'b1;
                led_g = 1'b1;
            end

            WARNING: begin
                led_r = 1'b1;
                led_g = 1'b1;
            end

            CRITICAL: begin
                led_r  = 1'b1;
                buzzer = 1'b1;
            end

            COMM_LOSS: begin
                led_r  = 1'b1;
                buzzer = 1'b1;
            end

            SOS: begin
                led_r  = 1'b1;
                led_b  = 1'b1;
                buzzer = 1'b1;
            end

            default: begin
                led_r  = 1'b1;
                buzzer = 1'b1;
            end

        endcase

    end

endmodule
