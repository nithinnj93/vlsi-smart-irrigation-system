`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   uart_top
// Author:        Nithin N J
// Description:   
//   Standalone, industry-grade Universal Asynchronous Receiver/Transmitter IP Core.
//   Encapsulates baud rate generation, 8-N-1 transmission, and 16x oversampled 
//   reception with EMI glitch rejection into a unified, parameter-driven wrapper.
//////////////////////////////////////////////////////////////////////////////////

module uart_top #(
    parameter CLK_FREQ        = 50000000, // 50 MHz System Clock
    parameter BAUD_RATE       = 115200,   // High-speed IoT standard (ESP32 compatible)
    parameter DATA_WIDTH      = 8,        // Standard 8-bit payload
    parameter OVERSAMPLE_RATE = 16        // 16x Oversampling for Receiver
)(
    // System Clock & Reset
    input  wire                  clk,
    input  wire                  reset,

    // Transmitter Interface (Control Path -> TX)
    input  wire                  tx_start,
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire                  busy,
    output wire                  tx_done,
    output wire                  tx,         // Serial Output to ESP32 / PC

    // Receiver Interface (RX -> Control Path)
    input  wire                  rx,         // Serial Input from ESP32 / PC
    output wire [DATA_WIDTH-1:0] data_out,
    output wire                  rx_done
);

    //----------------------------------------------------------------------------
    // Explicit Internal Interconnect Wire Declarations
    //----------------------------------------------------------------------------
    wire baud_tick;      // 1x Baud Enable Pulse (connects baud_gen to uart_tx)
    wire baud_over_tick; // 16x Baud Enable Pulse (connects baud_gen to uart_rx)

    //----------------------------------------------------------------------------
    // 1. Baud Rate Generator Instantiation (v2 Dual-Output Architecture)
    //----------------------------------------------------------------------------
    baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE_RATE(OVERSAMPLE_RATE)
    ) BAUD_GEN_INST (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),
        .baud_over_tick(baud_over_tick)
    );

    //----------------------------------------------------------------------------
    // 2. UART Transmitter Instantiation
    //----------------------------------------------------------------------------
    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) TX_INST (
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
    // 3. UART Receiver Instantiation (16x Oversampling)
    //----------------------------------------------------------------------------
    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .OVERSAMPLE_RATE(OVERSAMPLE_RATE)
    ) RX_INST (
        .clk(clk),
        .reset(reset),
        .baud_over_tick(baud_over_tick),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

endmodule