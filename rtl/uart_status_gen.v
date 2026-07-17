`timescale 1ns / 1ps

module uart_status_gen #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire [7:0]            moisture, // Filtered moisture
    input  wire                  pump_on,  // Pump status
    input  wire [1:0]            status,   // Comparator status
    input  wire                  tx_busy,  // From UART TX
    
    output reg                   tx_start,
    output reg  [DATA_WIDTH-1:0] tx_data
);

    // ASCII Message: "M:XXX P:X S:X\r\n" (14 bytes)
    reg [7:0] packet [0:13];
    reg [3:0] index;
    reg [2:0] state;

    always @(posedge clk) begin
        if (reset) begin
            index <= 0;
            state <= 0;
            tx_start <= 0;
        end else begin
            case (state)
                0: begin // Prepare Packet
                    packet[0] = "M"; packet[1] = ":";
                    packet[2] = (moisture/100) + "0";
                    packet[3] = ((moisture/10)%10) + "0";
                    packet[4] = (moisture%10) + "0";
                    packet[5] = " "; packet[6] = "P"; packet[7] = ":";
                    packet[8] = pump_on + "0";
                    packet[9] = " "; packet[10] = "S"; packet[11] = ":";
                    packet[12] = status + "0"; packet[13] = "\n";
                    state <= 1;
                end
                1: begin // Trigger UART
                    if (!tx_busy) begin
                        tx_data <= packet[index];
                        tx_start <= 1;
                        state <= 2;
                    end
                end
                2: begin
                    tx_start <= 0;
                    if (!tx_busy) begin
                        if (index == 13) index <= 0;
                        else index <= index + 1;
                        state <= 1;
                    end
                end
            endcase
        end
    end
endmodule