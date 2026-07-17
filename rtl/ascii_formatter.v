`timescale 1ns / 1ps

module ascii_formatter (
    input  wire [7:0] moisture,
    input  wire       pump_on,
    input  wire [1:0] status,
    
    // Output is a flat bus of 14 bytes (112 bits)
    output wire [111:0] packet_bytes
);

    // M:085 P:1 S:0\n
    // Byte indices: 01234567890123
    assign packet_bytes[111:104] = "M";
    assign packet_bytes[103:96]  = ":";
    assign packet_bytes[95:88]   = (moisture/100) + "0";
    assign packet_bytes[87:80]   = ((moisture/10)%10) + "0";
    assign packet_bytes[79:72]   = (moisture%10) + "0";
    assign packet_bytes[71:64]   = " ";
    assign packet_bytes[63:56]   = "P";
    assign packet_bytes[55:48]   = ":";
    assign packet_bytes[47:40]   = pump_on + "0";
    assign packet_bytes[39:32]   = " ";
    assign packet_bytes[31:24]   = "S";
    assign packet_bytes[23:16]   = ":";
    assign packet_bytes[15:8]    = status + "0";
    assign packet_bytes[7:0]     = 8'h0A; // \n

endmodule