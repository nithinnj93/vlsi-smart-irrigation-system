`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   sensor_if
// Author:        Nithin N J
// Description:   
//   Industry-grade Clock Domain Crossing (CDC) Sensor Interface.
//   Utilizes a 2-stage D-flip-flop synchronizer to mitigate metastability when
//   capturing asynchronous ADC valid strobes, an internal rising-edge detector
//   to generate 1-cycle enable pulses, and a registered data-capture pipeline
//   to guarantee 100% lockstep alignment between control strobes and data.
//////////////////////////////////////////////////////////////////////////////////

module sensor_if #(
    parameter DATA_WIDTH = 8
)(
    // System Clock Domain
    input  wire                  clk,
    input  wire                  reset,

    // Asynchronous External Interface (From Sensor / ADC)
    input  wire                  async_valid_in, // Asynchronous data ready strobe
    input  wire [DATA_WIDTH-1:0] async_data_in,  // Raw noisy ADC data bus

    // Synchronous Internal Interface (To Digital Filter)
    output wire                  sample_valid_out, // Clean 1-cycle system clock pulse
    output wire [DATA_WIDTH-1:0] data_out          // Synchronized, stable sensor reading
);

    //----------------------------------------------------------------------------
    // Internal Registers (CDC Synchronization & Edge Detection Pipeline)
    //----------------------------------------------------------------------------
    reg                  valid_meta_reg;  // Stage 1: Metastability catching flop
    reg                  valid_sync_reg;  // Stage 2: Synchronized stable flop
    reg                  valid_old_reg;   // Stage 3: History flop for edge detection
    reg                  valid_pulse_reg; // Stage 4: Registered output strobe (prevents skew!)
    
    reg [DATA_WIDTH-1:0] data_reg;        // Synchronous data capture register

    //----------------------------------------------------------------------------
    // Output Port Binding (Continuous Assignments to Registered Flops)
    //----------------------------------------------------------------------------
    assign sample_valid_out = valid_pulse_reg;
    assign data_out         = data_reg;

    //----------------------------------------------------------------------------
    // Sequential Logic: 2-Flop CDC Pipeline & Lockstep Data Capture
    //----------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            valid_meta_reg  <= 1'b0;
            valid_sync_reg  <= 1'b0;
            valid_old_reg   <= 1'b0;
            valid_pulse_reg <= 1'b0;
            data_reg        <= {DATA_WIDTH{1'b0}};
        end else begin
            // 1. Shift through the 2-flop CDC synchronizer
            valid_meta_reg <= async_valid_in;
            valid_sync_reg <= valid_meta_reg;
            
            // 2. Capture history for edge detection
            valid_old_reg  <= valid_sync_reg;

            // 3. Registered Edge Pulse: Fires high for exactly 1 clock cycle
            valid_pulse_reg <= (valid_sync_reg & ~valid_old_reg);

            // 4. Lockstep Data Latch: Captures data on the exact same edge as the pulse!
            if (valid_sync_reg & ~valid_old_reg) begin
                data_reg <= async_data_in;
            end
        end
    end

endmodule