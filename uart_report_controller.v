`timescale 1ns / 1ps

// ============================================================
// TERRA SENSE WORKER BAND
// UART REPORT CONTROLLER
// ============================================================
// FPGA -> ESP32
//
// ACK report:
//     55
//
// SOS report:
//     A5 | 01 | NODE_ID | RISK | SEQ | CRC
//
// SOS has priority over a pending ACK.
// ============================================================

module uart_report_controller #(
    parameter integer CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       rst,

    input  wire       ack_request,
    input  wire       sos_event,

    input  wire [7:0] latest_node_id,
    input  wire [1:0] latest_risk,
    input  wire [7:0] latest_sequence,

    output wire       uart_tx
);

    localparam [1:0] IDLE      = 2'd0;
    localparam [1:0] SEND_BYTE = 2'd1;
    localparam [1:0] WAIT_DONE = 2'd2;

    localparam [7:0] ACK_BYTE = 8'h55;
    localparam [7:0] SOS_START = 8'hA5;
    localparam [7:0] SOS_TYPE  = 8'h01;

    reg [1:0] state;

    reg       ack_pending;
    reg       sos_pending;

    reg [7:0] frame [0:5];
    reg [2:0] frame_index;
    reg [2:0] frame_length;

    reg       tx_start;
    reg [7:0] tx_data;
    wire      tx_done;

    // ------------------------------------------------------------
    // UART transmitter
    // ------------------------------------------------------------
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_tx (
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx       (uart_tx),
        .tx_done  (tx_done)
    );

    // ------------------------------------------------------------
    // CRC-8, polynomial 0x07
    // CRC covers the first five SOS bytes.
    // ------------------------------------------------------------
    function [7:0] crc8_5;
        input [7:0] b0;
        input [7:0] b1;
        input [7:0] b2;
        input [7:0] b3;
        input [7:0] b4;

        reg [7:0] crc;
        reg [7:0] data_byte;
        integer i;
        integer j;

        begin
            crc = 8'h00;

            for (i = 0; i < 5; i = i + 1) begin
                case (i)
                    0: data_byte = b0;
                    1: data_byte = b1;
                    2: data_byte = b2;
                    3: data_byte = b3;
                    4: data_byte = b4;
                    default: data_byte = 8'h00;
                endcase

                crc = crc ^ data_byte;

                for (j = 0; j < 8; j = j + 1) begin
                    if (crc[7])
                        crc = (crc << 1) ^ 8'h07;
                    else
                        crc = crc << 1;
                end
            end

            crc8_5 = crc;
        end
    endfunction

    // ------------------------------------------------------------
    // Controller
    // ------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            ack_pending <= 1'b0;
            sos_pending <= 1'b0;
            frame_index <= 3'd0;
            frame_length<= 3'd0;
            tx_start    <= 1'b0;
            tx_data     <= 8'h00;

            frame[0] <= 8'h00;
            frame[1] <= 8'h00;
            frame[2] <= 8'h00;
            frame[3] <= 8'h00;
            frame[4] <= 8'h00;
            frame[5] <= 8'h00;
        end
        else begin
            tx_start <= 1'b0;

            // Queue ACK requests. An ACK remains pending until sent.
            if (ack_request)
                ack_pending <= 1'b1;

            // Capture the SOS report at the exact event instant.
            if (sos_event) begin
                sos_pending <= 1'b1;

                frame[0] <= SOS_START;
                frame[1] <= SOS_TYPE;
                frame[2] <= latest_node_id;
                frame[3] <= {6'b000000, latest_risk};
                frame[4] <= latest_sequence;
                frame[5] <= crc8_5(
                    SOS_START,
                    SOS_TYPE,
                    latest_node_id,
                    {6'b000000, latest_risk},
                    latest_sequence
                );
            end

            case (state)
                IDLE: begin
                    // SOS has priority over ACK.
                    if (sos_pending || sos_event) begin
                        frame_index  <= 3'd0;
                        frame_length <= 3'd6;
                        sos_pending  <= 1'b0;
                        state        <= SEND_BYTE;
                    end
                    else if (ack_pending) begin
                        frame_index  <= 3'd0;
                        frame_length <= 3'd1;
                        ack_pending  <= 1'b0;
                        state        <= SEND_BYTE;
                    end
                end

                SEND_BYTE: begin
                    tx_start <= 1'b1;

                    if (frame_length == 3'd1)
                        tx_data <= ACK_BYTE;
                    else
                        tx_data <= frame[frame_index];

                    state <= WAIT_DONE;
                end

                WAIT_DONE: begin
                    if (tx_done) begin
                        if (frame_index + 1'b1 >= frame_length) begin
                            state <= IDLE;
                        end
                        else begin
                            frame_index <= frame_index + 1'b1;
                            state <= SEND_BYTE;
                        end
                    end
                end

                default: begin
                    state        <= IDLE;
                    ack_pending  <= 1'b0;
                    sos_pending  <= 1'b0;
                    frame_index  <= 3'd0;
                    frame_length <= 3'd0;
                    tx_start     <= 1'b0;
                end
            endcase
        end
    end

endmodule

