# FPGA-Based Electronic Voting Machine (EVM) with R305 Biometric Authentication

**Repository:** https://github.com/Shxbhh/EVM  
**Languages:** Verilog (~90%), Tcl (~10%)  
**Target Platform:** Xilinx Basys-3 (Artix-7)

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)  
2. [Key Features](#key-features)  
3. [System Architecture](#system-architecture)  
   - [Module Overview](#module-overview)  
   - [Finite-State Machine Flow](#finite-state-machine-flow)  
   - [UART & Biometric Integration](#uart--biometric-integration)  
4. [Hardware & Toolchain](#hardware--toolchain)  
5. [Getting Started](#getting-started)  
   - [Prerequisites](#prerequisites)  
   - [Pin Constraints (`constraints.xdc`)](#pin-constraints-constraintsxdc)  
   - [Building & Programming](#building--programming)  
6. [Usage Instructions](#usage-instructions)  
   - [Fingerprint Enrollment & Verification](#fingerprint-enrollment--verification)  
   - [Casting a Vote](#casting-a-vote)  
   - [Closing Poll & Displaying Results](#closing-poll--displaying-results)  
7. [Directory Structure](#directory-structure)  
8. [Future Enhancements](#future-enhancements)  
9. [Author & Acknowledgments](#author--acknowledgments)  
10. [License](#license)  

---

## 📝 Project Overview

This repository implements a **Smart Electronic Voting Machine (EVM)** entirely in Verilog, synthesized on a Xilinx Basys-3 FPGA. The design ensures that *only* an authenticated polling agent can open the machine—either by scanning a registered fingerprint on the R305 sensor or by entering a hardcoded 4-digit fallback code. Once unlocked, the electorate casts votes for up to four candidates. When voting concludes, the polling agent re-authenticates to close the poll and view tallies. All state transitions (Locked → Open → Voting → Tally) are orchestrated via a single finite-state machine, with real-time feedback on a 4-digit seven-segment display and LED indicators.

---

## ✅ Key Features

- **Biometric Access Control (R305 Sensor):**  
  - Custom **UART TX/RX** modules (`uart_tx.v`, `uart_rx.v`) send commands to and receive responses from the R305 fingerprint reader at 57 600 bps.  
  - FSM stays in **Locked** until it gets a “Match OK” packet from R305—or until the fallback 4-digit code is correctly entered within a timeout.  
  - Helps prevent unauthorized opening of the machine or tampering with vote tallies.

- **Secure Voting Workflow & Visual Feedback:**  
  - **Locked State:** Red LED ON, display shows “LO.”  
  - **Authentication Phase:** Display prompts “FP” (fingerprint) or “Cd” (code); the 2 Hz/1 Hz clocks help blink prompts or time out entry.  
  - **Open (Voting) State:** Green LED ON, “00” blinks at 2 Hz. Voters press one of four debounced buttons to cast a ballot. The display momentarily shows “C1,” “C2,” etc., to confirm the vote.  
  - **Tally (Closed) State:** Blue LED ON. After re-authentication, the FSM sequences through each candidate’s BCD-converted vote count (e.g., “01,” “12,” etc.) on the rightmost two digits, pausing 2 s per candidate.

- **Modular, Scalable Verilog Design:**  
  - **Submodules:**  
    - `7seg.v`: 4-digit seven-segment display driver (BCD→segments).  
    - `binbcd.v`: 8-bit binary → two-digit BCD converter.  
    - `button.v`: Push-button debouncer & single-pulse generator.  
    - `clk1Hz.v` / `clk2Hz.v`: Clock dividers from the 100 MHz input to 1 Hz/2 Hz for prompts and timeouts.  
    - `leds.v`: Controls four on-board LEDs (Locked, Open, Voting, Tally).  
    - `uart_rx.v` / `uart_tx.v`: UART modules (parameterized `CLKS_PER_BIT`) for R305 commands and responses.  
    - `statemachine.v`: Master FSM defines all EVM states and transition logic.  
    - `vm.v`: Top-level wrapper that instantiates every submodule and wires I/Os (buttons, seven-segment, LEDs, UART).  

  - **Reusable Constraints:**  
    - `constraints.xdc` maps all signals to Basys-3 pins (buttons BTN0–BTN7, segments SEG[0–6], AN[0–3], LEDs LD[0–3], PMOD JA[1/2] for UART, 100 MHz clock).  
    - Timing and IOSTANDARD (LVCMOS33) constraints guarantee reliable operation.

  - **Scalable:** Although limited here to four candidates (due to I/O count and display digits), the same code can be ported to a larger FPGA (e.g., Nexys A7) to support 8–16 candidates, a graphical LCD, or networked logging.

---

## 🏗 System Architecture

### Module Overview

| **Filename**    | **Responsibility**                                                                                                                                                                                                                         |
|-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `7seg.v`        | Drives a common-anode 4-digit seven-segment display. Takes up to four 4-bit BCD inputs and multiplexes them at ~1 kHz to show digits 0–9.                                                                                                    |
| `binbcd.v`      | Converts an 8-bit binary vote count (0–255) into two 4-bit BCD digits (tens, ones), so each candidate’s vote total (max 99 here) can be displayed.                                                                                          |
| `button.v`      | Debounces mechanical push buttons (BTN0–BTN7). Outputs a single, clean one-clock-cycle pulse (`o_Button_Pulse`) for each distinct press.                                                                                                     |
| `clk1Hz.v`      | Divides the 100 MHz onboard clock down to 1 Hz. Used to enforce 1 s delays (e.g., “show confirmation for 1 s” or “code entry timeout”).                                                                                                      |
| `clk2Hz.v`      | Divides 100 MHz → 2 Hz. Used to blink “Enter Code” or “FP” prompts at 2 Hz while awaiting authentication.                                                                                                                                   |
| `leds.v`        | Controls four discrete LEDs:  
                 - **LD0 (Green):** Open → Voting state  
                 - **LD1 (Red):** Locked state  
                 - **LD2 (Yellow):** Voting confirmation (while “C#” is displayed)  
                 - **LD3 (Blue):** Closed/Tally state  
                 The module lights exactly one LED based on the current `i_State`.                                                                                                    |
| `uart_rx.v`     | UART Receiver at parameterized baud (57 600 bps). Samples incoming serial data (`i_Rx_Serial`) from the R305. Asserts `o_Rx_DV` and outputs `o_Rx_Byte[7:0]` when a full byte is captured.                                                  |
| `uart_tx.v`     | UART Transmitter at the same baud. Accepts an 8-bit `i_Tx_Byte` and sends it out on `o_Tx_Serial` over the PMOD to the R305. Asserts `o_Tx_Done` when the byte is fully transmitted.                                                       |
| `statemachine.v`| Implements the entire EVM state diagram:  
                 1. **Locked** (Idle, send “Search FP” to R305; wait for match or fallback code)  
                 2. **Open & Ready** (Green LED, blink “00” at 2 Hz, accept votes)  
                 3. **Voting** (Yellow LED, display “C1–C4” for 1 s, increment counters via `binbcd`)  
                 4. **Closed/Tally** (Blue LED, re-authenticate, then cycle each candidate’s vote count on display)  
                 Maintains four 8-bit vote registers, handles code entry via `button.v` + 1 Hz timeout, arms UART commands for enrollment/search.                                                                     |
| `vm.v`          | Top-level integration:  
                 - Wires all submodules (`7seg`, `binbcd`, `button`, `clk1Hz`, `clk2Hz`, `leds`, `uart_rx`, `uart_tx`, `statemachine`)  
                 - Maps physical I/Os: BTN[0–7], SEG[0–6], AN[0–3], LED[0–3], UART_RX, UART_TX, CLK_IN_100MHz.  
                 - Instantiates `statemachine` and routes its signals to displays/LEDs/buttons.                                                                                         |
| `constraints.xdc`| Pin assignment and IOSTANDARD constraints for Basys-3:  
                 - **Buttons (BTN0–BTN7):** PLL’ed to `button.v` inputs (secret code = BTN0–BTN3; votes = BTN4–BTN7).  
                 - **7-Segment (SEG[0–6], AN[0–3]):** Connected to `7seg.v` outputs.  
                 - **LEDs (LD0–LD3):** Driven by `leds.v`.  
                 - **UART (JA[1]=UART_RX, JA[2]=UART_TX):** 3.3 V TTL to R305.  
                 - **Clock (W5):** 100 MHz system clock.  
                 All IOSTANDARDs set to LVCMOS33, with pull-ups enabled on buttons.                                                                                                    |

---

### Finite-State Machine Flow

1. **Locked State**  
   - **Display:** “LO” (both digits) continuously.  
   - **LEDs:** LD1 (Red) ON; others OFF.  
   - **UART:** On reset, FSM immediately issues a “Search Fingerprint” command (bytes `0x01`, page range) via `uart_tx.v`.  
   - **Event Triggers:**  
     - **Fingerprint Match:** R305 returns a specific “Match OK” byte via `uart_rx.v` (assert `o_Rx_DV`). FSM latches match → transition to **Open & Ready**.  
     - **Failed Attempts (×3):** If R305 reports “No Match” three times, FSM displays “FA” for 2 s, then enables fallback.  
     - **Secret-Code Fallback:** Within a 15 s window (driven by `clk1Hz.v`), pressing BTN0 → BTN1 → BTN2 → BTN3 in correct sequence causes a “Cd OK” condition → transition to **Open & Ready**. If the code is wrong or time expires, display “ER” then stay Locked.

2. **Open & Ready State**  
   - **Display:** Rightmost two digits show “00,” blinking at 2 Hz (via `clk2Hz.v`). Leftmost two digits remain blank.  
   - **LEDs:** LD0 (Green) ON; others OFF.  
   - **Accept Votes:** Wait for any of BTN4 (C1), BTN5 (C2), BTN6 (C3), BTN7 (C4) to be pressed. On a valid button pulse (debounced by `button.v`), transition to **Voting** for that candidate.

3. **Voting State**  
   - **Display:** Show “C1,” “C2,” “C3,” or “C4” on the rightmost two digits for exactly 1 s (driven by `clk1Hz.v`).  
   - **LEDs:** LD2 (Yellow) ON during that 1 s.  
   - **Action:** Increment the selected candidate’s 8-bit binary counter. Immediately feed that binary count into `binbcd.v` to update the two BCD-digit registers. After 1 s, return to **Open & Ready** (back to blinking “00”).

4. **Closed/Tally State**  
   - **Trigger:** Polling agent re-authenticates (Fingerprint or Secret Code) while in **Open & Ready**.  
   - **LEDs:** LD3 (Blue) ON; others OFF.  
   - **Display Sequence:** For each candidate i=1..4:  
     1. FSM reads candidate_i_count (8-bit), sends to `binbcd.v` → two BCD digits.  
     2. `7seg.v` displays “XX” (BCD) on the rightmost two digits for 2 s. Leftmost digits show “P1,” “P2,” etc. (encoded as segment patterns).  
     3. After 2 s, clear digits for 0.5 s, then move to next candidate.  
   - **Optional Winner Highlight:** After cycling, FSM can display “Wn” for 3 s beside the candidate with the highest count.  
   - **End State:** Remains in Closed until a hard reset (board reset or power cycle) clears all vote registers.

---

### UART & Biometric Integration

1. **UART Receiver (`uart_rx.v`)**  
   - Parameter `CLKS_PER_BIT` = 100 MHz / 57 600 bps ≈ 1736.  
   - Samples `i_Rx_Serial` on a 16× oversampled clock to detect start bit, data bits, and stop bit.  
   - Asserts `o_Rx_DV` (1-clk pulse) when a valid byte arrives, with the received byte in `o_Rx_Byte[7:0]`.  
   - The FSM monitors specific response codes from R305, including:  
     - **0x00 (Match OK)** → unlock.  
     - **0x02 (No Match)** → failed attempt.  
     - **0x01, 0x02, 0x03** in enrollment handshakes.

2. **UART Transmitter (`uart_tx.v`)**  
   - Same `CLKS_PER_BIT` as the receiver.  
   - Takes an 8-bit `i_Tx_Byte` and, when `i_Tx_DV` is asserted, serializes it on `o_Tx_Serial` for R305. Asserts `o_Tx_Ready` when idle.  
   - The FSM drives byte sequences to command R305:  
     - **Search Fingerprint:** `[0x01, page, 0x00, 0x00]` (page range = 1–20).  
     - **Enroll Fingerprint:** `[0x01, page_address, ...]` to initiate enrollment flow.  
     - **Delete/Other:** If needed for template management.

3. **Fingerprint Workflow in `statemachine.v`**  
   - On reset, FSM sends “Search FP” via `uart_tx.v` and waits on `uart_rx.v`.  
   - If R305 returns “Match OK,” FSM latches that and jumps to **Open & Ready** immediately.  
   - If “No Match,” increment `fail_count`; after three “No Match” replies, display “FA” and allow secret-code fallback.  
   - **Enrollment Trigger:** Holding BTN0+BTN3 together for >3 s in Locked state sends an “Enroll FP” sequence. R305 scans the finger twice, responds with “Enroll OK.” FSM captures that to store a new template in the onboard library.

---

## 🛠 Hardware & Toolchain

- **FPGA Board:**  
  - **Xilinx Basys-3 (Artix-7 XC7A35T)**  
    - 100 MHz system clock, four on-board LEDs, eight push buttons, 4-digit seven-segment display, PMOD headers.  

- **Fingerprint Sensor:**  
  - **R305 (TTL UART, 3.3 V) connected to PMOD JA**  
    - TX → JA1 → `UART_RX` (FPGA)  
    - RX ← JA2 ← `UART_TX` (FPGA)  
    - Ensure PMOD supply (jumper E1) is set to 3.3 V.

- **Development Environment:**  
  - **Vivado Design Suite 2022.2 (WebPack)**  
    - Synthesis, Implementation, Bitstream Generation.  
    - Hardware Manager for on-chip debugging and live I/O.  
  - **Digilent USB-JTAG HS1** (built-in) for programming.

- **Programming & Debugging:**  
  - Use Vivado Hardware Manager → Auto-Connect → Program Device.  
  - Optionally, attach a Logic Analyzer on UART lines to view raw R305 traffic.

---

## 🚀 Getting Started

### Prerequisites

1. **Vivado Installation**  
   - Install Vivado 2022.2 (WebPack license).  
   - Verify `vivado` is in your PATH.

2. **Clone the Repository**  
   ```bash
   git clone https://github.com/Shxbhh/EVM.git
   cd EVM
