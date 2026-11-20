`timescale 1ns / 1ps

// ============================================================
// TERRA SENSE WORKER BAND
// COMPLETE FAULT-INJECTION + SOS LOCATION VERIFICATION
//
// TESTS
//  1. NORMAL SAFE
//  2. BAD CRC
//  3. INVALID VALID-FLAG
//  4. WARNING
//  5. CRITICAL
//  6. RETURN TO SAFE
//  7. COMMUNICATION LOSS
//  8. LOCAL SOS
//  9. SOS UART LOCATION REPORT
//
// UART INPUT TO FPGA:
//     AA | NODE_ID | RISK | VALID | SEQ | SOS | CRC
//
// UART OUTPUT FROM FPGA:
//
// Normal ACK:
//     55
//
// SOS report:
//     A5 | 01 | NODE_ID | RISK | SEQ | CRC
//
// ============================================================

module worker_band_tb;

    // ============================================================
    // SIMULATION PARAMETERS
    // ============================================================

    parameter integer CLK_FREQ  = 10_000_000;
    parameter integer BAUD_RATE = 1_000_000;

    // Short watchdog for simulation
    parameter integer WATCHDOG_TIMEOUT_CYCLES = 3000;

    // ============================================================
    // SIGNALS
    // ============================================================

    reg clk;
    reg rst;

    reg uart_rx;
    reg sos_btn;

    wire uart_tx;

    wire led_r;
    wire led_g;
    wire led_b;
    wire buzzer;

    integer errors;

    // ============================================================
    // DUT
    // ============================================================

    worker_band_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .WATCHDOG_TIMEOUT_CYCLES(WATCHDOG_TIMEOUT_CYCLES)
    )
    dut (
        .clk100mhz(clk),
        .rst(rst),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),

        .sos_btn(sos_btn),

        .led_r(led_r),
        .led_g(led_g),
        .led_b(led_b),

        .buzzer(buzzer)
    );

    // ============================================================
    // CLOCK
    //
    // 10 MHz clock
    // Period = 100 ns
    // ============================================================

    initial begin

        clk = 1'b0;

        forever
            #50 clk = ~clk;

    end

    // ============================================================
    // UART BIT
    //
    // 1 MHz UART
    // 1 bit = 1 us = 1000 ns
    // ============================================================

    task uart_bit;

        input bit_value;

        begin

            uart_rx = bit_value;

            #1000;

        end

    endtask

    // ============================================================
    // UART BYTE
    //
    // 8-N-1
    // LSB FIRST
    // ============================================================

    task uart_byte;

        input [7:0] data;

        integer i;

        begin

            // START BIT
            uart_bit(1'b0);

            // DATA BITS
            for (i = 0; i < 8; i = i + 1)
                uart_bit(data[i]);

            // STOP BIT
            uart_bit(1'b1);

        end

    endtask

    // ============================================================
    // CRC-8
    //
    // Polynomial = 0x07
    // Initial value = 0x00
    // ============================================================

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

    // ============================================================
    // SEND VALID PACKET
    //
    // AA | NODE | RISK | VALID | SEQ | SOS | CRC
    // ============================================================

    task send_packet;

        input [7:0] node;
        input [1:0] risk;
        input [7:0] seq;
        input       sos;

        reg [7:0] crc;

        begin

            crc = 8'h00;

            crc = crc8_next(crc, 8'hAA);
            crc = crc8_next(crc, node);

            crc = crc8_next(
                crc,
                {6'b000000, risk}
            );

            crc = crc8_next(crc, 8'h01);

            crc = crc8_next(crc, seq);

            crc = crc8_next(
                crc,
                {7'b0000000, sos}
            );

            // SEND PACKET

            uart_byte(8'hAA);
            uart_byte(node);
            uart_byte({6'b000000, risk});
            uart_byte(8'h01);
            uart_byte(seq);
            uart_byte({7'b0000000, sos});
            uart_byte(crc);

        end

    endtask

    // ============================================================
    // SEND PACKET WITH BAD CRC
    // ============================================================

    task send_bad_crc_packet;

        input [7:0] node;
        input [1:0] risk;
        input [7:0] seq;
        input       sos;

        reg [7:0] crc;

        begin

            crc = 8'h00;

            crc = crc8_next(crc, 8'hAA);
            crc = crc8_next(crc, node);

            crc = crc8_next(
                crc,
                {6'b000000, risk}
            );

            crc = crc8_next(crc, 8'h01);

            crc = crc8_next(crc, seq);

            crc = crc8_next(
                crc,
                {7'b0000000, sos}
            );

            uart_byte(8'hAA);
            uart_byte(node);
            uart_byte({6'b000000, risk});
            uart_byte(8'h01);
            uart_byte(seq);
            uart_byte({7'b0000000, sos});

            // DELIBERATELY WRONG CRC

            uart_byte(crc ^ 8'hFF);

        end

    endtask

    // ============================================================
    // SEND PACKET WITH VALID = 0
    // ============================================================

    task send_invalid_packet;

        input [7:0] node;
        input [1:0] risk;
        input [7:0] seq;
        input       sos;

        reg [7:0] crc;

        begin

            crc = 8'h00;

            crc = crc8_next(crc, 8'hAA);
            crc = crc8_next(crc, node);

            crc = crc8_next(
                crc,
                {6'b000000, risk}
            );

            // VALID = 0

            crc = crc8_next(crc, 8'h00);

            crc = crc8_next(crc, seq);

            crc = crc8_next(
                crc,
                {7'b0000000, sos}
            );

            uart_byte(8'hAA);
            uart_byte(node);
            uart_byte({6'b000000, risk});

            // INVALID

            uart_byte(8'h00);

            uart_byte(seq);
            uart_byte({7'b0000000, sos});
            uart_byte(crc);

        end

    endtask

    // ============================================================
    // OUTPUT CHECKER
    // ============================================================

    task check_outputs;

        input expected_r;
        input expected_g;
        input expected_b;
        input expected_buzzer;

        input [127:0] test_name;

        begin

            #1;

            if ((led_r !== expected_r) ||
                (led_g !== expected_g) ||
                (led_b !== expected_b) ||
                (buzzer !== expected_buzzer)) begin

                $display("[FAIL] %s", test_name);

                $display(
                    "       R=%b G=%b B=%b BUZZER=%b",
                    led_r,
                    led_g,
                    led_b,
                    buzzer
                );

                errors = errors + 1;

            end

            else begin

                $display("[PASS] %s", test_name);

            end

        end

    endtask

    // ============================================================
    // RECEIVE ONE UART BYTE FROM FPGA
    //
    // Used for FPGA -> ESP32 UART verification.
    //
    // 8-N-1
    // 1 MHz UART
    //
    // Wait for START BIT
    // Wait 1.5 bit times
    // Sample 8 data bits
    // ============================================================

    task uart_receive_byte;

        input first_byte;
        output [7:0] data;
        integer i;

        begin
            data = 8'h00;

            // ----------------------------------------------------
            // Always synchronize to the ACTUAL falling edge of the
            // next UART START bit. This avoids byte-boundary drift.
            // ----------------------------------------------------
            @(negedge uart_tx);

            // Move to center of START bit.
            #500;

            if (uart_tx !== 1'b0) begin
                $display("[ERROR] UART START BIT INVALID");
                errors = errors + 1;
            end

            // Move to center of DATA bit 0.
            #1000;

            // UART is LSB first.
            for (i = 0; i < 8; i = i + 1) begin
                data[i] = uart_tx;
                #1000;
            end

            // We are at center of STOP bit.
            if (uart_tx !== 1'b1) begin
                $display("[ERROR] UART STOP BIT INVALID");
                errors = errors + 1;
            end

            // Return to the end of the stop bit. The next call will
            // wait for the next actual falling START edge.
            #500;
        end

    endtask

    // ============================================================
    // CALCULATE SOS REPORT CRC
    //
    // Frame:
    //
    // A5 | 01 | NODE | RISK | SEQ | CRC
    //
    // CRC covers first 5 bytes.
    // ============================================================

    function [7:0] calculate_sos_crc;

        input [7:0] start_byte;
        input [7:0] type_byte;
        input [7:0] node_byte;
        input [7:0] risk_byte;
        input [7:0] seq_byte;

        reg [7:0] crc;

        begin

            crc = 8'h00;

            crc = crc8_next(crc, start_byte);
            crc = crc8_next(crc, type_byte);
            crc = crc8_next(crc, node_byte);
            crc = crc8_next(crc, risk_byte);
            crc = crc8_next(crc, seq_byte);

            calculate_sos_crc = crc;

        end

    endfunction

    // ============================================================
    // VERIFY SOS UART FRAME
    //
    // Expected:
    //
    // A5 | 01 | NODE | RISK | SEQ | CRC
    // ============================================================

    task check_sos_uart_frame;

        input [7:0] expected_node;
        input [1:0] expected_risk;
        input [7:0] expected_sequence;

        reg [7:0] rx_start;
        reg [7:0] rx_type;
        reg [7:0] rx_node;
        reg [7:0] rx_risk;
        reg [7:0] rx_seq;
        reg [7:0] rx_crc;

        reg [7:0] expected_crc;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("WAITING FOR FPGA SOS UART REPORT");
            $display("----------------------------------------------");

            // RECEIVE SIX BYTES

            uart_receive_byte(1'b1, rx_start);
            uart_receive_byte(1'b0, rx_type);
            uart_receive_byte(1'b0, rx_node);
            uart_receive_byte(1'b0, rx_risk);
            uart_receive_byte(1'b0, rx_seq);
            uart_receive_byte(1'b0, rx_crc);

            // CALCULATE EXPECTED CRC

            expected_crc = calculate_sos_crc(
                8'hA5,
                8'h01,
                expected_node,
                {6'b000000, expected_risk},
                expected_sequence
            );

            $display(
                "SOS FRAME RECEIVED: %02h %02h %02h %02h %02h %02h",
                rx_start,
                rx_type,
                rx_node,
                rx_risk,
                rx_seq,
                rx_crc
            );

            $display(
                "EXPECTED FRAME:     A5 01 %02h %02h %02h %02h",
                expected_node,
                {6'b000000, expected_risk},
                expected_sequence,
                expected_crc
            );

            // CHECK START BYTE

            if (rx_start !== 8'hA5) begin

                $display("[FAIL] SOS START BYTE");

                errors = errors + 1;

            end

            else begin

                $display("[PASS] SOS START BYTE");

            end

            // CHECK EVENT TYPE

            if (rx_type !== 8'h01) begin

                $display("[FAIL] SOS EVENT TYPE");

                errors = errors + 1;

            end

            else begin

                $display("[PASS] SOS EVENT TYPE");

            end

            // CHECK NODE ID

            if (rx_node !== expected_node) begin

                $display(
                    "[FAIL] SOS NODE ID: expected %02h, got %02h",
                    expected_node,
                    rx_node
                );

                errors = errors + 1;

            end

            else begin

                $display(
                    "[PASS] SOS NODE ID = %02h",
                    rx_node
                );

            end

            // CHECK RISK

            if (rx_risk !== {6'b000000, expected_risk}) begin

                $display(
                    "[FAIL] SOS RISK: expected %02h, got %02h",
                    {6'b000000, expected_risk},
                    rx_risk
                );

                errors = errors + 1;

            end

            else begin

                $display(
                    "[PASS] SOS RISK = %02h",
                    rx_risk
                );

            end

            // CHECK SEQUENCE

            if (rx_seq !== expected_sequence) begin

                $display(
                    "[FAIL] SOS SEQUENCE: expected %02h, got %02h",
                    expected_sequence,
                    rx_seq
                );

                errors = errors + 1;

            end

            else begin

                $display(
                    "[PASS] SOS SEQUENCE = %02h",
                    rx_seq
                );

            end

            // CHECK CRC

            if (rx_crc !== expected_crc) begin

                $display(
                    "[FAIL] SOS CRC: expected %02h, got %02h",
                    expected_crc,
                    rx_crc
                );

                errors = errors + 1;

            end

            else begin

                $display(
                    "[PASS] SOS CRC = %02h",
                    rx_crc
                );

            end

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        errors = 0;

        clk     = 1'b0;
        rst     = 1'b1;

        uart_rx = 1'b1;
        sos_btn = 1'b0;

        // ========================================================
        // RESET
        // ========================================================

        repeat(10)
            @(posedge clk);

        rst = 1'b0;

        repeat(20)
            @(posedge clk);

        // ========================================================
        // TEST 1
        // NORMAL SAFE
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: NORMAL SAFE PACKET");
        $display("==============================================");

        send_packet(
            8'h01,
            2'b00,
            8'h01,
            1'b0
        );

        repeat(50)
            @(posedge clk);

        check_outputs(
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            "SAFE PACKET"
        );

        // ========================================================
        // TEST 2
        // BAD CRC
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: BAD CRC");
        $display("==============================================");

        send_bad_crc_packet(
            8'h01,
            2'b11,
            8'h02,
            1'b0
        );

        repeat(50)
            @(posedge clk);

        check_outputs(
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            "BAD CRC REJECTED"
        );

        // ========================================================
        // TEST 3
        // INVALID VALID-FLAG
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 3: INVALID VALID-FLAG");
        $display("==============================================");

        send_invalid_packet(
            8'h01,
            2'b11,
            8'h03,
            1'b0
        );

        repeat(50)
            @(posedge clk);

        check_outputs(
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            "INVALID PACKET REJECTED"
        );

        // ========================================================
        // TEST 4
        // WARNING
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 4: WARNING");
        $display("==============================================");

        send_packet(
            8'h01,
            2'b10,
            8'h04,
            1'b0
        );

        repeat(50)
            @(posedge clk);

        check_outputs(
            1'b1,
            1'b1,
            1'b0,
            1'b0,
            "WARNING"
        );

        // ========================================================
        // TEST 5
        // CRITICAL
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 5: CRITICAL");
        $display("==============================================");

        send_packet(
            8'h01,
            2'b11,
            8'h05,
            1'b0
        );

        repeat(50)
            @(posedge clk);

        check_outputs(
            1'b1,
            1'b0,
            1'b0,
            1'b1,
            "CRITICAL"
        );

        // ========================================================
        // TEST 6
        // RETURN TO SAFE
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 6: RETURN TO SAFE");
        $display("==============================================");

        send_packet(
            8'h01,
            2'b00,
            8'h06,
            1'b0
        );

        repeat(50)
            @(posedge clk);

        check_outputs(
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            "SAFE AGAIN"
        );

        // ========================================================
        // TEST 7
        // COMMUNICATION LOSS
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 7: COMMUNICATION LOSS");
        $display("==============================================");

        repeat(WATCHDOG_TIMEOUT_CYCLES + 100)
            @(posedge clk);

        check_outputs(
            1'b1,
            1'b0,
            1'b0,
            1'b1,
            "COMMUNICATION LOSS"
        );

        // ========================================================
        // TEST 8
        // LOCAL SOS
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 8: LOCAL SOS");
        $display("==============================================");

        sos_btn = 1'b1;

        repeat(10)
            @(posedge clk);

        sos_btn = 1'b0;

        repeat(10)
            @(posedge clk);

        check_outputs(
            1'b1,
            1'b0,
            1'b1,
            1'b1,
            "LOCAL SOS"
        );

        // ========================================================
        // RESET AFTER LOCAL SOS
        //
        // SOS is intentionally latched, so reset is required
        // before starting TEST 9.
        // ========================================================

        $display("");
        $display("RESETTING AFTER LOCAL SOS");

        rst = 1'b1;

        repeat(10)
            @(posedge clk);

        rst = 1'b0;

        repeat(20)
            @(posedge clk);

        // ========================================================
        // TEST 9
        // SOS LOCATION UART REPORT
        //
        // Establish latest VALID context:
        //
        // NODE = 02
        // RISK = CRITICAL = 11
        // SEQ  = 07
        //
        // Then press physical SOS.
        //
        // Expected FPGA TX:
        //
        // A5 01 02 03 07 CRC
        // ========================================================

        $display("");
        $display("==============================================");
        $display("TEST 9: SOS UART LOCATION REPORT");
        $display("==============================================");

        $display("");
        $display("Sending VALID NODE 2 / CRITICAL packet...");

        send_packet(
            8'h02,
            2'b11,
            8'h07,
            1'b0
        );

        // Allow packet parser/CRC/FSM to process

        repeat(50)
            @(posedge clk);

        // Allow normal ACK 0x55 to finish.
        //
        // At 1 MHz UART:
        // 10 bits x 1 us = 10 us.
        //

        #15000;

        // Verify worker is in CRITICAL state

        check_outputs(
            1'b1,
            1'b0,
            1'b0,
            1'b1,
            "NODE 2 CRITICAL BEFORE SOS"
        );

        // ========================================================
        // PRESS SOS BUTTON
        // ========================================================

        $display("");
        $display("PRESSING LOCAL SOS BUTTON...");

        // IMPORTANT:
        // Start the UART receiver BEFORE the SOS transmitter can
        // generate the first falling edge.  This prevents the
        // testbench from entering the middle of the first A5 byte.
        //
        // The button is released in parallel while the UART frame
        // is being received.

        fork

            begin
                sos_btn = 1'b1;

                repeat(10)
                    @(posedge clk);

                sos_btn = 1'b0;
            end

            begin
                // Receive complete FPGA SOS report.
                check_sos_uart_frame(
                    8'h02,     // NODE 2
                    2'b11,     // CRITICAL
                    8'h07      // SEQUENCE 7
                );
            end

        join

        // ========================================================
        // VERIFY LOCAL SOS AFTER UART REPORT
        // ========================================================

        check_outputs(
            1'b1,
            1'b0,
            1'b1,
            1'b1,
            "LOCAL SOS ACTIVE"
        );

        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("==============================================");
        $display("       TERRA SENSE WORKER BAND");
        $display("       COMPLETE VERIFICATION");
        $display("==============================================");

        if (errors == 0) begin

            $display("");
            $display("       ALL TESTS PASSED");
            $display("");
            $display("       9 / 9 TESTS PASSED");
            $display("");
            $display("       SOS LOCATION REPORT VERIFIED");
            $display("       NODE ID VERIFIED");
            $display("       RISK LEVEL VERIFIED");
            $display("       SEQUENCE VERIFIED");
            $display("       CRC VERIFIED");
            $display("");

        end

        else begin

            $display("");
            $display(
                "       TEST FAILED - ERRORS = %0d",
                errors
            );
            $display("");

        end

        $display("==============================================");

        #5000;

        $finish;

    end

endmodule
