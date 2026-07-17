`timescale 1ns / 1ps

module irrigation_top #(
    parameter DATA_WIDTH = 8,
    parameter MAX_RUN    = 20,
    parameter COOLDOWN   = 10
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  adc_valid_in,
    input  wire [DATA_WIDTH-1:0] adc_data_in,
    output wire                  pump_on,
    output wire                  pump_timeout,
    output wire                  tx
);

    //----------------------------------------------------------------------------
    // Global Interconnect Wires
    //----------------------------------------------------------------------------
    wire                   sample_valid;
    wire [DATA_WIDTH-1:0]  raw_moisture;
    wire [DATA_WIDTH-1:0]  proc_moisture;
    wire                   dry_trig;
    wire                   wet_trig;
    wire                   fault;
    wire [1:0]             status;
    wire [111:0]           packet;
    wire                   tx_start;
    wire [7:0]             tx_byte;
    wire                   uart_busy;

    //----------------------------------------------------------------------------
    // 1. Sensor CDC Interface
    //----------------------------------------------------------------------------
    sensor_if #(DATA_WIDTH) SENSOR_CDC (
        .clk(clk), .reset(reset),
        .async_valid_in(adc_valid_in), .async_data_in(adc_data_in),
        .sample_valid_out(sample_valid), .data_out(raw_moisture)
    );

    //----------------------------------------------------------------------------
    // 2. DSP Filter
    //----------------------------------------------------------------------------
    digital_filter #(DATA_WIDTH, 3) DSP_FILTER (
        .clk(clk), .reset(reset),
        .sample_valid(sample_valid), 
        .data_in(raw_moisture),
        .data_out(proc_moisture)
    );

    //----------------------------------------------------------------------------
    // 3. Moisture Comparator
    //----------------------------------------------------------------------------
    moisture_comparator #(DATA_WIDTH) COMPARATOR (
        .moisture_in(proc_moisture),
        .thresh_low(8'd30), .thresh_high(8'd70),
        .dry_trigger(dry_trig), .wet_trigger(wet_trig),
        .sensor_fault(fault), .status_code(status)
    );

    //----------------------------------------------------------------------------
    // 4. Pump Control FSM
    //----------------------------------------------------------------------------
    pump_fsm #(8, MAX_RUN, COOLDOWN) PUMP_CONTROLLER (
        .clk(clk), .reset(reset),
        .dry_trigger(dry_trig), .wet_trigger(wet_trig), .sensor_fault(fault),
        .pump_on(pump_on), .pump_timeout(pump_timeout), .fsm_state()
    );

    //----------------------------------------------------------------------------
    // 5. Telemetry Pipeline
    //----------------------------------------------------------------------------
    ascii_formatter FORMATTER (
        .moisture(proc_moisture), // Fixed: mapped to proc_moisture
        .pump_on(pump_on), 
        .status(status),
        .packet_bytes(packet)
    );

    uart_sequencer SEQUENCER (
        .clk(clk), .reset(reset), .packet_bytes(packet),
        .tx_busy(uart_busy), .tx_start(tx_start), .tx_data(tx_byte)
    );

    uart_top #(50000000, 115200) UART_IP (
        .clk(clk), .reset(reset),
        .tx_start(tx_start), .data_in(tx_byte),
        .busy(uart_busy), .tx(tx),
        .rx(1'b1) 
    );

endmodule