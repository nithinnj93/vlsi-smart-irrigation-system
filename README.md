# RTL Smart Irrigation Controller

> A Hardware/Software Co-Design project implementing a Smart Irrigation Controller using Verilog RTL, FSM-based control, digital verification, and ESP32 IoT integration.

---

## Project Overview

This project combines **Digital VLSI Design** and **Internet of Things (IoT)** to develop a smart irrigation system capable of automatically controlling water pumps based on soil moisture conditions.

Unlike conventional Arduino-based irrigation systems, the core decision-making logic is implemented in **Verilog RTL**, making the project suitable for learning digital design, verification, and hardware-software co-design.

---

## Objectives

- Design an RTL-based irrigation controller.
- Implement hardware decision-making using Verilog.
- Develop FSM-based pump control.
- Verify functionality using self-checking testbenches.
- Integrate RTL modules with ESP32 for IoT monitoring.
- Build a recruiter-friendly VLSI portfolio project.

---

## Project Architecture

```
                Soil Moisture Sensor
                         │
                         ▼
                 ESP32 / ADC Interface
                         │
                         ▼
            +---------------------------+
            | Moisture Comparator RTL   |
            +---------------------------+
                         │
                         ▼
            +---------------------------+
            | Digital Moisture Filter   |
            +---------------------------+
                         │
                         ▼
            +---------------------------+
            | Pump Controller FSM       |
            +---------------------------+
                  │              │
                  ▼              ▼
          Alarm Controller    UART Interface
                  │              │
                  └──────┬───────┘
                         ▼
                  IoT Cloud Dashboard
```

---

# Features

- Verilog RTL Design
- FSM-Based Pump Controller
- Soil Moisture Comparator
- Digital Moisture Filtering
- Self-checking Testbenches
- Waveform Generation (VCD)
- ESP32 IoT Integration
- Modular Hardware Architecture

---

# Current Progress

| Module | Status |
|----------|--------|
| Moisture Comparator | ✅ Completed |
| Comparator Testbench | ✅ Completed |
| Pump FSM | ✅ Completed |
| Pump FSM Testbench | ✅ Completed |
| Digital Moisture Filter | 🚧 In Progress |
| UART Transmitter | ⏳ Planned |
| UART Receiver | ⏳ Planned |
| Alarm Controller | ⏳ Planned |
| Top Module | ⏳ Planned |
| ESP32 Integration | ⏳ Planned |

---

# Repository Structure

```
rtl-smart-irrigation-controller
│
├── rtl/
│   ├── moisture_comparator.v
│   ├── pump_fsm.v
│   ├── digital_filter.v
│   ├── uart_tx.v
│   ├── uart_rx.v
│   └── top_module.v
│
├── tb/
│   ├── moisture_comparator_tb.v
│   ├── pump_fsm_tb.v
│   └── ...
│
├── esp32/
│
├── docs/
│
├── waveforms/
│
└── README.md
```

---

# Technologies Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- VS Code
- Git
- GitHub
- ESP32
- Embedded C
- IoT

---

# Verification

Each RTL module is verified using:

- Self-checking Testbenches
- Functional Simulation
- PASS/FAIL Verification
- VCD Waveform Generation

---

# Learning Outcomes

This project demonstrates:

- RTL Design
- Digital Logic Design
- Finite State Machines
- Hardware Verification
- Hardware/Software Co-Design
- Embedded Systems
- IoT Integration

---

# Future Improvements

- Moving Average Digital Filter
- UART Communication
- SPI Interface
- I2C Sensor Interface
- PWM Motor Control
- AI-Based Irrigation Prediction
- FPGA Implementation
- OpenLane ASIC Flow
- Physical Design Exploration

---

# Author

**Nithin N J**

Bachelor of Engineering  
VLSI Design and Technology

---

## License

This project is developed for educational purposes and VLSI learning.
