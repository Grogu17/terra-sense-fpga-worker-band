`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2026 10:01:40
// Design Name: 
// Module Name: safety_fsm
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
module safety_fsm(

    input wire       clk,
    input wire       rst,

    input wire       packet_valid,
    input wire [1:0] risk_level,

    input wire       comm_timeout,
    input wire       sos_active,

    output reg [2:0] state

);

    localparam SAFE      = 3'd0;
    localparam WATCH     = 3'd1;
    localparam WARNING   = 3'd2;
    localparam CRITICAL  = 3'd3;
    localparam COMM_LOSS = 3'd4;
    localparam SOS       = 3'd5;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            state <= COMM_LOSS;
        end

        else if (sos_active) begin
            state <= SOS;
        end

        else if (comm_timeout) begin
            state <= COMM_LOSS;
        end

        else if (packet_valid) begin

            case (risk_level)

                2'b00:
                    state <= SAFE;

                2'b01:
                    state <= WATCH;

                2'b10:
                    state <= WARNING;

                2'b11:
                    state <= CRITICAL;

                default:
                    state <= COMM_LOSS;

            endcase

        end

    end

endmodule

