`timescale 1ns / 1ps

module uart_rx #(
    parameter integer CLKS_PER_BIT = 1736
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,

    output reg [7:0]  rx_data,
    output reg        rx_done
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0] state;

    reg [15:0] clk_count;
    reg [2:0]  bit_count;
    reg [7:0]  data_reg;

    // Synchronizer
    reg rx_sync1;
    reg rx_sync2;

    // ------------------------------------------------------------
    // RX synchronizer
    // ------------------------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end
        else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    // ------------------------------------------------------------
    // UART receiver
    // 8-N-1, LSB first
    // ------------------------------------------------------------

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            state     <= IDLE;
            clk_count <= 16'd0;
            bit_count <= 3'd0;
            data_reg  <= 8'd0;

            rx_data   <= 8'd0;
            rx_done   <= 1'b0;
        end

        else begin

            rx_done <= 1'b0;

            case (state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------

                IDLE: begin

                    clk_count <= 16'd0;
                    bit_count <= 3'd0;

                    if (rx_sync2 == 1'b0)
                        state <= START;

                end

                // ------------------------------------------------
                // START BIT
                // Sample middle of start bit
                // ------------------------------------------------

                START: begin

                    if (clk_count == (CLKS_PER_BIT / 2) - 1) begin

                        clk_count <= 16'd0;

                        if (rx_sync2 == 1'b0)
                            state <= DATA;
                        else
                            state <= IDLE;

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end

                // ------------------------------------------------
                // DATA BITS
                // ------------------------------------------------

                DATA: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 16'd0;

                        data_reg[bit_count] <= rx_sync2;

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

                // ------------------------------------------------
                // STOP BIT
                // ------------------------------------------------

                STOP: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 16'd0;

                        // Stop bit must be HIGH
                        if (rx_sync2 == 1'b1) begin
                            rx_data <= data_reg;
                            rx_done <= 1'b1;
                        end

                        state <= IDLE;

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end

                default: begin
                    state     <= IDLE;
                    clk_count <= 16'd0;
                    bit_count <= 3'd0;
                end

            endcase

        end
    end

endmodule

