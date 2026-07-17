`timescale 1ns / 1ps

module irrigation_top_tb;

    parameter DATA_WIDTH = 8;
    
    // Testbench Inputs
    reg clk;
    reg reset;
    reg adc_valid_in;
    reg [DATA_WIDTH-1:0] adc_data_in;

    // Testbench Outputs
    wire pump_on;
    wire pump_timeout;
    wire tx;

    // Instantiate System Under Test (SUT)
    irrigation_top #(DATA_WIDTH, 20, 10) SUT (
        .clk(clk),
        .reset(reset),
        .adc_valid_in(adc_valid_in),
        .adc_data_in(adc_data_in),
        .pump_on(pump_on),
        .pump_timeout(pump_timeout),
        .tx(tx)
    );

    // Clock Gen
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to inject sensor data asynchronously
    task inject_sample;
        input [DATA_WIDTH-1:0] val;
    begin
        @(negedge clk);
        adc_data_in  = val;
        adc_valid_in = 1'b1;
        @(negedge clk);
        adc_valid_in = 1'b0;
    end
    endtask

    initial begin
        // Init
        reset = 1;
        adc_valid_in = 0;
        adc_data_in = 0;
        repeat(10) @(posedge clk);
        reset = 0;

        $display("==================================================");
        $display(" STARTING FULL SYSTEM INTEGRATION TEST");
        $display("==================================================");

        // 1. Dry Condition: Trigger Pump
        // Feed 20 (Below threshold 30)
        repeat(10) inject_sample(8'd20);
        #500;
        if (pump_on) $display("[PASS] Pump triggered on Dry condition.");
        else         $display("[FAIL] Pump failed to trigger!");

        // 2. Wet Condition: Shutoff
        // Feed 85 (Above threshold 70)
        repeat(10) inject_sample(8'd85);
        #500;
        if (!pump_on) $display("[PASS] Pump shutoff on Wet condition.");
        else          $display("[FAIL] Pump failed to shutoff!");

        $display("==================================================");
        $display(" INTEGRATION TEST COMPLETE");
        $display("==================================================");
        $finish;
    end
endmodule