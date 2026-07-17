`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   uart_top_tb
// Author:        Nithin N J
// Description:   10/10 Self-checking system integration testbench for UART IP Core.
//                Verifies complete encapsulation by removing external clock ticks
//                and running automated bidirectional framing over internal loopback
//                at a realistic IoT baud rate (115200 Baud @ 50 MHz System Clock).
//////////////////////////////////////////////////////////////////////////////////

module uart_top_tb;

    // Target System Parameters
    parameter CLK_FREQ        = 50000000; // 50 MHz
    parameter BAUD_RATE       = 115200;   // 115.2 kbps
    parameter DATA_WIDTH      = 8;
    parameter OVERSAMPLE_RATE = 16;

    // Testbench Driver Signals
    reg                   clk;
    reg                   reset;
    reg                   tx_start;
    reg  [DATA_WIDTH-1:0] data_in;

    // Testbench Observation Wires
    wire                  busy;
    wire                  tx_done;
    wire [DATA_WIDTH-1:0] data_out;
    wire                  rx_done;

    // Internal Loopback Interconnect (TX -> RX)
    wire                  serial_loop;

    // Verification Scoreboard Counters
    integer               pass_count;
    integer               fail_count;

    //----------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation (Complete IP Encapsulation)
    //----------------------------------------------------------------------------
    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH),
        .OVERSAMPLE_RATE(OVERSAMPLE_RATE)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .data_in(data_in),
        .busy(busy),
        .tx_done(tx_done),
        .tx(serial_loop),     // TX drives the loopback wire
        .rx(serial_loop),     // RX reads the loopback wire
        .data_out(data_out),
        .rx_done(rx_done)
    );

    //----------------------------------------------------------------------------
    // Clock Generation (50 MHz -> 20ns period)
    //----------------------------------------------------------------------------
    initial clk = 0;
    always #10 clk = ~clk;

    //----------------------------------------------------------------------------
    // Waveform Dump
    //----------------------------------------------------------------------------
    initial begin
        $dumpfile("uart_top_tb.vcd");
        $dumpvars(0, uart_top_tb);
    end

    //----------------------------------------------------------------------------
    // Verification Task: Automated Encapsulated Transaction
    //----------------------------------------------------------------------------
    task send_and_check;
        input [DATA_WIDTH-1:0] payload;
        input [255:0]          test_name; // Sized to 256 bits to prevent MSB truncation!
    begin
        // 1. Wait until IP Core is completely idle
        while (busy == 1'b1) @(posedge clk);

        // 2. Load payload and assert single-cycle start request
        @(posedge clk);
        data_in  = payload;
        tx_start = 1'b1;
        @(posedge clk);
        tx_start = 1'b0;

        // 3. Event-Driven Synchronization: Lock onto receiver completion pulse
        @(posedge rx_done);

        // 4. Scoreboard Evaluation
        if (data_out === payload) begin
            pass_count = pass_count + 1;
            $display("[PASS] %0s : Sent = 8'h%h | Received = 8'h%h", test_name, payload, data_out);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] %0s : Sent = 8'h%h | Received = 8'h%h", test_name, payload, data_out);
        end

        // 5. Inter-frame spacing
        repeat(20) @(posedge clk);
    end
    endtask

    //----------------------------------------------------------------------------
    // Main System Regression Sequence
    //----------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        reset      = 1'b1;
        tx_start   = 1'b0;
        data_in    = 8'h00;

        // Hold reset for 10 clock cycles
        repeat(10) @(posedge clk);
        reset = 1'b0;
        repeat(10) @(posedge clk);

        $display("==================================================");
        $display(" STARTING UART IP CORE INTEGRATION REGRESSION");
        $display(" Target: 115200 Baud @ 50 MHz System Clock");
        $display("==================================================");

        // 1. Baseline ASCII/Hex Verification
        send_and_check(8'hA5, "Standard Pattern (10100101)     ");
        send_and_check(8'h3C, "Standard Pattern (00111100)     ");

        // 2. Corner Case Verification
        send_and_check(8'h00, "Boundary Case: All Zeros (8'h00)");
        send_and_check(8'hFF, "Boundary Case: All Ones (8'hFF) ");
        send_and_check(8'h55, "Alternating Bits (01010101)     ");
        send_and_check(8'hAA, "Alternating Bits (10101010)     ");

        // 3. Back-to-Back IoT Stream Simulation
        $display("\n[INFO] Simulating Continuous IoT Sensor Data Stream...");
        send_and_check(8'h4D, "ASCII Character 'M' (Moisture)  ");
        send_and_check(8'h3A, "ASCII Character ':' (Separator) ");
        send_and_check(8'h38, "ASCII Character '8' (Digit 8)   ");
        send_and_check(8'h35, "ASCII Character '5' (Digit 5)   ");

        //------------------------------------------------------------------------
        // Verification Summary
        //------------------------------------------------------------------------
        $display("\n==================================================");
        $display(" UART TOP INTEGRATION VERIFICATION SUMMARY");
        $display("==================================================");
        $display(" TOTAL PASSED : %0d", pass_count);
        $display(" TOTAL FAILED : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS       : ALL INTEGRATION TESTS PASSED 100%%");
        else
            $display(" STATUS       : VERIFICATION FAILED");
        $display("==================================================\n");

        $finish;
    end

endmodule