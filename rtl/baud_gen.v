module baud_gen #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input clk,
    input reset,
    output reg baud_tick
);

localparam DIVISOR = CLK_FREQ / BAUD_RATE;

integer counter;

always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        counter <= 0;
        baud_tick <= 0;
    end
    else
    begin
        if(counter == DIVISOR-1)
        begin
            counter <= 0;
            baud_tick <= 1;
        end
        else
        begin
            counter <= counter + 1;
            baud_tick <= 0;
        end
    end
end

endmodule