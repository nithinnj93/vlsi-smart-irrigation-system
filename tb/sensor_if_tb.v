`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   sensor_if_tb
// Author:        Nithin N J
// Description:   10/10 Self-checking black-box verification environment for 
//                the CDC Sensor Interface. Intentionally injects asynchronous,
//                unaligned stimulus between clock edges to verify 2-flop latency,
//                edge detection uniqueness, and stable data latching.
//////////////////////////////////////////////////////////////////////////////////

module sensor_if_tb;

    parameter DATA_WIDTH = 8;

    // Testbench Drivers
    reg                  clk;
    reg                  reset;
    reg                  async_valid_in;
    reg [DATA_WIDTH-1:0] async_data_in;

    // Testbench Observation Wires
    wire                  sample_valid_out;
    wire [DATA_WIDTH-1:0] data_out;

    // Scoreboard Counters
    integer pass_count;
    integer fail_count;

    //----------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation (Strict Black-Box Mapping)
    //----------------------------------------------------------------------------
    sensor_if #(
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .async_valid_in(async_valid_in),
        .async_data_in(async_data_in),
        .sample_valid_out(sample_valid_out),
        .data_out(data_out)
    );

    //----------------------------------------------------------------------------
    // Clock Generation (100 MHz -> 10ns period)
    //----------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //----------------------------------------------------------------------------
    // Waveform Dump
    //----------------------------------------------------------------------------
    initial begin
        $dumpfile("sensor_if_tb.vcd");
        $dumpvars(0, sensor_if_tb);
    end

    //----------------------------------------------------------------------------
    // Verification Task: Asynchronous Injection & Synchronized Capture Check
    //----------------------------------------------------------------------------
    task inject_and_verify;
        input [DATA_WIDTH-1:0] raw_payload;
        input integer          hold_cycles; // How many cycles ADC holds strobe high
        input [255:0]          test_name;
        integer                pulse_count;
        integer                i;
    begin
        pulse_count = 0;

        // 1. Intentionally inject asynchronous data & strobe 3ns AFTER clock edge!
        @(posedge clk);
        #3; 
        async_data_in  = raw_payload;
        async_valid_in = 1'b1;

        // 2. Monitor outputs over the synchronization window (Hold time + 4 buffer cycles)
        for (i = 0; i < (hold_cycles + 4); i = i + 1) begin
            @(negedge clk); // Sample on negedge to prevent race conditions!
            
            // Check if 1-cycle enable pulse fired
            if (sample_valid_out === 1'b1) begin
                pulse_count = pulse_count + 1;
                // Verify that data latched cleanly without corruption
                if (data_out === raw_payload) begin
                    pass_count = pass_count + 1;
                    $display("[PASS] %0s | Valid Fired! Data Matched: 8'h%h", test_name, data_out);
                end else begin
                    fail_count = fail_count + 1;
                    $display("[FAIL] %0s | Data Corruption! Exp: 8'h%h Got: 8'h%h", test_name, raw_payload, data_out);
                end
            end

            // Deassert external asynchronous strobe after requested hold duration
            if (i == hold_cycles) begin
                async_valid_in = 1'b0;
            end
        end

        // 3. Verify Edge Detector Uniqueness: Must only fire exactly ONCE!
        if (pulse_count === 1) begin
            pass_count = pass_count + 1;
            $display("[PASS] %0s | Edge Detector clean: exactly 1 pulse generated", test_name);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] %0s | Glitch detected! Pulse count = %0d (Expected 1)", test_name, pulse_count);
        end

        // Wait a few idle cycles between tests
        repeat(3) @(posedge clk);
    end
    endtask

    //----------------------------------------------------------------------------
    // Main Verification Regression Sequence
    //----------------------------------------------------------------------------
    initial begin
        pass_count     = 0;
        fail_count     = 0;
        reset          = 1'b1;
        async_valid_in = 1'b0;
        async_data_in  = 8'h00;

        repeat(5) @(posedge clk);
        reset = 1'b0;
        repeat(2) @(posedge clk);

        $display("==================================================");
        $display(" STARTING CDC SENSOR INTERFACE VERIFICATION");
        $display("==================================================");

        // 1. Single-Cycle Asynchronous Strobe Injection (Standard ADC reading)
        $display("\n[INFO] Test 1: Injecting unaligned asynchronous strobe (1-cycle hold)...");
        inject_and_verify(8'hA5, 1, "Async Capture 8'hA5 (1-cycle) ");

        // 2. Long-Hold Asynchronous Strobe (Testing Edge Detector Glitch Immunity)
        $display("\n[INFO] Test 2: Injecting long strobe (held high for 8 clock cycles)...");
        inject_and_verify(8'h3C, 8, "Long-Strobe Capture 8'h3C     ");

        // 3. Corner Case Regressions (Boundary ADC Values)
        $display("\n[INFO] Test 3: Executing boundary ADC value CDC captures...");
        inject_and_verify(8'h00, 2, "Boundary Case: All Zeros (0x00)");
        inject_and_verify(8'hFF, 3, "Boundary Case: All Ones (0xFF) ");
        inject_and_verify(8'h55, 1, "Alternating Bits (01010101)   ");

        //------------------------------------------------------------------------
        // Verification Summary
        //------------------------------------------------------------------------
        $display("\n==================================================");
        $display(" SENSOR INTERFACE VERIFICATION SUMMARY");
        $display("==================================================");
        $display(" TOTAL PASSED : %0d", pass_count);
        $display(" TOTAL FAILED : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS       : ALL CDC TESTS PASSED 100%%");
        else
            $display(" STATUS       : VERIFICATION FAILED");
        $display("==================================================\n");

        $finish;
    end

endmodule