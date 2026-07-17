`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   uart_loopback_tb
// Author:        Nithin N J
// Description:   Bidirectional UART Loopback Verification Environment.
//                Connects uart_tx serial output directly to uart_rx serial input
//                to verify 1x/16x clock domain interoperability and 8-N-1 framing.
//////////////////////////////////////////////////////////////////////////////////

module uart_loopback_tb;

    parameter DATA_WIDTH       = 8;
    parameter OVERSAMPLE_RATE  = 16;
    parameter CLKS_PER_16X_TICK = 4; // Scaled down for fast simulation viewing

    // System Signals
    reg                   clk;
    reg                   reset;

    // Clock Enable Ticks
    reg                   baud_over_tick; // 16x tick for RX
    reg                   baud_tick;      // 1x tick for TX
    reg [3:0]             tx_divide_cnt;  // Divides 16x tick by 16 to get 1x tick
    integer               tick_counter;

    // TX Interface
    reg                   tx_start;
    reg  [DATA_WIDTH-1:0] data_in;
    wire                  busy;
    wire                  tx_done;

    // RX Interface
    wire [DATA_WIDTH-1:0] data_out;
    wire                  rx_done;

    // The Loopback Interconnect Wire
    wire                  loop_serial;

    // Verification Counters
    integer               pass_count;
    integer               fail_count;

    //----------------------------------------------------------------------------
    // 1. Instantiate UART Transmitter (TX)
    //----------------------------------------------------------------------------
    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) TX_DUT (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data_in(data_in),
        .busy(busy),
        .tx(loop_serial),       // Drives the loopback wire
        .tx_done(tx_done)
    );

    //----------------------------------------------------------------------------
    // 2. Instantiate UART Receiver (RX)
    //----------------------------------------------------------------------------
    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .OVERSAMPLE_RATE(OVERSAMPLE_RATE)
    ) RX_DUT (
        .clk(clk),
        .reset(reset),
        .baud_over_tick(baud_over_tick),
        .rx(loop_serial),       // Reads from the loopback wire
        .data_out(data_out),
        .rx_done(rx_done)
    );

    //----------------------------------------------------------------------------
    // Clock Generation (100 MHz -> 10ns period)
    //----------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //----------------------------------------------------------------------------
    // Synchronous 16x and 1x Baud Tick Generator
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            tick_counter   <= 0;
            baud_over_tick <= 1'b0;
            baud_tick      <= 1'b0;
            tx_divide_cnt  <= 4'd0;
        end else begin
            // Default 1-cycle pulses to 0
            baud_over_tick <= 1'b0;
            baud_tick      <= 1'b0;

            // Generate 16x Oversample Tick
            if (tick_counter == CLKS_PER_16X_TICK - 1) begin
                tick_counter   <= 0;
                baud_over_tick <= 1'b1;

                // Divide 16x tick by 16 to generate 1x TX tick
                if (tx_divide_cnt == OVERSAMPLE_RATE - 1) begin
                    tx_divide_cnt <= 4'd0;
                    baud_tick     <= 1'b1;
                end else begin
                    tx_divide_cnt <= tx_divide_cnt + 1'b1;
                end
            end else begin
                tick_counter <= tick_counter + 1;
            end
        end
    end

    //----------------------------------------------------------------------------
    // Waveform Dump
    //----------------------------------------------------------------------------
    initial begin
        $dumpfile("uart_loopback_tb.vcd");
        $dumpvars(0, uart_loopback_tb);
    end

    //----------------------------------------------------------------------------
    // Verification Task: Automated Bidirectional Transaction
    //----------------------------------------------------------------------------
    task send_and_verify;
        input [DATA_WIDTH-1:0] payload;
        input [127:0]          test_name;
    begin
        // 1. Wait until transmitter is idle
        while (busy == 1'b1) @(posedge clk);

        // 2. Load payload and assert 1-cycle start pulse
        @(posedge clk);
        data_in  = payload;
        tx_start = 1'b1;
        @(posedge clk);
        tx_start = 1'b0;

        // 3. Event-Driven Synchronization: Wait for RX to capture and assemble byte
        @(posedge rx_done);

        // 4. Black-Box Verification: Compare transmitted vs. received payload
        if (data_out === payload) begin
            pass_count = pass_count + 1;
            $display("[PASS] %0s : Sent = 8'h%h | Received = 8'h%h", test_name, payload, data_out);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] %0s : Sent = 8'h%h | Received = 8'h%h", test_name, payload, data_out);
        end

        // 5. Allow a few clock cycles of line idle time before next frame
        repeat(10) @(posedge clk);
    end
    endtask

    //----------------------------------------------------------------------------
    // Main Regression Sequence
    //----------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        reset      = 1'b1;
        tx_start   = 1'b0;
        data_in    = 8'h00;

        repeat(10) @(posedge clk);
        reset = 1'b0;
        repeat(10) @(posedge clk);

        $display("==================================================");
        $display(" STARTING UART BIDIRECTIONAL LOOPBACK REGRESSION");
        $display("==================================================");

        // Standard Patterns
        send_and_verify(8'hA5, "Standard Pattern (10100101)");
        send_and_verify(8'h3C, "Standard Pattern (00111100)");

        // Corner Cases & Shift-Order Verification
        send_and_verify(8'h00, "Boundary Case: All Zeros  ");
        send_and_verify(8'hFF, "Boundary Case: All Ones   ");
        send_and_verify(8'h55, "Alternating Bits (01010101)");
        send_and_verify(8'hAA, "Alternating Bits (10101010)");

        // Back-to-Back Stress Test (Inter-frame timing check)
        $display("\n[INFO] Executing Back-to-Back Stress Test...");
        send_and_verify(8'h12, "Stress Byte 1 (8'h12)     ");
        send_and_verify(8'h34, "Stress Byte 2 (8'h34)     ");
        send_and_verify(8'h56, "Stress Byte 3 (8'h56)     ");
        send_and_verify(8'h78, "Stress Byte 4 (8'h78)     ");

        //------------------------------------------------------------------------
        // Verification Summary
        //------------------------------------------------------------------------
        $display("\n==================================================");
        $display(" LOOPBACK VERIFICATION SUMMARY");
        $display("==================================================");
        $display(" TOTAL PASSED : %0d", pass_count);
        $display(" TOTAL FAILED : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS       : ALL LOOPBACK TESTS PASSED 100%%");
        else
            $display(" STATUS       : VERIFICATION FAILED");
        $display("==================================================\n");

        $finish;
    end

endmodule