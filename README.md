# TERRA SENSE – FPGA-Based Worker Safety Wearable

**FPGA-based worker safety wearable for real-time mine safety monitoring, hazard alerts, communication-loss detection, and emergency SOS reporting.**

## Project Overview

TERRA SENSE is an AI-enabled mine subsidence monitoring and early-warning system designed to improve underground worker safety.

My contribution focuses on the **FPGA-based worker safety wearable**, implemented using Verilog HDL on the Digilent Arty A7-100T FPGA board.

The FPGA receives risk information from an ESP32 through UART, validates incoming packets using CRC, updates the worker safety state, and activates visual and audio alerts. It also provides an OLED status display and supports emergency SOS reporting back to the ESP32.

## My FPGA Contribution

- Developed the Verilog RTL architecture for the worker safety band.
- Implemented UART-based communication and packet reception.
- Designed packet parsing and CRC-8 validation.
- Implemented a safety Finite State Machine (FSM).
- Integrated a watchdog timer for communication-loss detection.
- Developed RGB LED and buzzer-based alert control.
- Integrated an SSD1331 OLED display using SPI.
- Implemented local SOS activation and UART-based emergency reporting.

## System Architecture

```text
Mine Monitoring Sensors
          |
          v
 ESP32 Gateway / Backend
          |
          v
  Worker ESP32 Controller
          |
          | UART
          v
+----------------------------+
|       FPGA Worker Band     |
|                            |
|       UART Receiver        |
|             |              |
|       Packet Parser        |
|             |              |
|       CRC Validation       |
|             |              |
|       Safety FSM           |
|          /   \             |
|    Watchdog  SOS Control   |
|          |                 |
|    Alert Controller        |
|          |                 |
+----------------------------+
       |       |       |
       v       v       v
     RGB LED  Buzzer  OLED
```

The FPGA performs deterministic safety monitoring and alert control. AI-based anomaly detection is handled by the project's backend, not by the FPGA.

## Hardware Platform

| Component | Specification |
|---|---|
| FPGA Board | Digilent Arty A7-100T |
| FPGA Device | XC7A100T |
| Development Tool | Xilinx Vivado |
| HDL | Verilog |
| Clock Frequency | 100 MHz (hardware) |
| UART Baud Rate | 115200 (hardware) |
| Display | SSD1331 OLED, 96 × 64 |
| Display Interface | SPI |

## RTL Module Description

| Module | Function |
|---|---|
| `worker_band_top.v` | Top-level integration |
| `uart_rx.v` | Receives UART data |
| `uart_tx.v` | Transmits UART data |
| `packet_parser.v` | Extracts packet fields |
| `crc_checker.v` | Validates packet integrity |
| `watchdog.v` | Detects communication timeout |
| `safety_fsm.v` | Controls worker safety states |
| `alert_controller.v` | Controls RGB LED and buzzer |
| `sos_event_controller.v` | Generates SOS event |
| `sos_controller.v` | Handles SOS control logic |
| `uart_report_controller.v` | Sends emergency report |
| `oled_ssd1331.v` | Controls OLED display |

## Safety States

| State | Description | Indication |
|---|---|---|
| SAFE | Normal operating condition | Green LED |
| WATCH | Initial risk condition | Yellow LED |
| WARNING | Elevated risk condition | Yellow LED |
| CRITICAL | Critical hazard detected | Red LED + Buzzer |
| COMM_LOSS | Communication timeout | Red LED + Buzzer |
| SOS | Emergency button activated | Red + Blue LED + Buzzer |

## UART Communication Protocol

### Incoming Packet (ESP32 → FPGA)

| Field | Description |
|---|---|
| `AA` | Start byte |
| `NODE_ID` | Sensor node identifier |
| `RISK` | Risk classification |
| `VALID` | Data validity flag |
| `SEQ` | Sequence number |
| `SOS` | SOS status |
| `CRC` | CRC-8 checksum |

