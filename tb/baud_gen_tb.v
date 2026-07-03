`timescale 1ns/1ps

module baud_gen_tb;

reg clk;
reg reset;

wire baud_tick;

baud_gen #(
    .CLK_FREQ(100),
    .BAUD_RATE(10)
) uut (
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick)
);

always #5 clk = ~clk;

integer tick_count = 0;

initial
begin
    $dumpfile("waveforms/baud_gen.vcd");
    $dumpvars(0, baud_gen_tb);

    clk = 0;
    reset = 1;

    #20;
    reset = 0;

    #500;

    $display("-------------------------");
    $display("Total Baud Ticks = %0d", tick_count);
    $display("-------------------------");

    $finish;
end

always @(posedge clk)
begin
    if(baud_tick)
    begin
        tick_count = tick_count + 1;
        $display("Tick at time %0t", $time);
    end
end

endmodule