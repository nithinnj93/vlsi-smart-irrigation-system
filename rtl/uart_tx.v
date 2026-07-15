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
    tx   <= 1'b1;
    busy <= 1'b0;

    if(start_pending && baud_tick)
    begin
        shift_reg <= data_in;

        bit_count <= 0;

        start_pending <= 1'b0;

        busy <= 1'b1;

        state <= START;
    end
end


        DATA:
begin
    tx <= shift_reg[0];

    shift_reg <= shift_reg >> 1;

    if (bit_count == DATA_BITS-1)
    begin
        state <= STOP;
    end
    else
    begin
        bit_count <= bit_count + 1;
    end
end
        STOP:
begin
    tx <= 1'b1;          // Stop bit
    busy <= 1'b1;

    state <= IDLE;
end

        endcase

    end

end

endmodule