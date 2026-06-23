# BANDWIDTH THROTTLER

This document provides the microarchitectural design specification for the Secure Bandwidth Throttler IP. The architecture utilizes a closed-loop system layout running within a single master clock domain to protect downstream components from high-speed data floods.

---

## 1. Top-Level Architecture Overview

The design consists of a sequential data processing pipeline combined with a parallel feedback control loop. 



### Data Pipeline Flow
Data flows sequentially through the following modules:


<img width="1400" height="720" alt="image" src="https://github.com/user-attachments/assets/260b02e7-0e1b-4df5-9d37-9fc712a4124e" />

---

## 2. Component Layout and Functional Microarchitecture

<img width="1073" height="486" alt="image" src="https://github.com/user-attachments/assets/7ffe09ca-084d-4963-9ee3-520b7638d58c" />


### A. Input Stage (`axis_reg_slice`)
* **Purpose:** Acts as the physical isolation layer at the input boundary of the IP block to cut long, high-fanout combinational paths from external pins.
* **Hardware Latency:** Introduces a predictable, single clock cycle propagation delay forward.
* **Internal Block Logic:**
  * Contains a primary register bank and a secondary backup register (`skid_reg`).
  * **Handshake Routing:** Under normal operation, it registers incoming valid data directly to the FIFO.
  * **Backpressure Management:** If the downstream FIFO buffer pulls its ready line low (`slice_to_fifo_tready == 0`), the register slice isolates the system by capturing any in-flight data word inside `skid_reg` on the next clock edge and immediately dropping the external `s_axis_tready` signal. This safely freezes the external sender.

### B. Elastic Memory Buffer (`axis_fifo`)
* **Purpose:** An internal buffer that absorbs traffic bursts while the output side is undergoing rate regulation or experiencing total blockage.
* **Structure:** A 512-word deep internal RAM grid with a 37-bit payload width ($32\text{-bit } TDATA + 4\text{-bit } TKEEP + 1\text{-bit } TLAST$).
* **Internal Block Logic:**
  * **Occupancy Math:** Tracks pointer locations via a write pointer (`wr_ptr_reg`) and a read pointer (`rd_ptr_reg`). The live data volume inside the memory is calculated every clock cycle:
   fifo_occupancy = wr_ptr_reg - rd_ptr_reg
  * **80% High-Watermark Line:** A hardware comparator continuously checks the live occupancy value. The moment the internal depth hits $\ge 410$ words, the dedicated `fifo_watermark_80` signal wire flips high to notify the control state machine.
  * **Simulation Initialization Loop:** On the assertion of a reset (`rst`), an internal loop automatically writes zeros across all 512 memory indices to neutralize uninitialized simulation states ("Red X").

### C. Bandwidth Regulator (`axis_rate_limit`)
* **Purpose:** Acts as the active system throttle valve to enforce strict throughput caps based on feedback commands.
* **Internal Block Logic:**
  * Reads the 8-bit pacing fraction coefficients (`rate_num` and `rate_denom`) issued dynamically by the state machine.
  * **Pacing Pattern Generator:** An internal wrap-around counter counts sequentially from 1 up to the value of `rate_denom` on every clock tick.
  * **Wait-State Injection:** Instead of destructively dropping packets, it cuts throughput by modulating its upstream ready handshake line. When a 25% throughput cap is applied (`01 / 04`), the limiter logic holds its ready line high for exactly 1 clock cycle and forces it low for the next 3 clock cycles. This injects wait-states backwards into the pipeline, causing excess data to gather safely inside the upstream FIFO.

### D. Traffic Monitor (`axis_stat_counter`)
* **Purpose:** Sits passively on the master boundary to serve as a zero-overhead exit flow meter.
* **Internal Block Logic:**
  * **Passive Accumulation:** Continuously snoops on successful output transfers by checking if both master handshake lines are high (`m_axis_tvalid && m_axis_tready`).
  * **Windowed Calculation:** An internal tracking counter measures a fixed observation window (e.g., 1,000 clock periods). Throughout this window, it accumulates the exact number of passing data bytes.
  * **FSM Interfacing:** The moment the observation window timer expires, the block pulses a `status_valid` signal, exposes the total byte sum on the `status_byte_count` bus to update the state machine, and clears its internal accumulators back to zero for the next cycle.

### E. Central Controller (`rate_control_fsm`)
* **Purpose:** The centralized command center linking monitoring metrics to active pacing gates.

