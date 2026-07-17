`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   uart_tx_tb
// Author:        Nithin N J
// Description:   Self-checking verification environment for modular UART TX.
//////////////////////////////////////////////////////////////////////////////////

module uart_tx_tb;

    parameter DATA_WIDTH   = 8;
    parameter CLKS_PER_BIT = 8; // Scaled down for fast simulation viewing

    reg                   clk;
    reg                   reset;
    reg                   baud_tick;
    reg                   tx_start;
    reg  [DATA_WIDTH-1:0] data_in;

    wire                  busy;
    wire                  tx;
    wire                  tx_done;

    integer               pass_count;
    integer               fail_count;
    integer               tick_counter;

    //----------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    //----------------------------------------------------------------------------
    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data_in(data_in),
        .busy(busy),
        .tx(tx),
        .tx_done(tx_done)
    );

    //----------------------------------------------------------------------------
    // Clock Generation (100 MHz -> 10ns period)
    //----------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //----------------------------------------------------------------------------
    // Mock Free-Running Baud Tick Generator
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            tick_counter <= 0;
            baud_tick    <= 0;
        end else begin
            if (tick_counter == CLKS_PER_BIT - 1) begin
                tick_counter <= 0;
                baud_tick    <= 1'b1; // 1-cycle enable pulse
            end else begin
                tick_counter <= tick_counter + 1;
                baud_tick    <= 1'b0;
            end
        end
    end

    //----------------------------------------------------------------------------
    // Waveform Dump for GTKWave / VS Code
    //----------------------------------------------------------------------------
    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
    end

    //----------------------------------------------------------------------------
    // Verification Tasks
    //----------------------------------------------------------------------------
    task wait_for_next_baud_tick;
    begin
        @(posedge clk);
        while (baud_tick == 1'b0) begin
            @(posedge clk);
        end
    end
    endtask

    task check_line;
        input expected_value;
        input [127:0] bit_name;
    begin
        if (tx === expected_value) begin
            pass_count = pass_count + 1;
            $display("[PASS] %0s : Expected TX = %b, Got TX = %b", bit_name, expected_value, tx);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] %0s : Expected TX = %b, Got TX = %b", bit_name, expected_value, tx);
        end
    end
    endtask

    //----------------------------------------------------------------------------
    // Main Verification Sequence
    //----------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        reset      = 1'b1;
        tx_start   = 1'b0;
        data_in    = 8'h00;
        tick_counter = 0;

        repeat(5) @(posedge clk);
        reset = 1'b0;
        repeat(2) @(posedge clk);

        $display("==================================================");
        $display(" STARTING UART TRANSMITTER VERIFICATION");
        $display("==================================================");

        // 1. Verify Idle State
        check_line(1'b1, "IDLE State");

        // 2. Assert tx_start for EXACTLY 1 CLOCK CYCLE (Testing Latch Mechanism)
        data_in = 8'hA5; // Binary: 10100101 (LSB transmitted first -> 1,0,1,0,0,1,0,1)
        $display("\n[INFO] Asserting 1-cycle tx_start pulse for Data: 8'hA5...");
        @(posedge clk);
        tx_start = 1'b1;
        @(posedge clk);
        tx_start = 1'b0; // Immediately deasserted!

        // 3. Verify Busy asserts immediately (even before baud_tick arrives)
        if (busy === 1'b1) begin
            pass_count = pass_count + 1;
            $display("[PASS] Busy asserted immediately upon tx_start");
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] Busy failed to assert on tx_start");
        end

        // 4. Wait for first baud_tick and check Start Bit
        wait_for_next_baud_tick();
        check_line(1'b0, "START Bit ");

        // 5. Check 8 Data Bits (LSB First: 1 -> 0 -> 1 -> 0 -> 0 -> 1 -> 0 -> 1)
        wait_for_next_baud_tick(); check_line(1'b1, "DATA Bit 0");
        wait_for_next_baud_tick(); check_line(1'b0, "DATA Bit 1");
        wait_for_next_baud_tick(); check_line(1'b1, "DATA Bit 2");
        wait_for_next_baud_tick(); check_line(1'b0, "DATA Bit 3");
        wait_for_next_baud_tick(); check_line(1'b0, "DATA Bit 4");
        wait_for_next_baud_tick(); check_line(1'b1, "DATA Bit 5");
        wait_for_next_baud_tick(); check_line(1'b0, "DATA Bit 6");
        wait_for_next_baud_tick(); check_line(1'b1, "DATA Bit 7");

        // 6. Check Stop Bit
        wait_for_next_baud_tick(); 
        check_line(1'b1, "STOP Bit  ");

        // 7. Verify tx_done 1-cycle pulse
        if (tx_done === 1'b1) begin
            pass_count = pass_count + 1;
            $display("[PASS] tx_done pulsed high cleanly at Stop Bit boundary");
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] tx_done did not pulse high when expected");
        end

        // 8. Verify Busy deasserts on next clock
        @(posedge clk);
        if (busy === 1'b0) begin
            pass_count = pass_count + 1;
            $display("[PASS] Busy deasserted cleanly after transmission");
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] Busy remained high after transmission completed");
        end

        //------------------------------------------------------------------------
        // Verification Summary
        //------------------------------------------------------------------------
        $display("\n==================================================");
        $display(" VERIFICATION SUMMARY");
        $display("==================================================");
        $display(" TOTAL PASSED : %0d", pass_count);
        $display(" TOTAL FAILED : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS       : ALL TEST CASES PASSED 100%");
        else
            $display(" STATUS       : VERIFICATION FAILED");
        $display("==================================================\n");

        $finish;
    end

endmodule