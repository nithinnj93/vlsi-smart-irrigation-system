//=========================================================
// Module Name : Moisture Comparator
// Project     : RTL-Based Smart Irrigation Controller
// Author      : Nithin N J
// Description : Compares soil moisture with threshold
//               and generates pump control signal.
//=========================================================

module moisture_comparator (

    input  wire [7:0] moisture,     // Soil moisture (0-100)
    input  wire [7:0] threshold,    // Threshold value

    output reg pump_on              // Pump control output

);

always @(*) begin

    if (moisture < threshold)
        pump_on = 1'b1;
    else
        pump_on = 1'b0;

end
endmodule