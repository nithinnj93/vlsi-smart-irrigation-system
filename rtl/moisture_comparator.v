`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Project Name:  RTL Smart Irrigation Controller
// Module Name:   moisture_comparator
// Author:        Nithin N J
// Description:   
//   Industry-grade combinational threshold comparator with hysteresis support
//   and ADC open/short circuit fault protection. Evaluates filtered moisture
//   against programmable low/high thresholds to generate clean pump FSM triggers.
//////////////////////////////////////////////////////////////////////////////////

module moisture_comparator #(
    parameter DATA_WIDTH = 8
)(
    // Data Inputs
    input  wire [DATA_WIDTH-1:0] moisture_in, // Filtered sensor reading
    input  wire [DATA_WIDTH-1:0] thresh_low,  // Pump ON threshold (e.g., 30%)
    input  wire [DATA_WIDTH-1:0] thresh_high, // Pump OFF threshold (e.g., 70%)

    // Control & Telemetry Outputs
    output wire                  dry_trigger,  // Triggers pump ON
    output wire                  wet_trigger,  // Triggers pump OFF
    output wire                  sensor_fault, // High if open/short circuit detected
    output wire [1:0]            status_code   // 00:Optimal, 01:Dry, 10:Wet, 11:Fault
);

    //----------------------------------------------------------------------------
    // Status Encoding Parameters
    //----------------------------------------------------------------------------
    localparam [1:0] STAT_OPTIMAL = 2'b00,
                     STAT_DRY     = 2'b01,
                     STAT_WET     = 2'b10,
                     STAT_FAULT   = 2'b11;

    //----------------------------------------------------------------------------
    // 1. Hardware Fault Detection (Open / Short Circuit Protection)
    //----------------------------------------------------------------------------
    // Raw ADC readings of all-0s (GND short) or all-1s (VCC pull-up open) indicate broken sensor wire
    assign sensor_fault = (moisture_in == {DATA_WIDTH{1'b0}}) || 
                          (moisture_in == {DATA_WIDTH{1'b1}});

    //----------------------------------------------------------------------------
    // 2. Gated Threshold Comparisons (Fail-Safe Override)
    //----------------------------------------------------------------------------
    // If a sensor fault exists, force triggers to 0 to prevent runaway pump activation
    assign dry_trigger = (!sensor_fault) && (moisture_in < thresh_low);
    assign wet_trigger = (!sensor_fault) && (moisture_in >= thresh_high);

    //----------------------------------------------------------------------------
    // 3. Priority Encoded Telemetry Status
    //----------------------------------------------------------------------------
    assign status_code = sensor_fault ? STAT_FAULT   :
                         dry_trigger  ? STAT_DRY     :
                         wet_trigger  ? STAT_WET     : STAT_OPTIMAL;

endmodule