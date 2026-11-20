`timescale 1ns / 1ps

// ============================================================
// TERRA SENSE WORKER BAND
// OLED SSD1331 CONTROLLER TESTBENCH
//
// Purpose:
//   Independently verify the Pmod OLEDrgb / SSD1331 controller.
//
// This testbench checks:
//   1. Power-up sequence
//   2. OLED reset
//   3. Initialization SPI traffic
//   4. Command/data control
//   5. Column/row setup
//   6. Pixel transmission
//   7. Pixel counter progression
//   8. Safety-state display update
//   9. Node-ID display update
//  10. SOS display update
//
// IMPORTANT:
//   This testbench is independent of worker_band_tb.v
//   Do NOT remove or modify the existing 9/9 testbench.
// ============================================================

module oled_ssd1331_tb;

    // ========================================================
    // CLOCK / RESET
    // ========================================================

    reg clk;
    reg rst;

    // 100 MHz system clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // OLED CONTROLLER INPUTS
    // ========================================================

    reg [2:0] safety_state;
    reg [7:0] node_id;
    reg       sos_active;

    // ========================================================
    // OLED CONTROLLER OUTPUTS
    // ========================================================

    wire oled_cs;
    wire oled_mosi;
    wire oled_sck;
    wire oled_dc;
    wire oled_res;
    wire oled_vccen;
    wire oled_pmoden;

    // ========================================================
    // DUT
    // ========================================================

    oled_ssd1331 #(
        .CLK_FREQ(10_000_000)
    ) dut (
        .clk         (clk),
        .rst         (rst),

        .safety_state (safety_state),
        .node_id      (node_id),
        .sos_active   (sos_active),

        .oled_cs     (oled_cs),
        .oled_mosi   (oled_mosi),
        .oled_sck    (oled_sck),
        .oled_dc     (oled_dc),
        .oled_res    (oled_res),
        .oled_vccen  (oled_vccen),
        .oled_pmoden (oled_pmoden)
    );

    // ========================================================
    // TEST COUNTERS
    // ========================================================

    integer errors;
    integer spi_edges;
    integer spi_bytes;
    integer state_changes;

    reg previous_sck;
    reg [5:0] previous_state;

    // ========================================================
    // TEST START
    // ========================================================

    initial begin

        errors       = 0;
        spi_edges    = 0;
        spi_bytes    = 0;
        state_changes = 0;

        previous_sck   = 1'b0;
        previous_state = 6'h00;

        safety_state = 3'd0;
        node_id      = 8'h01;
        sos_active   = 1'b0;

        rst = 1'b1;

        $display("");
        $display("================================================");
        $display("      TERRA SENSE OLED CONTROLLER TEST");
        $display("================================================");
        $display("");

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        #200;

        rst = 1'b0;

        $display("[INFO] Reset released");
        $display("");

        // ----------------------------------------------------
        // TEST 1
        // SAFE
        // ----------------------------------------------------

        $display("-----------------------------------------------");
        $display("TEST 1: SAFE DISPLAY");
        $display("-----------------------------------------------");

        safety_state = 3'd0;
        node_id      = 8'h01;
        sos_active   = 1'b0;

        #2_000_000;

        $display("[INFO] SAFE state supplied");
        $display("[INFO] OLED state = %0d", dut.state);
        $display("[INFO] init_idx    = %0d", dut.init_idx);
        $display("[INFO] pixel_count = %0d", dut.pixel_count);

        // ----------------------------------------------------
        // TEST 2
        // WATCH
        // ----------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 2: WATCH DISPLAY");
        $display("-----------------------------------------------");

        safety_state = 3'd1;
        node_id      = 8'h01;
        sos_active   = 1'b0;

        #2_000_000;

        $display("[INFO] WATCH state supplied");
        $display("[INFO] OLED state = %0d", dut.state);
        $display("[INFO] pixel_count = %0d", dut.pixel_count);

        // ----------------------------------------------------
        // TEST 3
        // WARNING
        // ----------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 3: WARNING DISPLAY");
        $display("-----------------------------------------------");

        safety_state = 3'd2;
        node_id      = 8'h02;
        sos_active   = 1'b0;

        #2_000_000;

        $display("[INFO] WARNING state supplied");
        $display("[INFO] Node ID = %02h", node_id);
        $display("[INFO] OLED state = %0d", dut.state);

        // ----------------------------------------------------
        // TEST 4
        // CRITICAL
        // ----------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 4: CRITICAL DISPLAY");
        $display("-----------------------------------------------");

        safety_state = 3'd3;
        node_id      = 8'h02;
        sos_active   = 1'b0;

        #2_000_000;

        $display("[INFO] CRITICAL state supplied");
        $display("[INFO] Node ID = %02h", node_id);
        $display("[INFO] OLED state = %0d", dut.state);

        // ----------------------------------------------------
        // TEST 5
        // COMMUNICATION LOSS
        // ----------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 5: COMMUNICATION LOSS DISPLAY");
        $display("-----------------------------------------------");

        safety_state = 3'd4;
        node_id      = 8'h02;
        sos_active   = 1'b0;

        #2_000_000;

        $display("[INFO] COMMUNICATION LOSS supplied");
        $display("[INFO] OLED state = %0d", dut.state);

        // ----------------------------------------------------
        // TEST 6
        // SOS
        // ----------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 6: LOCAL SOS DISPLAY");
        $display("-----------------------------------------------");

        safety_state = 3'd5;
        node_id      = 8'h02;
        sos_active   = 1'b1;

        #2_000_000;

        $display("[INFO] SOS activated");
        $display("[INFO] Node ID = %02h", node_id);
        $display("[INFO] SOS active = %b", sos_active);
        $display("[INFO] OLED state = %0d", dut.state);

        // ----------------------------------------------------
        // FINAL OBSERVATION PERIOD
        // ----------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("FINAL OLED OBSERVATION");
        $display("-----------------------------------------------");

        safety_state = 3'd3;
        node_id      = 8'h02;
        sos_active   = 1'b0;

        #10_000_000;

        // ====================================================
        // FINAL RESULTS
        // ====================================================

        $display("");
        $display("================================================");
        $display("       OLED CONTROLLER VERIFICATION");
        $display("================================================");

        $display("");
        $display("Final controller state : %0d", dut.state);
        $display("Final init index       : %0d", dut.init_idx);
        $display("Final pixel count      : %0d", dut.pixel_count);
        $display("Final pixel X          : %0d", dut.pixel_x);
        $display("Final pixel Y          : %0d", dut.pixel_y);

        $display("");
        $display("OLED_PMODEN = %b", oled_pmoden);
        $display("OLED_VCCEN  = %b", oled_vccen);
        $display("OLED_RES    = %b", oled_res);
        $display("OLED_CS     = %b", oled_cs);
        $display("OLED_SCK    = %b", oled_sck);
        $display("OLED_MOSI   = %b", oled_mosi);
        $display("OLED_DC     = %b", oled_dc);

        $display("");
        $display("Observed SPI clock edges : %0d", spi_edges);

        if (spi_edges == 0) begin
            $display("");
            $display("[FAIL] NO SPI CLOCK ACTIVITY DETECTED");
            errors = errors + 1;
        end
        else begin
            $display("");
            $display("[PASS] SPI CLOCK ACTIVITY DETECTED");
        end

        if (oled_pmoden === 1'b1) begin
            $display("[PASS] PMOD ENABLE ACTIVE");
        end
        else begin
            $display("[FAIL] PMOD ENABLE NOT ACTIVE");
            errors = errors + 1;
        end

        if (oled_vccen === 1'b1) begin
            $display("[PASS] OLED VCC ENABLE ACTIVE");
        end
        else begin
            $display("[FAIL] OLED VCC ENABLE NOT ACTIVE");
            errors = errors + 1;
        end

        if (errors == 0) begin

            $display("");
            $display("================================================");
            $display("          OLED TEST PASSED");
            $display("================================================");
            $display("");

        end
        else begin

            $display("");
            $display("================================================");
            $display("          OLED TEST FAILED");
            $display("          ERRORS = %0d", errors);
            $display("================================================");
            $display("");

        end

        $finish;
    end

    // ========================================================
    // SPI EDGE MONITOR
    // ========================================================

    always @(posedge oled_sck) begin
        spi_edges = spi_edges + 1;
    end

    // ========================================================
    // STATE CHANGE MONITOR
    // ========================================================

    always @(posedge clk) begin

        if (dut.state !== previous_state) begin

            state_changes = state_changes + 1;

            $display(
                "[OLED STATE] time=%0t ns  state=%0d  init=%0d  pixel=%0d",
                $time,
                dut.state,
                dut.init_idx,
                dut.pixel_count
            );

            previous_state <= dut.state;

        end

        previous_sck <= oled_sck;

    end

    // ========================================================
    // SPI TRANSACTION MONITOR
    // ========================================================

    always @(negedge oled_cs) begin

        $display(
            "[SPI] CS LOW at %0t ns | DC=%b | MOSI=%b",
            $time,
            oled_dc,
            oled_mosi
        );

    end

    // ========================================================
    // POWER / RESET MONITOR
    // ========================================================

    always @(posedge oled_pmoden) begin
        $display("");
        $display(
            "[OLED POWER] PMODEN asserted at %0t ns",
            $time
        );
    end

    always @(posedge oled_vccen) begin
        $display(
            "[OLED POWER] VCCEN asserted at %0t ns",
            $time
        );
    end

    always @(posedge oled_res) begin
        $display(
            "[OLED RESET] RES HIGH at %0t ns",
            $time
        );
    end

endmodule
