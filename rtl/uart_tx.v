module uart_tx #(
    parameter DATA_BITS = 8
)(
    input wire clk,
    input wire reset,

    input wire baud_tick,

    input wire tx_start,

    input wire [DATA_BITS-1:0] data_in,

    output reg tx,
    output reg busy
);

//======================================================
// State Encoding
//======================================================

localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

//======================================================
// Internal Registers
//======================================================

reg [1:0] state;

reg [DATA_BITS-1:0] shift_reg;

reg [2:0] bit_count;

reg start_pending;

//======================================================
// Sequential Logic
//======================================================

always @(posedge clk or posedge reset)
begin

    if(reset)
    begin

        state <= IDLE;

        tx <= 1'b1;

        busy <= 1'b0;

        shift_reg <= 0;

        bit_count <= 0;

        start_pending <= 0;

    end
    else
    begin

        //--------------------------------------------------
        // Latch transmit request
        //--------------------------------------------------

        if(tx_start)
            start_pending <= 1'b1;

        //--------------------------------------------------
        // FSM
        //--------------------------------------------------

        case(state)

        IDLE:
        begin
            // Next step will go here
        end

        START:
        begin
            // Next step will go here
        end

        DATA:
        begin
            // Next step will go here
        end

        STOP:
        begin
            // Next step will go here
        end

        endcase

    end

end

endmodule