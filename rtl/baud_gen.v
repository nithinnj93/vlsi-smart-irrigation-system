`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   baud_gen (v2)
// Author:        Nithin N J
// Description:   
//   Industry-grade Baud Rate Generator with dual clock-enable outputs.
//   Derives a 16x oversampling tick (baud_over_tick) for UART RX and cleanly
//   divides it by 16 to generate a phase-aligned 1x tick (baud_tick) for TX.
//   Uses dynamic $clog2 register sizing and synchronous reset methodologies.
//////////////////////////////////////////////////////////////////////////////////

module baud_gen #(
    parameter CLK_FREQ        = 50000000, // 50 MHz default system clock
    parameter BAUD_RATE       = 9600,     // 9600 baud default
    parameter OVERSAMPLE_RATE = 16        // 16x oversampling for receiver
)(
    input  wire clk,
    input  wire reset,
    output wire baud_tick,      // 1x Baud Enable Pulse (for uart_tx)
    output wire baud_over_tick  // 16x Baud Enable Pulse (for uart_rx)
);

    //----------------------------------------------------------------------------
    // Parameterized Divisor & Dynamic Register Width Calculation
    //----------------------------------------------------------------------------
    // Divisor for 16x oversampling tick: 50,000,000 / (9600 * 16) = ~325
    localparam DIVISOR       = CLK_FREQ / (BAUD_RATE * OVERSAMPLE_RATE);
    localparam COUNTER_WIDTH = $clog2(DIVISOR);

    //----------------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------------
    reg [COUNTER_WIDTH-1:0] over_cnt_reg, over_cnt_next;
    reg [3:0]               div16_cnt_reg, div16_cnt_next; // 4-bit counter (0 to 15)
    reg                     over_tick_reg, over_tick_next;
    reg                     tick_reg, tick_next;

    //----------------------------------------------------------------------------
    // Output Port Binding (Continuous Assignments)
    //----------------------------------------------------------------------------
    assign baud_over_tick = over_tick_reg;
    assign baud_tick      = tick_reg;

    //----------------------------------------------------------------------------
    // Sequential Logic: Synchronous Reset & Register Updates
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            over_cnt_reg  <= {COUNTER_WIDTH{1'b0}};
            div16_cnt_reg <= 4'd0;
            over_tick_reg <= 1'b0;
            tick_reg      <= 1'b0;
        end else begin
            over_cnt_reg  <= over_cnt_next;
            div16_cnt_reg <= div16_cnt_next;
            over_tick_reg <= over_tick_next;
            tick_reg      <= tick_next;
        end
    end

    //----------------------------------------------------------------------------
    // Combinational Logic: Next-State & Tick Generation Decode
    //----------------------------------------------------------------------------
    always @(*) begin
        // Default assignments to prevent unintentional latch inference
        over_cnt_next  = over_cnt_reg;
        div16_cnt_next = div16_cnt_reg;
        over_tick_next = 1'b0; // Default to 0; pulses high for exactly 1 clock cycle
        tick_next      = 1'b0;

        // 1. Generate the 16x Oversampling Tick
        if (over_cnt_reg == (DIVISOR - 1)) begin
            over_cnt_next  = {COUNTER_WIDTH{1'b0}};
            over_tick_next = 1'b1;

            // 2. Cascade: Increment div16 counter ONLY when 16x tick fires
            if (div16_cnt_reg == (OVERSAMPLE_RATE - 1)) begin
                div16_cnt_next = 4'd0;
                tick_next      = 1'b1; // Fires exactly once every 16 oversample pulses!
            end else begin
                div16_cnt_next = div16_cnt_reg + 1'b1;
            end

        end else begin
            over_cnt_next = over_cnt_reg + 1'b1;
        end
    end

endmodule