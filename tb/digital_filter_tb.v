`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   digital_filter_tb
// Author:        Nithin N J
// Description:   10/10 Self-checking black-box verification environment for 
//                the recursive moving average digital filter. Utilizes negedge
//                stimulus driving to eliminate delta-cycle race conditions.
//////////////////////////////////////////////////////////////////////////////////

module digital_filter_tb;

    parameter DATA_WIDTH  = 8;
    parameter WINDOW_BITS = 3; // 8-tap filter

    // Testbench Drivers
    reg                   clk;
    reg                   reset;
    reg                   sample_valid;
    reg  [DATA_WIDTH-1:0] data_in;

    // Testbench Observation Wires
    wire [DATA_WIDTH-1:0] data_out;
    wire                  filter_valid;

    // Scoreboard Counters
    integer               pass_count;
    integer               fail_count;

    //----------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation (Strict Black-Box Mapping)
    //----------------------------------------------------------------------------
    digital_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .WINDOW_BITS(WINDOW_BITS)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .sample_valid(sample_valid),
        .data_in(data_in),
        .data_out(data_out),
        .filter_valid(filter_valid)
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
        $dumpfile("digital_filter_tb.vcd");
        $dumpvars(0, digital_filter_tb);
    end

    //----------------------------------------------------------------------------
    // Verification Task: Feed Sample and Score Output (Negedge Driven)
    //----------------------------------------------------------------------------
    task feed_and_check;
        input [DATA_WIDTH-1:0] sample_val;
        input [DATA_WIDTH-1:0] expected_out;
        input [255:0]          test_name;
    begin
        // 1. Drive sample cleanly on negative edge (prevents setup/race hazards)
        @(negedge clk);
        sample_valid = 1'b1;
        data_in      = sample_val;
        
        // 2. Deassert on next negative edge (guarantees exactly 1 posedge sample)
        @(negedge clk);
        sample_valid = 1'b0;

        // 3. Sample scoreboard output after DUT registers settle
        if (data_out === expected_out && filter_valid === 1'b1) begin
            pass_count = pass_count + 1;
            $display("[PASS] %0s | In: %0d -> Out: %0d (Expected: %0d)", 
                     test_name, sample_val, data_out, expected_out);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] %0s | In: %0d -> Out: %0d (Expected: %0d)", 
                     test_name, sample_val, data_out, expected_out);
        end

        // Wait a couple idle clock cycles between transactions
        repeat(2) @(posedge clk);
    end
    endtask

    //----------------------------------------------------------------------------
    // Main Verification Regression Sequence
    //----------------------------------------------------------------------------
    integer j;
    initial begin
        pass_count   = 0;
        fail_count   = 0;
        reset        = 1'b1;
        sample_valid = 1'b0;
        data_in      = 8'h00;

        repeat(5) @(posedge clk);
        reset = 1'b0;
        repeat(2) @(posedge clk);

        $display("==================================================");
        $display(" STARTING DIGITAL FILTER VERIFICATION (8-TAP)");
        $display("==================================================");

        //--------------------------------------------------
        // 1. STEP RESPONSE TEST (Ramping from 0 to 128)
        //--------------------------------------------------
        $display("\n[INFO] Test 1: Step Response (Feeding constant 128 into empty filter)...");
        feed_and_check(8'd128, 8'd16,  "Step Tap 1 (128/8 * 1)    ");
        feed_and_check(8'd128, 8'd32,  "Step Tap 2 (128/8 * 2)    ");
        feed_and_check(8'd128, 8'd48,  "Step Tap 3 (128/8 * 3)    ");
        feed_and_check(8'd128, 8'd64,  "Step Tap 4 (128/8 * 4)    ");
        feed_and_check(8'd128, 8'd80,  "Step Tap 5 (128/8 * 5)    ");
        feed_and_check(8'd128, 8'd96,  "Step Tap 6 (128/8 * 6)    ");
        feed_and_check(8'd128, 8'd112, "Step Tap 7 (128/8 * 7)    ");
        feed_and_check(8'd128, 8'd128, "Step Tap 8 (Steady State) ");

        //--------------------------------------------------
        // 2. STEADY STATE & IMPULSE NOISE REJECTION TEST
        //--------------------------------------------------
        $display("\n[INFO] Test 2: Flushing to steady state of 50...");
        for (j = 0; j < 8; j = j + 1) begin
            @(negedge clk); // Driven on negedge!
            sample_valid = 1'b1;
            data_in      = 8'd50;
            @(negedge clk);
            sample_valid = 1'b0;
            repeat(2) @(posedge clk);
        end

        $display("\n[INFO] Test 3: Injecting 1-cycle EMI voltage spike of 255!");
        // If steady state is 50 (sum=400), adding 255 and replacing one 50 gives sum = 605.
        // 605 >> 3 = 75 decimal. The noise spike is successfully suppressed!
        feed_and_check(8'd255, 8'd75, "EMI Impulse Suppression   ");

        // Feed another normal sample to watch the noise flush out
        feed_and_check(8'd50,  8'd75, "Post-Impulse Recovery 1   ");

        //------------------------------------------------------------------------
        // Verification Summary
        //------------------------------------------------------------------------
        $display("\n==================================================");
        $display(" FILTER VERIFICATION SUMMARY");
        $display("==================================================");
        $display(" TOTAL PASSED : %0d", pass_count);
        $display(" TOTAL FAILED : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS       : ALL FILTER TESTS PASSED 100%%");
        else
            $display(" STATUS       : VERIFICATION FAILED");
        $display("==================================================\n");

        $finish;
    end

endmodule