**Packet length:** 7 bytes

CRC-8 uses polynomial `0x07`.

### Emergency Report (FPGA → ESP32)

The FPGA sends an emergency report when the worker activates the local SOS button.

```text
A5 | TYPE | NODE_ID | RISK | SEQ | CRC
```

Example verified SOS report:

```text
A5 01 02 03 07 F4
```

**Packet length:** 6 bytes

## Simulation and Verification

The complete worker band RTL was tested using the `worker_band_tb.v` testbench.

**9/9 functional test cases passed.**

| Test | Scenario |
|---|---|
| 1 | Normal SAFE packet reception |
| 2 | Invalid CRC detection |
| 3 | Invalid VALID flag detection |
| 4 | WARNING state transition |
| 5 | CRITICAL state transition |
| 6 | Return to SAFE state |
| 7 | Watchdog timeout and COMM_LOSS |
| 8 | Local SOS button activation |
| 9 | SOS UART location report |

The simulation uses shorter testbench timing parameters to make verification faster. These are separate from the hardware clock and UART settings listed above.

## Simulation Waveforms

The following waveforms demonstrate the functional verification of the FPGA-based worker safety band.

### 1. UART Reception and Packet Validation

![UART Reception and Packet Validation](images/UART%20reception%20and%20packet%20validation.png)

### 2. Safety FSM and Alert Outputs

![Safety FSM and Alert Outputs](images/Safety%20FSM%20and%20alert%20outputs.png)

### 3. Watchdog and Communication Loss

![Watchdog and Communication Loss](images/Watchdog%20and%20communication%20loss.png)

### 4. Local SOS Activation

![Local SOS Activation](images/Local%20SOS%20activation.png)

### 5. SOS UART Location Report

![SOS UART Location Report](images/SOS%20UART%20location%20report.png)

## FPGA Hardware Demonstrations

The following videos demonstrate the FPGA implementation on the physical hardware.

### 1. Complete FPGA Worker Safety Band Demonstration

[▶ Watch Complete FPGA Demonstration](demo/complete_fpga_demo.mp4)

Demonstrates the overall worker safety band functionality, including OLED status display and safety alerts.

### 2. Emergency SOS Button Demonstration

[▶ Watch SOS Emergency Demonstration](demo/sos_emergency.mp4)

Demonstrates local SOS activation and emergency reporting functionality.

## Repository Structure

```text
terra-sense-fpga-worker-band/
│
├── README.md
├── alert_controller.v
├── crc_checker.v
├── oled_ssd1331.v
├── oled_ssd1331_tb.v
├── packet_parser.v
├── safety_fsm.v
├── sos_controller.v
├── sos_event_controller.v
├── uart_report_controller.v
├── uart_rx.v
├── uart_tx.v
├── watchdog.v
├── worker_band_tb.v
├── worker_band_top.v
├── worker_band_top.xdc
│
├── images/
│   ├── 01_uart_crc_validation.png
│   ├── 02_safety_fsm_transitions.png
│   ├── 03_watchdog_comm_loss.png
│   ├── 04_local_sos_activation.png
│   └── 05_sos_uart_location_report.png
│
└── demo/
    ├── complete_fpga_demo.mp4
    └── sos_button_demo.mp4
```

## Key VLSI and Digital Design Concepts

- Verilog RTL design
- Finite State Machine (FSM) design
- UART serial communication
- SPI communication
- CRC-based data integrity checking
- Watchdog timer implementation
- Sequential and combinational logic
- FPGA top-level integration
- Hardware debugging and simulation

## Project Context

This FPGA worker safety wearable was developed as the hardware component of the TERRA SENSE team project for mine subsidence monitoring and early warning.

This repository showcases my FPGA/RTL contribution to the overall system.

---

**Tools:** Verilog HDL | Xilinx Vivado | Digilent Arty A7-100T | UART | SPI | SSD1331 OLED

**License:** MIT
