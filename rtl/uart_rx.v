`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   uart_rx
// Author:        Nithin N J
// Description:   
//   Industry-grade UART Receiver (8-N-1) using 16x Oversampling Architecture.
//   Features asynchronous start-bit detection, mid-bit sampling for maximum
//   jitter tolerance, and false-start EMI glitch rejection.
//////////////////////////////////////////////////////////////////////////////////

module uart_rx #(
    parameter DATA_WIDTH      = 8,
    parameter OVERSAMPLE_RATE = 16
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  baud_over_tick, // 16x Baud Rate Enable Pulse
    input  wire                  rx,             // Asynchronous Serial Input
    output wire [DATA_WIDTH-1:0] data_out,
    output wire                  rx_done
);

    //----------------------------------------------------------------------------
    // State Encoding
    //----------------------------------------------------------------------------
    localparam [1:0] IDLE      = 2'd0,
                     START_BIT = 2'd1,
                     DATA_BITS = 2'd2,
                     STOP_BIT  = 2'd3;

    //----------------------------------------------------------------------------
    // Internal Registers
    //----------------------------------------------------------------------------
    reg [1:0]            state_reg, state_next;
    reg [3:0]            sample_cnt_reg, sample_cnt_next; // Counts 0 to 15 ticks
    reg [2:0]            bit_cnt_reg, bit_cnt_next;       // Counts 0 to 7 data bits
    reg [DATA_WIDTH-1:0] shift_reg, shift_next;
    reg                  rx_done_reg, rx_done_next;

    //----------------------------------------------------------------------------
    // Output Port Binding (Continuous Assignments)
    //----------------------------------------------------------------------------
    assign data_out = shift_reg;
    assign rx_done  = rx_done_reg;

    //----------------------------------------------------------------------------
    // Sequential Logic: Register Update (Synchronous Reset)
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state_reg      <= IDLE;
            sample_cnt_reg <= 4'd0;
            bit_cnt_reg    <= 3'd0;
            shift_reg      <= {DATA_WIDTH{1'b0}};
            rx_done_reg    <= 1'b0;
        end else begin
            state_reg      <= state_next;
            sample_cnt_reg <= sample_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            shift_reg      <= shift_next;
            rx_done_reg    <= rx_done_next;
        end
    end

    //----------------------------------------------------------------------------
    // Combinational Logic: Next State and Output Decode
    //----------------------------------------------------------------------------
    always @(*) begin
        // Default assignments to prevent unintentional latch inference
        state_next      = state_reg;
        sample_cnt_next = sample_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        shift_next      = shift_reg;
        rx_done_next    = 1'b0;          // Default: 1-cycle pulse on frame completion

        case (state_reg)
            //--------------------------------------------------
            // IDLE: Monitor falling edge on RX line
            //--------------------------------------------------
            IDLE: begin
                if (rx == 1'b0) begin
                    sample_cnt_next = 4'd0;
                    state_next      = START_BIT;
                end
            end

            //--------------------------------------------------
            // START_BIT: Verify at tick 7 (mid-point of start bit)
            //--------------------------------------------------
            START_BIT: begin
                if (baud_over_tick) begin
                    if (sample_cnt_reg == (OVERSAMPLE_RATE / 2) - 1) begin // Tick 7
                        if (rx == 1'b0) begin
                            // Valid start bit verified! Reset counter for data bits
                            sample_cnt_next = 4'd0;
                            bit_cnt_next    = 3'd0;
                            state_next      = DATA_BITS;
                        end else begin
                            // Glitch detected (line bounced back to 1)! Abort to IDLE
                            state_next = IDLE;
                        end
                    end else begin
                        sample_cnt_next = sample_cnt_reg + 1'b1;
                    end
                end
            end

            //--------------------------------------------------
            // DATA_BITS: Sample each bit at tick 15 (mid-point)
            //--------------------------------------------------
            DATA_BITS: begin
                if (baud_over_tick) begin
                    if (sample_cnt_reg == (OVERSAMPLE_RATE - 1)) begin // Tick 15
                        sample_cnt_next = 4'd0;
                        // Shift in received bit (LSB First architecture)
                        shift_next = {rx, shift_reg[DATA_WIDTH-1:1]};
                        
                        if (bit_cnt_reg == (DATA_WIDTH - 1)) begin
                            state_next = STOP_BIT;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1'b1;
                        end
                    end else begin
                        sample_cnt_next = sample_cnt_reg + 1'b1;
                    end
                end
            end

            //--------------------------------------------------
            // STOP_BIT: Wait for mid-point of stop bit, assert done
            //--------------------------------------------------
            STOP_BIT: begin
                if (baud_over_tick) begin
                    if (sample_cnt_reg == (OVERSAMPLE_RATE - 1)) begin // Tick 15
                        rx_done_next = 1'b1; // Pulse rx_done for exactly 1 system clock
                        state_next   = IDLE;
                    end else begin
                        sample_cnt_next = sample_cnt_reg + 1'b1;
                    end
                end
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule