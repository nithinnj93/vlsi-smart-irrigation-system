`timescale 1ns/1ps

module uart_tx_tb;

    reg clk;
    reg reset;
    reg tx_start;
    reg [7:0] data_in;

    wire tx;
    wire busy;

    integer pass_count = 0;
    integer fail_count = 0;

    // DUT
    uart_tx uut (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

    // Clock
    always #5 clk = ~clk;

    // Task for checking TX
    task check_tx;
        input expected;
        begin
            #1;
            if(tx == expected) begin
                $display("PASS : Time=%0t TX=%0b", $time, tx);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL : Time=%0t Expected=%0b Got=%0b",
                          $time, expected, tx);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin

        $dumpfile("waveforms/uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        clk = 0;
        reset = 1;
        tx_start = 0;
        data_in = 8'b01010011;

        #12;
        reset = 0;

        // Idle
        #10;
        check_tx(1);

        // Start transmission
        tx_start = 1;
        #10;
        tx_start = 0;

        // Start bit
        check_tx(0);

        // Wait for all data bits and stop bit
        repeat(9)
            #10;

        // Stop bit
        check_tx(1);

        $display("--------------------------------");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("--------------------------------");

        if(fail_count == 0)
            $display("UART TEST PASSED");
        else
            $display("UART TEST FAILED");

        $finish;

    end

endmodule