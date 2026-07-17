`timescale 1ns / 1ps

module uart_status_gen_tb;

    parameter DATA_WIDTH = 8;

    reg             clk;
    reg             reset;
    reg [7:0]       moisture;
    reg             pump_on;
    reg [1:0]       status;
    reg             tx_busy;
    
    wire            tx_start;
    wire [7:0]      tx_data;

    // DUT Instantiation
    uart_status_gen #(DATA_WIDTH) DUT (
        .clk(clk),
        .reset(reset),
        .moisture(moisture),
        .pump_on(pump_on),
        .status(status),
        .tx_busy(tx_busy),
        .tx_start(tx_start),
        .tx_data(tx_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Scoreboard: Capture the packet sent by the generator
    reg [7:0] received_packet [0:13];
    integer   byte_idx;

    // Simulation of UART TX Busy Handshake
    // When the generator pulses tx_start, we assert tx_busy for 3 cycles 
    // to simulate the UART transmission time.
    always @(posedge clk) begin
        if (tx_start) begin
            tx_busy <= 1'b1;
            received_packet[byte_idx] <= tx_data;
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
        $display(" STARTING UART STATUS GEN VERIFICATION");
        $display("==================================================");

        // Wait for one full packet (14 bytes * 3 cycles handshake = ~42 cycles)
        repeat(100) @(posedge clk);

        // Expected: "M:085 P:1 S:0\n"
        if (received_packet[0] == "M" && received_packet[2] == "0" && 
            received_packet[3] == "8" && received_packet[4] == "5" &&
            received_packet[8] == "1" && received_packet[12] == "0") begin
            $display("[PASS] Telemetry Packet Verified: M:085 P:1 S:0");
        end else begin
            $display("[FAIL] Packet Mismatch!");
            $display("       Got: %c%c%c%c%c...", received_packet[0], received_packet[1], received_packet[2], received_packet[3], received_packet[4]);
        end

        $display("==================================================");
        $finish;
    end
endmodule