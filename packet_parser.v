`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2026 09:57:25
// Design Name: 
// Module Name: packet_parser
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

module packet_parser(
    input wire       clk,
    input wire       rst,

    input wire [7:0] rx_data,
    input wire       rx_done,

    output reg       packet_received,

    output reg [7:0] node_id,
    output reg [1:0] risk_level,
    output reg       valid_flag,
    output reg [7:0] sequence_number,
    output reg       sos_request,

    output reg [7:0] calculated_crc,
    output reg [7:0] received_crc
);

    localparam WAIT_START = 3'd0;
    localparam NODE       = 3'd1;
    localparam RISK       = 3'd2;
    localparam VALID      = 3'd3;
    localparam SEQUENCE   = 3'd4;
    localparam SOS        = 3'd5;
    localparam CRC        = 3'd6;

    reg [2:0] state;

    reg [7:0] crc_reg;

    // ------------------------------------------------------------
    // CRC-8
    // Polynomial = x^8 + x^2 + x + 1
    // Polynomial value = 0x07
    // ------------------------------------------------------------

    function [7:0] crc8_next;

        input [7:0] crc;
        input [7:0] data;

        integer i;
        reg [7:0] c;

        begin

            c = crc ^ data;

            for (i = 0; i < 8; i = i + 1) begin

                if (c[7])
                    c = (c << 1) ^ 8'h07;
                else
                    c = c << 1;

            end

            crc8_next = c;

        end

    endfunction

    // ------------------------------------------------------------
    // Parser
    // ------------------------------------------------------------

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state           <= WAIT_START;

            crc_reg         <= 8'h00;

            node_id         <= 8'h00;
            risk_level      <= 2'b00;
            valid_flag      <= 1'b0;
            sequence_number <= 8'h00;
            sos_request     <= 1'b0;

            calculated_crc  <= 8'h00;
            received_crc    <= 8'h00;

            packet_received <= 1'b0;

        end

        else begin

            packet_received <= 1'b0;

            if (rx_done) begin

                case (state)

                    // ------------------------------------------------
                    // START
                    // ------------------------------------------------

                    WAIT_START: begin

                        if (rx_data == 8'hAA) begin

                            crc_reg <= crc8_next(
                                8'h00,
                                rx_data
                            );

                            state <= NODE;

                        end

                    end

                    // ------------------------------------------------
                    // NODE ID
                    // ------------------------------------------------

                    NODE: begin

                        node_id <= rx_data;

                        crc_reg <= crc8_next(
                            crc_reg,
                            rx_data
                        );

                        state <= RISK;

                    end

                    // ------------------------------------------------
                    // RISK
                    // ------------------------------------------------

                    RISK: begin

                        risk_level <= rx_data[1:0];

                        crc_reg <= crc8_next(
                            crc_reg,
                            rx_data
                        );

                        state <= VALID;

                    end

                    // ------------------------------------------------
                    // VALID
                    // ------------------------------------------------

                    VALID: begin

                        valid_flag <= (rx_data == 8'h01);

                        crc_reg <= crc8_next(
                            crc_reg,
                            rx_data
                        );

                        state <= SEQUENCE;

                    end

                    // ------------------------------------------------
                    // SEQUENCE
                    // ------------------------------------------------

                    SEQUENCE: begin

                        sequence_number <= rx_data;

                        crc_reg <= crc8_next(
                            crc_reg,
                            rx_data
                        );

                        state <= SOS;

                    end

                    // ------------------------------------------------
                    // SOS
                    // ------------------------------------------------

                    SOS: begin

                        sos_request <= rx_data[0];

                        crc_reg <= crc8_next(
                            crc_reg,
                            rx_data
                        );

                        state <= CRC;

                    end

                    // ------------------------------------------------
                    // CRC
                    // ------------------------------------------------

                    CRC: begin

                        received_crc   <= rx_data;
                        calculated_crc <= crc_reg;

                        packet_received <= 1'b1;

                        state <= WAIT_START;

                    end

                    default: begin
                        state <= WAIT_START;
                    end

                endcase

            end
        end

    end

endmodule
