`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2026 10:00:40
// Design Name: 
// Module Name: watchdog
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

module watchdog #(
    parameter integer TIMEOUT_CYCLES = 100_000_000
)(
    input wire clk,
    input wire rst,

    input wire refresh,

    output reg timeout
);

    localparam integer COUNT_WIDTH =
        (TIMEOUT_CYCLES <= 1) ?
        1 :
        $clog2(TIMEOUT_CYCLES);

    reg [COUNT_WIDTH-1:0] count;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            count   <= 0;
            timeout <= 1'b1;

        end

        else if (refresh) begin

            count   <= 0;
            timeout <= 1'b0;

        end

        else if (count >= TIMEOUT_CYCLES - 1) begin

            count   <= TIMEOUT_CYCLES - 1;
            timeout <= 1'b1;

        end

        else begin

            count   <= count + 1'b1;
            timeout <= 1'b0;

        end

    end

endmodule

