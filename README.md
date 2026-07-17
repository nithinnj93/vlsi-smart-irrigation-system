# 🌱 RTL Smart Irrigation Controller

> **A modular Verilog RTL implementation of a Smart Irrigation Controller featuring digital signal processing, UART communication, self-checking verification, and planned ESP32 IoT integration.**

![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Verification](https://img.shields.io/badge/Verification-Self--Checking-green)
![UART](https://img.shields.io/badge/UART-8N1-orange)
![Status](https://img.shields.io/badge/Project-Completed-brightgreen)

---

# 📖 Project Overview

The **RTL Smart Irrigation Controller** is a hardware-centric implementation of an automated irrigation system using **Verilog HDL**.

Unlike conventional Arduino-based irrigation projects where all control logic executes in software, this project implements the complete decision-making pipeline as synthesizable RTL.

The controller continuously processes soil moisture data, filters sensor noise, determines irrigation status, controls the water pump through a finite state machine (FSM), and generates UART telemetry for external monitoring.

The project demonstrates **RTL Design, Digital Signal Processing, Hardware Verification, UART Communication, and Hardware/Software Co-Design**.

---

# 🎯 Project Objectives

- Design a modular RTL-based Smart Irrigation Controller
- Develop reusable Verilog IP blocks
- Implement finite state machine (FSM) based pump control
- Filter noisy sensor inputs using digital signal processing
- Generate real-time UART telemetry
- Verify every module using self-checking testbenches
- Build a recruiter-quality VLSI portfolio project
- Integrate the hardware design with an ESP32 IoT platform (future work)

---

# ⭐ Key Highlights

- ✅ Modular RTL architecture
- ✅ Parameterized Verilog design
- ✅ UART IP Core with 16× oversampling receiver
- ✅ Moving Average Digital Filter
- ✅ Moisture Comparator with fault detection
- ✅ Pump Controller FSM
- ✅ ASCII Telemetry Generator
- ✅ UART Packet Sequencer
- ✅ Self-checking verification environment
- ✅ UART Loopback Verification
- ✅ Full System Integration Testbench

---

# 🏗 System Architecture

```
                 Soil Moisture Sensor
                         │
                         ▼
                  Sensor Interface
                         │
                         ▼
                 Digital Filter
                         │
                         ▼
             Moisture Comparator
                         │
                         ▼
                   Pump FSM
                         │
             ┌───────────┴────────────┐
             ▼                        ▼
      Pump Control              ASCII Formatter
                                         │
                                         ▼
                                 UART Sequencer
                                         │
                                         ▼
                                    UART IP Core
                                         │
                                         ▼
                                ESP32 / Serial Terminal
```

---

# 📂 Repository Structure

```
rtl-smart-irrigation-controller
│
├── rtl/
│   ├── sensor_if.v
│   ├── digital_filter.v
│   ├── moisture_comparator.v
│   ├── pump_fsm.v
│   ├── baud_gen.v
│   ├── uart_tx.v
│   ├── uart_rx.v
│   ├── uart_top.v
│   ├── ascii_formatter.v
│   ├── uart_sequencer.v
│   └── irrigation_top.v
│
├── tb/
│   ├── sensor_if_tb.v
│   ├── digital_filter_tb.v
│   ├── moisture_comparator_tb.v
│   ├── pump_fsm_tb.v
│   ├── baud_gen_tb.v
│   ├── uart_tx_tb.v
│   ├── uart_rx_tb.v
│   ├── uart_loopback_tb.v
│   ├── uart_top_tb.v
│   ├── uart_status_gen_tb.v
│   └── irrigation_top_tb.v
│
├── waveforms/
│
├── docs/
│
└── README.md
```

---

# 🧩 RTL Modules

| Module | Description |
|----------|-------------|
| **sensor_if** | Synchronizes asynchronous sensor interface using CDC synchronization |
| **digital_filter** | Moving average filter for noise suppression |
| **moisture_comparator** | Dual-threshold comparator with sensor fault detection |
| **pump_fsm** | Finite State Machine controlling irrigation pump |
| **baud_gen** | Parameterized UART baud generator |
| **uart_tx** | UART transmitter (8-N-1) |
| **uart_rx** | 16× oversampling UART receiver |
| **uart_top** | Complete reusable UART IP wrapper |
| **ascii_formatter** | Converts system status into ASCII telemetry |
| **uart_sequencer** | Streams telemetry packets over UART |
| **irrigation_top** | Complete Smart Irrigation Controller |

---

# 📡 UART Telemetry

Example telemetry packet:

```
M:085 P:1 S:0
```

Where:

| Field | Meaning |
|--------|---------|
| **M** | Moisture Percentage |
| **P** | Pump Status |
| **S** | System Status |

Example:

```
M:085 P:1 S:0
```

means:

- Moisture = **85%**
- Pump = **ON**
- System = **Normal**

---

# 🧪 Verification Strategy

Every RTL module is independently verified before system integration.

Verification includes:

- Self-checking testbenches
- Functional verification
- PASS / FAIL scoreboards
- Boundary condition testing
- Corner-case testing
- UART loopback verification
- System integration testing
- Waveform generation using GTKWave

---

# ✅ Verification Coverage

| Module | Status |
|---------|--------|
| Sensor Interface | ✅ Verified |
| Digital Filter | ✅ Verified |
| Moisture Comparator | ✅ Verified |
| Pump FSM | ✅ Verified |
| Baud Generator | ✅ Verified |
| UART Transmitter | ✅ Verified |
| UART Receiver | ✅ Verified |
| UART Loopback | ✅ Verified |
| UART Top | ✅ Verified |
| UART Status Generator | ✅ Verified |
| Irrigation Top | ✅ Verified |

---

# 🔄 Data Flow

```
ADC Sensor
      │
      ▼
Sensor Interface
      │
      ▼
Digital Filter
      │
      ▼
Moisture Comparator
      │
      ▼
Pump FSM
      │
      ▼
ASCII Formatter
      │
      ▼
UART Sequencer
      │
      ▼
UART Top
      │
      ▼
Serial Terminal / ESP32
```

---

# ▶ Running Simulation

Compile:

```bash
iverilog -o sim rtl/*.v tb/<testbench>.v
```

Run:

```bash
vvp sim
```

Example:

```bash
iverilog -o uart_top_sim rtl/*.v tb/uart_top_tb.v
vvp uart_top_sim
```

---

# 🛠 Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- Visual Studio Code
- Git
- GitHub
- ESP32 (Planned)
- Embedded C (Planned)

---

# 📚 Concepts Demonstrated

- RTL Design
- Finite State Machines (FSM)
- UART Communication
- Clock Domain Crossing (CDC)
- Digital Signal Processing
- Parameterized Verilog
- Modular Hardware Design
- Hierarchical RTL Integration
- Hardware Verification
- Self-checking Testbenches
- Loopback Testing
- Hardware/Software Co-Design

---

# 🚀 Future Enhancements

- ESP32 IoT Integration
- MQTT Cloud Connectivity
- FPGA Implementation (Vivado / Quartus)
- Binary-to-BCD Hardware Converter
- SPI Sensor Interface
- I²C Sensor Interface
- PWM Pump Speed Control
- Multi-zone Irrigation Support
- OpenLane ASIC Flow
- Physical Design Exploration
- SystemVerilog Assertions
- Continuous Integration (GitHub Actions)

---

# 👨‍💻 Author

## Nithin N J

**Bachelor of Engineering**

**VLSI Design and Technology**

GitHub: **https://github.com/nithinnj93**

---

# 📜 License

This project is released under the **MIT License**.

---

## ⭐ Acknowledgement

This project was developed as part of a personal VLSI learning journey to gain practical experience in RTL design, digital verification, and hardware system integration while building a recruiter-oriented engineering portfolio.
---

## License

This project is developed for educational purposes and VLSI learning.
