`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   digital_filter
// Author:        Nithin N J
// Description:   
//   Industry-grade Recursive Moving Average (Boxcar) Digital Filter.
//   Optimized for ASIC/FPGA DSP architectures: utilizes power-of-2 bit-shifting
//   to eliminate hardware dividers, and an O(1) running-sum accumulator to
//   prevent deep combinational adder trees.
//////////////////////////////////////////////////////////////////////////////////

module digital_filter #(
    parameter DATA_WIDTH  = 8, // 8-bit ADC input resolution
    parameter WINDOW_BITS = 3  // Window size N = 2^3 = 8 taps
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  sample_valid, // High when new ADC sample is ready
    input  wire [DATA_WIDTH-1:0] data_in,      // Raw noisy moisture sensor reading

    output wire [DATA_WIDTH-1:0] data_out,     // Filtered, smoothed moisture reading
    output reg                   filter_valid  // High once filter pipeline is active
);

    //----------------------------------------------------------------------------
    // Derived Parameters
    //----------------------------------------------------------------------------
    localparam TAP_COUNT   = 1 << WINDOW_BITS;          // 2^3 = 8 taps
    localparam ACCUM_WIDTH = DATA_WIDTH + WINDOW_BITS;  // 8 + 3 = 11 bits to prevent overflow

    //----------------------------------------------------------------------------
    // Internal Registers & Memory Array
    //----------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0]  tap_reg [0:TAP_COUNT-1]; // Shift register memory array
    reg [ACCUM_WIDTH-1:0] sum_reg;                 // Running accumulator
    
    integer i;

    //----------------------------------------------------------------------------
    // Continuous Assignment: Hardwired Division via Bit-Shifting (>> WINDOW_BITS)
    //----------------------------------------------------------------------------
    // Takes the top DATA_WIDTH bits of the accumulator, discarding the remainder
    assign data_out = sum_reg[ACCUM_WIDTH-1 : WINDOW_BITS];

    //----------------------------------------------------------------------------
    // Sequential Logic: Shift Register Pipeline & Recursive Accumulator
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            sum_reg      <= {ACCUM_WIDTH{1'b0}};
            filter_valid <= 1'b0;
            for (i = 0; i < TAP_COUNT; i = i + 1) begin
                tap_reg[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (sample_valid) begin
            // 1. Recursive Running Sum: Add newest sample, subtract oldest sample
            sum_reg <= sum_reg + data_in - tap_reg[TAP_COUNT-1];

            // 2. Advance Shift Register Pipeline
            tap_reg[0] <= data_in;
            for (i = 1; i < TAP_COUNT; i = i + 1) begin
                tap_reg[i] <= tap_reg[i-1];
            end

            // 3. Assert valid flag once the first valid sample enters the filter
            filter_valid <= 1'b1;
        end
    end

endmodule