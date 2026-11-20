`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2026 09:58:41
// Design Name: 
// Module Name: crc_checker
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
/////////////////////////////////////////////////////////////////////////////////

module crc_checker(

    input wire       clk,
    input wire       rst,

    input wire       packet_received,

    input wire [7:0] calculated_crc,
    input wire [7:0] received_crc,

    input wire       valid_flag,

    output reg       packet_valid

);

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            packet_valid <= 1'b0;
        end

        else begin

            packet_valid <= 1'b0;

            if (packet_received) begin

                if ((calculated_crc == received_crc) &&
                    (valid_flag == 1'b1)) begin

                    packet_valid <= 1'b1;

                end

            end

        end

    end

endmodule
