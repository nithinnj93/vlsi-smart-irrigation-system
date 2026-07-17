`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   moisture_comparator_tb
// Author:        Nithin N J
// Description:   10/10 Self-checking black-box verification environment for 
//                the dual-threshold moisture comparator. Validates hysteresis
//                deadband logic and fail-safe open/short circuit fault overrides.
//////////////////////////////////////////////////////////////////////////////////

module moisture_comparator_tb;

    parameter DATA_WIDTH = 8;

    // Testbench Drivers
    reg  [DATA_WIDTH-1:0] moisture_in;
    reg  [DATA_WIDTH-1:0] thresh_low;
    reg  [DATA_WIDTH-1:0] thresh_high;

    // Testbench Observation Wires
    wire                  dry_trigger;
    wire                  wet_trigger;
    wire                  sensor_fault;
    wire [1:0]            status_code;

    // Verification Scoreboard Counters
    integer               pass_count;
    integer               fail_count;

    //----------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation (Strict Black-Box Mapping)
    //----------------------------------------------------------------------------
    moisture_comparator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .moisture_in(moisture_in),
        .thresh_low(thresh_low),
        .thresh_high(thresh_high),
        .dry_trigger(dry_trigger),
        .wet_trigger(wet_trigger),
        .sensor_fault(sensor_fault),
        .status_code(status_code)
    );

    //----------------------------------------------------------------------------
    // Waveform Dump
    //----------------------------------------------------------------------------
    initial begin
        $dumpfile("moisture_comparator_tb.vcd");
        $dumpvars(0, moisture_comparator_tb);
    end

    //----------------------------------------------------------------------------
    // Automated Scoreboard Verification Task
    //----------------------------------------------------------------------------
    task apply_and_check;
        input [DATA_WIDTH-1:0] test_moisture;
        input [DATA_WIDTH-1:0] test_low;
        input [DATA_WIDTH-1:0] test_high;
        input                  exp_dry;
        input                  exp_wet;
        input                  exp_fault;
        input [1:0]            exp_status;
        input [255:0]          test_name;
    begin
        // Apply inputs
        moisture_in = test_moisture;
        thresh_low  = test_low;
        thresh_high = test_high;

        // Allow 10ns propagation delay for combinational gates to settle
        #10;

        // Black-box scoreboard verification
        if ((dry_trigger === exp_dry) && (wet_trigger === exp_wet) && 
            (sensor_fault === exp_fault) && (status_code === exp_status)) begin
            pass_count = pass_count + 1;
            $display("[PASS] %0s | M:%0d (L:%0d, H:%0d) -> Dry:%b Wet:%b Fault:%b Stat:%b", 
                     test_name, test_moisture, test_low, test_high, dry_trigger, wet_trigger, sensor_fault, status_code);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] %0s | M:%0d (L:%0d, H:%0d)", test_name, test_moisture, test_low, test_high);
            $display("       Expected: Dry:%b Wet:%b Fault:%b Stat:%b", exp_dry, exp_wet, exp_fault, exp_status);
            $display("       Got     : Dry:%b Wet:%b Fault:%b Stat:%b", dry_trigger, wet_trigger, sensor_fault, status_code);
        end
    end
    endtask

    //----------------------------------------------------------------------------
    // Main Verification Regression Sequence
    //----------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        moisture_in = 8'd50;
        thresh_low  = 8'd30;
        thresh_high = 8'd70;

        #10;
        $display("==================================================");
        $display(" STARTING MOISTURE COMPARATOR VERIFICATION");
        $display("==================================================");

        // Standard Operational Regimes (Low=30, High=70)
        apply_and_check(8'd50, 8'd30, 8'd70, 1'b0, 1'b0, 1'b0, 2'b00, "Optimal Range (50%)        ");
        apply_and_check(8'd20, 8'd30, 8'd70, 1'b1, 1'b0, 1'b0, 2'b01, "Dry Trigger Range (20%)    ");
        apply_and_check(8'd85, 8'd30, 8'd70, 1'b0, 1'b1, 1'b0, 2'b10, "Wet Trigger Range (85%)    ");

        // Hysteresis & Boundary Conditions
        apply_and_check(8'd30, 8'd30, 8'd70, 1'b0, 1'b0, 1'b0, 2'b00, "Boundary Exact Low (30%)   ");
        apply_and_check(8'd70, 8'd30, 8'd70, 1'b0, 1'b1, 1'b0, 2'b10, "Boundary Exact High (70%)  ");

        // Fail-Safe Hardware Fault Injection
        apply_and_check(8'h00, 8'd30, 8'd70, 1'b0, 1'b0, 1'b1, 2'b11, "Fault: Short to GND (0x00) ");
        apply_and_check(8'hFF, 8'd30, 8'd70, 1'b0, 1'b0, 1'b1, 2'b11, "Fault: Open Circuit (0xFF) ");

        //------------------------------------------------------------------------
        // Verification Summary
        //------------------------------------------------------------------------
        $display("\n==================================================");
        $display(" COMPARATOR VERIFICATION SUMMARY");
        $display("==================================================");
        $display(" TOTAL PASSED : %0d", pass_count);
        $display(" TOTAL FAILED : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS       : ALL COMPARATOR TESTS PASSED 100%%");
        else
            $display(" STATUS       : VERIFICATION FAILED");
        $display("==================================================\n");

        $finish;
    end

endmodule