`timescale 1ns/1ps

module moisture_comparator_tb;

    // Inputs
    reg [7:0] moisture;
    reg [7:0] threshold;

    // Output
    wire pump_on;

    integer pass_count = 0;
    integer fail_count = 0;

    // Design Under Test (DUT)
    moisture_comparator uut (
        .moisture(moisture),
        .threshold(threshold),
        .pump_on(pump_on)
    );

    // Task to check output
    task check_output;
        input expected;
        begin
            #5;
            if (pump_on == expected) begin
                $display("PASS : Moisture=%0d Threshold=%0d Pump=%0b",
                          moisture, threshold, pump_on);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL : Moisture=%0d Threshold=%0d Expected=%0b Got=%0b",
                          moisture, threshold, expected, pump_on);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
$dumpfile("waveforms/moisture_comparator.vcd");
$dumpvars(0, moisture_comparator_tb);
        $display("========================================");
        $display(" Moisture Comparator Verification");
        $display("========================================");

        threshold = 40;

        moisture = 20;
        check_output(1);

        moisture = 35;
        check_output(1);

        moisture = 40;
        check_output(0);

        moisture = 60;
        check_output(0);

        moisture = 10;
        check_output(1);

        $display("----------------------------------------");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("----------------------------------------");

        if (fail_count == 0)
            $display("ALL TEST CASES PASSED");
        else
            $display("SOME TEST CASES FAILED");

        $finish;

    end

endmodule