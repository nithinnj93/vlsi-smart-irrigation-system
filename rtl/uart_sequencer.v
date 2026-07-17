`timescale 1ns / 1ps

module uart_sequencer (
    input  wire         clk,
    input  wire         reset,
    input  wire [111:0] packet_bytes,
    input  wire         tx_busy,
    
    output reg          tx_start,
    output reg  [7:0]   tx_data
);

    reg [3:0] index;
    reg [1:0] state;

    always @(posedge clk) begin
        if (reset) begin
            index    <= 0;
            state    <= 0;
            tx_start <= 0;
        end else begin
            case (state)
                0: begin // Wait for busy to clear
                    if (!tx_busy) state <= 1;
                end
                1: begin // Send current byte
                    tx_data  <= packet_bytes[(13-index)*8 +: 8];
                    tx_start <= 1;
                    state    <= 2;
                end
                2: begin // Wait for TX to acknowledge
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