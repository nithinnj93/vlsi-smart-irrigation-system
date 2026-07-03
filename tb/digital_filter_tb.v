`timescale 1ns/1ps

module digital_filter_tb;

    reg clk;
    reg reset;
    reg [7:0] moisture;

    wire [7:0] filtered_moisture;

    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate DUT
    digital_filter uut (
        .clk(clk),
        .reset(reset),
        .moisture(moisture),
        .filtered_moisture(filtered_moisture)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        // Waveform generation
        $dumpfile("waveforms/digital_filter.vcd");
        $dumpvars(0, digital_filter_tb);

        clk = 0;
        reset = 1;
        moisture = 0;

        #10;
        reset = 0;

        // Sample 1
        moisture = 48;
        #10;
        $display("Sample=%0d Filtered=%0d", moisture, filtered_moisture);

        // Sample 2
        moisture = 50;
        #10;
        $display("Sample=%0d Filtered=%0d", moisture, filtered_moisture);

        // Sample 3
        moisture = 52;
        #10;
        $display("Sample=%0d Filtered=%0d", moisture, filtered_moisture);

        // Sample 4
        moisture = 54;
        #10;
        $display("Sample=%0d Filtered=%0d", moisture, filtered_moisture);

        // Sample 5
        moisture = 56;
        #10;
        $display("Sample=%0d Filtered=%0d", moisture, filtered_moisture);

        $finish;

    end

endmodule