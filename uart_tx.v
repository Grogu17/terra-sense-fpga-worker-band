`timescale 1ns / 1ps

// ============================================================
// TERRA SENSE WORKER BAND
// UART TRANSMITTER
// ============================================================
// 8-N-1, LSB first
// ============================================================

module uart_tx #(
    parameter integer CLKS_PER_BIT = 1736
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx,
    output reg        tx_done
);

    localparam [2:0] IDLE  = 3'd0;
    localparam [2:0] START = 3'd1;
    localparam [2:0] DATA  = 3'd2;
    localparam [2:0] STOP  = 3'd3;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_count;
    reg [7:0]  data_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= 16'd0;
            bit_count <= 3'd0;
            data_reg  <= 8'h00;
            tx        <= 1'b1;
            tx_done   <= 1'b0;
        end
        else begin
            tx_done <= 1'b0;

            case (state)
                IDLE: begin
                    tx        <= 1'b1;
                    clk_count <= 16'd0;
                    bit_count <= 3'd0;

                    if (tx_start) begin
                        data_reg <= tx_data;
                        state    <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        state     <= DATA;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    tx <= data_reg[bit_count];

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;

                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            state     <= STOP;
                        end
                        else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    tx <= 1'b1;

                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        tx_done   <= 1'b1;
                        state     <= IDLE;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state     <= IDLE;
                    clk_count <= 16'd0;
                    bit_count <= 3'd0;
                    tx        <= 1'b1;
                    tx_done   <= 1'b0;
                end
            endcase
        end
    end

endmodule

