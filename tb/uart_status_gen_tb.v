`timescale 1ns / 1ps

module uart_status_gen_tb;

    // Parameters
    parameter DATA_WIDTH = 8;

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] moisture;
    reg       pump_on;
    reg [1:0] status;
    reg       tx_busy;

    // Outputs
    wire       tx_start;
    wire [7:0] tx_data;

    // Internal Integration Wire
    wire [111:0] packet_bytes;

    // 1. Instantiate Data Path (Formatter)
    ascii_formatter FORMATTER (
        .moisture(moisture),
        .pump_on(pump_on),
        .status(status),
        .packet_bytes(packet_bytes)
    );

    // 2. Instantiate Control Path (Sequencer)
    uart_sequencer SEQUENCER (
        .clk(clk),
        .reset(reset),
        .packet_bytes(packet_bytes),
        .tx_busy(tx_busy),
        .tx_start(tx_start),
        .tx_data(tx_data)
    );

    // Clock Gen
    initial clk = 0;
    always #5 clk = ~clk;

    // Capture Packet
    reg [7:0] captured_packet [0:13];
    integer   byte_idx;

    always @(posedge clk) begin
        if (tx_start) begin
            tx_busy <= 1'b1; // Simulate busy
            captured_packet[byte_idx] <= tx_data;
            if (byte_idx < 13) byte_idx <= byte_idx + 1;
            else byte_idx <= 0;
        end else begin
            tx_busy <= 1'b0;
        end
    end

    initial begin
        reset    = 1;
        moisture = 85;
        pump_on  = 1;
        status   = 0;
        byte_idx = 0;
        
        repeat(5) @(posedge clk);
        reset = 0;

        $display("==================================================");
        $display(" STARTING INTEGRATED TELEMETRY VERIFICATION");
        $display("==================================================");

        // Wait for sequencer to finish one packet
        repeat(150) @(posedge clk);

        // Verify: "M:085 P:1 S:0\n"
        if (captured_packet[0] == "M" && captured_packet[2] == "0" && 
            captured_packet[3] == "8" && captured_packet[4] == "5" &&
            captured_packet[8] == "1" && captured_packet[12] == "0") begin
            $display("[PASS] Integrated Packet Verified: M:085 P:1 S:0");
        end else begin
            $display("[FAIL] Packet Mismatch!");
            $display("       Got: %c%c%c%c%c...", captured_packet[0], captured_packet[1], captured_packet[2], captured_packet[3], captured_packet[4]);
        end

        $display("==================================================");
        $finish;
    end
endmodule