* **State Logic & Conditions:**
  1. **`STATE_IDLE` (`3'b001`):** Default unthrottled mode. Sets full pacing capacity (`rate_num = 100`, `rate_denom = 100`). If `status_byte_count > cfg_high_threshold_bytes` OR `fifo_watermark_80 == 1'b1`, it transitions instantly to `STATE_THROTTLE`.
  2. **`STATE_THROTTLE` (`3'b010`):** Active restriction mode. Restricts output capacity to a 25% speed ceiling (`rate_num = 25`, `rate_denom = 100`). Once the windowed byte count drops below `cfg_low_threshold_bytes` AND `fifo_watermark_80` returns to 0, it moves to `STATE_RECOVERY`.
  3. **`STATE_RECOVERY` (`3'b100`):** Safe transition mode. Sets an intermediate 50% capacity cap and initializes a 5,000-clock-cycle countdown timer. If a fresh traffic spike or watermark flag occurs before the timer hits zero, it cancels recovery and jumps immediately back to `STATE_THROTTLE`. It will only return to full speed (`STATE_IDLE`) if the countdown timer successfully runs all the way down to zero.

---

## Top-Level Global Pin Layout & Signal Dictionary

The unified interface layout matches the verified top-level hardware structure, ensuring that every signal is bound to the system's singular master clock domain.

| **Signal Handle** | **Direction** | **Bit Width** | **Functional Mapping & Behavior** |
|-------------------|---------------|---------------|-----------------------------------|
| `clk` | Input | 1 bit | Master System Clock: Synchronously drives all flip-flops, internal dual-port memory arrays, and control structures. |
| `rst` | Input | 1 bit | Synchronous Global Reset: Flushes internal pointer indices, clears memory to suppress simulation "X" states, and resets FSMs to their default state. |
| `s_axis_tdata` | Input | 32 bits | Incoming Data Payload: Wide input data stream received from the upstream AXI-Stream source. |
| `s_axis_tkeep` | Input | 4 bits | Input Byte Qualifiers: Indicates which byte lanes within the 32-bit word contain valid data. |
| `s_axis_tvalid` | Input | 1 bit | Source Stream Validity: Asserted by the source whenever valid data is available. |
| `s_axis_tready` | Output | 1 bit | Upstream Backpressure Signal: Asserted when the internal buffer can accept new data; deasserted to stall the upstream source. |
| `s_axis_tlast` | Input | 1 bit | Source End-of-Frame Marker: Indicates the final transfer of a packet. |
| `m_axis_tdata` | Output | 32 bits | Regulated Master Data Payload: Dynamically throttled output data stream sent to the downstream receiver. |
| `m_axis_tkeep` | Output | 4 bits | Master Byte Qualifiers: Valid byte-lane indicators forwarded with the output data. |
| `m_axis_tvalid` | Output | 1 bit | Master Stream Validity: Asserted whenever throttled output data is available. |
| `m_axis_tready` | Input | 1 bit | Downstream Consumer Readiness: Indicates that the receiver is ready to accept data. |
| `m_axis_tlast` | Output | 1 bit | Master End-of-Frame Marker: Packet boundary indicator propagated to the downstream interface. |
| `cfg_high_threshold_bytes` | Input | 32 bits | Upper Threshold Register: Configures the maximum allowable data volume before throttling begins. |
| `cfg_low_threshold_bytes` | Input | 32 bits | Lower Threshold Register: Defines the recovery threshold at which throttling is released. |
| `cfg_rate_limit_mode` | Input | 1 bit | Operating Mode Select: `0` = Dynamic throttling enabled, `1` = Direct bypass mode. |
| `dynamic_num` | Input | 8 bits | Fractional Shaper Numerator: Configures the active duty-cycle numerator used for rate shaping. |
| `dynamic_denom` | Input | 8 bits | Fractional Shaper Denominator: Configures the duty-cycle denominator determining the shaping resolution. |
| `fifo_watermark_80` | Output | 1 bit | FIFO Occupancy Warning: Asserted when internal FIFO occupancy reaches approximately 80% capacity (≥410 words). |

## 3. Throttling Mechanics

The architecture is defensive because it applies backpressure to both sides of the design simultaneously:

1. **Downstream (Output Side) Throttling:** The FSM commands the rate limiter to pulse its ready lines, shielding downstream processing units from line-rate data floods.
2. **Upstream (Input Side) Throttling:** As wait-states accumulate, data backs up inside the FIFO. If the flood continues, the FIFO runs out of space and drops its input ready line (`s_axis_tready`). This backpressure signal travels up to the input source, forcing the external sender to hold until the system catches up.

---

## 4. Emergency Watermark Overdrive Logic

Under standard operations, the FSM relies on the long-window byte count from the Traffic Monitor to trigger rate regulation. However, if a sudden downstream blockage occurs (`m_axis_tready == 0`), data will pile up rapidly inside the FIFO. 

Waiting for the standard monitoring window to complete its full cycle could take hundreds of clock periods, causing a critical memory overflow. To bypass this delay, the `fifo_watermark_80` signal is wired as an immediate override path directly to the FSM. The exact clock edge where the buffer occupancy hits 410 words, it forces the FSM into `STATE_THROTTLE` on the very next clock cycle. This guarantees instant upstream backpressure propagation and total overflow protection independent of the monitoring window.
