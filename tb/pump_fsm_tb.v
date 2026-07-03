`timescale 1ns/1ps

module pump_fsm_tb;

    // Inputs
    reg clk;
    reg reset;
    reg dry;

    // Output
    wire pump_on;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate the Design Under Test (DUT)
    pump_fsm uut (
        .clk(clk),
        .reset(reset),
        .dry(dry),
        .pump_on(pump_on)
    );

    // Clock Generation (10 ns period)
    always #5 clk = ~clk;

    // Task to check pump output
    task check_output;
        input expected;
        begin
            #1;
            if (pump_on == expected) begin
                $display("PASS : Time=%0t Dry=%0b Pump=%0b",
                         $time, dry, pump_on);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL : Time=%0t Dry=%0b Expected=%0b Got=%0b",
                         $time, dry, expected, pump_on);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin

        // Waveform generation
        $dumpfile("waveforms/pump_fsm.vcd");
        $dumpvars(0, pump_fsm_tb);

        $display("=======================================");
        $display("      Pump FSM Verification");
        $display("=======================================");

        clk = 0;
        reset = 1;
        dry = 0;

        // Reset FSM
        #12;
        reset = 0;

        //-------------------------------------------------
        // Test Case 1 : Soil is Wet
        //-------------------------------------------------
        dry = 0;
        #10;
        check_output(0);

        //-------------------------------------------------
        // Test Case 2 : Soil becomes Dry
        //-------------------------------------------------
        dry = 1;

        #10;      // START_PUMP
        check_output(1);

        #10;      // WATERING
        check_output(1);

        //-------------------------------------------------
        // Test Case 3 : Soil becomes Wet again
        //-------------------------------------------------
        dry = 0;

        #10;      // STOP_PUMP
        check_output(0);

        #10;      // IDLE
        check_output(0);

        //-------------------------------------------------

        $display("---------------------------------------");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("---------------------------------------");

        if (fail_count == 0)
            $display("ALL TEST CASES PASSED");
        else
            $display("SOME TEST CASES FAILED");

        $finish;

    end

endmodule