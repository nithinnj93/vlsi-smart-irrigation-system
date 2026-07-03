# RTL Smart Irrigation Controller Architecture

## Overview

The Smart Irrigation Controller is a Hardware/Software Co-Design project developed using Verilog HDL and ESP32.

The hardware section is implemented as RTL modules.

The software section runs on an ESP32 which reads moisture sensor data and communicates with the RTL controller.

---

## System Architecture

```
         Soil Moisture Sensor
                  │
                  ▼
             ESP32 ADC
                  │
                  ▼
        Digital Moisture Filter
                  │
                  ▼
        Moisture Comparator
                  │
                  ▼
           Pump FSM Controller
                  │
          ┌───────┴────────┐
          ▼                ▼
      Water Pump       UART TX
                              │
                              ▼
                     Serial Monitor
```

---

## RTL Modules

- Digital Filter
- Moisture Comparator
- Pump Controller FSM
- UART Transmitter
- Top Module (Future)

---

## Future Improvements

- UART Receiver
- AXI Interface
- Wishbone Bus
- FPGA Implementation
- ASIC Flow