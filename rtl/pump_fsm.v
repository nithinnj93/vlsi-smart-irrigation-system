module pump_fsm(

    input wire clk,
    input wire reset,
    input wire dry,

    output reg pump_on

);

//-----------------------------
// State Encoding
//-----------------------------

parameter IDLE       = 2'b00;
parameter START_PUMP = 2'b01;
parameter WATERING   = 2'b10;
parameter STOP_PUMP  = 2'b11;

reg [1:0] current_state;
reg [1:0] next_state;

//-----------------------------
// State Register
//-----------------------------

always @(posedge clk or posedge reset)
begin
    if(reset)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

//-----------------------------
// Next State Logic
//-----------------------------

always @(*)
begin

    case(current_state)

        IDLE:
            if(dry)
                next_state = START_PUMP;
            else
                next_state = IDLE;

        START_PUMP:
            next_state = WATERING;

        WATERING:
            if(dry)
                next_state = WATERING;
            else
                next_state = STOP_PUMP;

        STOP_PUMP:
            next_state = IDLE;

        default:
            next_state = IDLE;

    endcase

end

//-----------------------------
// Output Logic
//-----------------------------

always @(*)
begin

    case(current_state)

        IDLE:
            pump_on = 0;

        START_PUMP:
            pump_on = 1;

        WATERING:
            pump_on = 1;

        STOP_PUMP:
            pump_on = 0;

        default:
            pump_on = 0;

    endcase

end

endmodule