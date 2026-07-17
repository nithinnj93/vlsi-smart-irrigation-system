`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   uart_tx
// Author:        Nithin N J
// Description:   
//   Industry-grade UART Transmitter (8-N-1) with decoupled Baud Tick enable.
//   Features a 5-state FSM with Start Request Latching to guarantee zero 
//   start-bit truncation when interfacing with a free-running baud generator.
//////////////////////////////////////////////////////////////////////////////////

module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  baud_tick,
    input  wire                  tx_start,
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire                  busy,
    output wire                  tx,
    output wire                  tx_done
);

    //----------------------------------------------------------------------------
    // State Encoding (Binary Clean Encoding)
    //----------------------------------------------------------------------------
    localparam [2:0] IDLE      = 3'd0,
                     WAIT_TICK = 3'd1,
                     START_BIT = 3'd2,
                     DATA_BITS = 3'd3,
                     STOP_BIT  = 3'd4;

    //----------------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------------
    reg [2:0]            state_reg, state_next;
    reg [DATA_WIDTH-1:0] shift_reg, shift_next;
    reg [2:0]            bit_cnt_reg, bit_cnt_next;
    reg                  tx_reg, tx_next;
    reg                  busy_reg, busy_next;
    reg                  tx_done_reg, tx_done_next;

    //----------------------------------------------------------------------------
    // Output Port Binding (Continuous Assignments)
    //----------------------------------------------------------------------------
    assign tx      = tx_reg;
    assign busy    = busy_reg;
    assign tx_done = tx_done_reg;

    //----------------------------------------------------------------------------
    // Sequential Logic: Register Update (Synchronous Reset)
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state_reg   <= IDLE;
            shift_reg   <= {DATA_WIDTH{1'b0}};
            bit_cnt_reg <= 3'd0;
            tx_reg      <= 1'b1;         // UART line is HIGH (Mark) when idle
            busy_reg    <= 1'b0;
            tx_done_reg <= 1'b0;
        end else begin
            state_reg   <= state_next;
            shift_reg   <= shift_next;
            bit_cnt_reg <= bit_cnt_next;
            tx_reg      <= tx_next;
            busy_reg    <= busy_next;
            tx_done_reg <= tx_done_next;
        end
    end

    //----------------------------------------------------------------------------
    // Combinational Logic: Next State and Output Decode
    //----------------------------------------------------------------------------
    always @(*) begin
        // Default assignments to prevent unintentional latches
        state_next   = state_reg;
        shift_next   = shift_reg;
        bit_cnt_next = bit_cnt_reg;
        tx_next      = tx_reg;
        busy_next    = busy_reg;
        tx_done_next = 1'b0;             // Default to 0; pulses for 1 clock cycle on completion

        case (state_reg)
            //--------------------------------------------------
            // IDLE: Monitor tx_start on every system clock
            //--------------------------------------------------
            IDLE: begin
                tx_next   = 1'b1;
                busy_next = 1'b0;
                if (tx_start) begin
                    shift_next = data_in; // Latch payload immediately
                    busy_next  = 1'b1;    // Assert busy immediately to lock host
                    state_next = WAIT_TICK;
                end
            end

            //--------------------------------------------------
            // WAIT_TICK: Align Start Bit to the next Baud Tick
            //--------------------------------------------------
            WAIT_TICK: begin
                tx_next   = 1'b1;
                busy_next = 1'b1;
                if (baud_tick) begin
                    tx_next      = 1'b0;  // Drive Start Bit (LOW / Space)
                    bit_cnt_next = 3'd0;
                    state_next   = START_BIT;
                end
            end

            //--------------------------------------------------
            // START_BIT: Hold Start Bit for 1 full Baud Period
            //--------------------------------------------------
            START_BIT: begin
                tx_next   = 1'b0;
                busy_next = 1'b1;
                if (baud_tick) begin
                    tx_next      = shift_reg[0]; // Drive LSB first
                    shift_next   = {1'b0, shift_reg[DATA_WIDTH-1:1]};
                    bit_cnt_next = 3'd0;
                    state_next   = DATA_BITS;
                end
            end

            //--------------------------------------------------
            // DATA_BITS: Shift out 8 bits sequentially
            //--------------------------------------------------
            DATA_BITS: begin
                tx_next   = tx_reg;
                busy_next = 1'b1;
                if (baud_tick) begin
                    if (bit_cnt_reg == (DATA_WIDTH - 1)) begin
                        tx_next    = 1'b1; // Drive Stop Bit (HIGH)
                        state_next = STOP_BIT;
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1'b1;
                        tx_next      = shift_reg[0];
                        shift_next   = {1'b0, shift_reg[DATA_WIDTH-1:1]};
                    end
                end
            end

            //--------------------------------------------------
            // STOP_BIT: Hold Stop Bit, assert done pulse
            //--------------------------------------------------
            STOP_BIT: begin
                tx_next   = 1'b1;
                busy_next = 1'b1;
                if (baud_tick) begin
                    tx_done_next = 1'b1;   // Pulse tx_done for exactly 1 system clock
                    busy_next    = 1'b0;
                    state_next   = IDLE;
                end
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule