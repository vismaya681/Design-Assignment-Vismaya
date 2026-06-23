# Secure Bandwidth Throttler IP



| Field              | Value                        |
| ------------------ | ---------------------------- |
| Project            | Secure Bandwidth Throttler   |
| Interface Protocol | AXI-Stream                   |
| Clock Domain       | Single Clock Domain          |
| Data Width         | 32-bit                       |
| FIFO Width         | 37-bit                       |
| FIFO Depth         | 512 Words                    |
| Control Method     | Closed-Loop Dynamic Feedback |


---

# 1. Introduction

The Secure Bandwidth Throttler is a hardware-based traffic regulation IP designed for AXI-Stream systems. The architecture continuously monitors outgoing traffic volume and dynamically regulates bandwidth when traffic exceeds configured operating limits.

The design combines buffering, throughput monitoring, dynamic rate control, and occupancy-based protection mechanisms within a single clock domain.

The primary goal is to protect downstream resources from traffic bursts, congestion events, and sustained high-rate data streams while maintaining AXI-Stream protocol compliance.

---

# 2. Design Objectives

The architecture was developed with the following objectives:

* Monitor output traffic volume continuously.
* Regulate bandwidth when configured thresholds are exceeded.
* Prevent FIFO overflow during downstream stalls.
* Maintain AXI-Stream handshake compliance.

---

# 3. System Architecture Overview

<img width="1400" height="720" alt="image" src="https://github.com/user-attachments/assets/d89d4cd9-3d41-43e8-8ba3-14e53c9bec42" />

The design consists of two major subsystems:

1. Forward Data Path
2. Feedback Control Path

## Forward Data Path

```text
Incoming AXI Stream
        │
        ▼
┌──────────────────────┐
│   axis_reg_slice     │
│    Skid Buffer       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      axis_fifo       │
│ 37-bit × 512 Words   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   axis_rate_limit    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  axis_stat_counter   │
└──────────┬───────────┘
           │
           ▼
      Output AXI Stream
```

---

## Feedback Control Path

```text
axis_stat_counter
         │
         ▼
 status_byte_count
         │
         ▼
┌─────────────────────┐
│  rate_control_fsm   │
└─────────┬───────────┘
          │
          ▼
 rate_num / rate_denom
          │
          ▼
 axis_rate_limit
```

---

## Emergency Protection Path

```text
FIFO Occupancy
      │
      ▼
 Occupancy ≥ 410
      │
      ▼
fifo_watermark_80
      │
      ▼
rate_control_fsm
      │
      ▼
STATE_THROTTLE
```

---

# 4. Data Path Architecture


Data travels through four major processing stages.

```text
Input
  │
  ▼
Register Slice
  │
  ▼
FIFO Buffer
  │
  ▼
Rate Limiter
  │
  ▼
Traffic Counter
  │
  ▼
Output
```

Each stage contributes a specific function to the overall protection mechanism.

---

# 5. Control Path Architecture

The control path operates independently of the payload path.

The Traffic Monitor continuously measures completed AXI transfers.

At the end of each observation window:

```text
Traffic Measurement
        │
        ▼
status_byte_count
        │
        ▼
FSM Decision
        │
        ▼
New Rate Configuration
        │
        ▼
Rate Limiter
```

The FSM uses the reported traffic volume to determine whether the system should remain in normal operation, enter throttling mode, or begin recovery.

---

# 6. Emergency Protection Path

Traffic monitoring operates over a fixed observation window.

A severe downstream blockage may fill the FIFO before the monitoring window completes.

To address this condition, FIFO occupancy is monitored independently.

```text
FIFO Occupancy
       │
       ▼
410 Words Reached
       │
       ▼
fifo_watermark_80 = 1
       │
       ▼
FSM Override
       │
       ▼
Immediate Transition
to THROTTLE State
```

This mechanism allows congestion response based on real-time buffer occupancy rather than waiting for a statistical traffic update.

---

# 7. Module-Level Microarchitecture

<img width="1073" height="486" alt="image" src="https://github.com/user-attachments/assets/b6abff54-583d-4d81-9b46-aa5b648f4f91" />


# A. axis_reg_slice

## Purpose

Provides timing isolation between external sources and internal logic.

## Normal Operation

Incoming transfers are registered and forwarded toward the FIFO.

## Backpressure Condition

If downstream ready becomes deasserted:

1. In-flight data is stored inside skid_reg.
2. Upstream ready is deasserted.
3. External transmission pauses.

This prevents loss of data already accepted by the interface.

---

# B. axis_fifo

## Purpose

Provides elastic buffering during throttling and congestion events.

## Configuration

| Parameter | Value     |
| --------- | --------- |
| Width     | 37 bits   |
| Depth     | 512 words |

## Stored Payload

```text
TDATA  = 32 bits
TKEEP  = 4 bits
TLAST  = 1 bit
----------------
TOTAL  = 37 bits
```

## Internal Architecture

```text
             Write Side
                  │
                  ▼
           wr_ptr_reg
                  │
                  ▼
      ┌──────────────────┐
      │     FIFO RAM     │
      │ 512 × 37 Bits    │
      └──────────────────┘
                  ▲
                  │
           rd_ptr_reg
                  ▲
                  │
             Read Side
```

## Occupancy Calculation

```text
fifo_occupancy
=
wr_ptr_reg - rd_ptr_reg
```

## Watermark Logic

```text
if (fifo_occupancy >= 410)
    fifo_watermark_80 = 1;
```

## Reset Behavior

Upon reset:

* Read pointer cleared.
* Write pointer cleared.
* Occupancy reset.
* Memory initialized to known values.

---

# C. axis_rate_limit

## Purpose

Applies bandwidth restrictions commanded by the FSM.

## Inputs

```text
rate_num
rate_denom
```

## Internal Operation

```text
Counter
 1
 2
 3
 4
 ↓
 Repeat
```

Example:

```text
rate_num   = 1
rate_denom = 4
```

Operation:

```text
Cycle 1 → Allow Transfer

Cycle 2 → Stall

Cycle 3 → Stall

Cycle 4 → Stall
```

Result:

```text
1 transfer every 4 cycles
```

The module regulates throughput by controlling ready handshakes rather than discarding payload data.

---

# D. axis_stat_counter

## Purpose

Monitors completed output transfers.

## Internal Structure

```text
Handshake Detector
        │
        ▼
Byte Counter
        │
        ▼
Window Timer
        │
        ▼
status_byte_count
```

## Measurement Method

A transfer is counted when:

```text
m_axis_tvalid &&
m_axis_tready
```

is true.

The module evaluates TKEEP to determine the number of valid bytes transferred during each handshake.

At the end of the monitoring interval:

```text
status_valid = 1
```

and a new byte count is presented to the FSM.

---

# E. rate_control_fsm

## Purpose

Acts as the central control engine.

Inputs:

```text
status_byte_count
cfg_high_threshold_bytes
cfg_low_threshold_bytes
fifo_watermark_80
```

Outputs:

```text
rate_num
rate_denom
```

---

# 8. FSM Operation

## State Diagram

```text
               +------------------+
               |      IDLE        |
               |100% Throughput   |
               +------------------+
                        │
                        │
 High Threshold OR
 Watermark Trigger
                        │
                        ▼
               +------------------+
               |    THROTTLE      |
               |25% Throughput    |
               +------------------+
                        │
                        │
 Traffic Below Low
 Threshold AND
 Watermark Cleared
                        │
                        ▼
               +------------------+
               |    RECOVERY      |
               |50% Throughput    |
               |Timer Active      |
               +------------------+
                 │            │
                 │            │
Timer Expired    │            │Traffic Spike
                 ▼            │
             +--------+       │
             | IDLE   |◄──────┘
             +--------+
```

---

## STATE_IDLE

Configuration:

```text
rate_num   = 100
rate_denom = 100
```

FSM continuously monitors:

```text
status_byte_count
fifo_watermark_80
```

---

## STATE_THROTTLE

Configuration:

```text
rate_num   = 25
rate_denom = 100
```

Bandwidth is restricted.

FIFO begins absorbing excess traffic.

Backpressure may propagate upstream if congestion persists.

---

## STATE_RECOVERY

Configuration:

```text
rate_num   = 50
rate_denom = 100
```

A 5000-cycle countdown timer begins.

If another traffic surge occurs:

```text
RECOVERY
   │
   ▼
THROTTLE
```

If stability is maintained for the entire timer duration:

```text
RECOVERY
   │
   ▼
IDLE
```

---

# 9. Throttling Mechanism

The throttling sequence occurs as follows:

```text
Traffic Surge
      │
      ▼
Counter Measures Increase
      │
      ▼
FSM Enters THROTTLE
      │
      ▼
Rate Limiter Reduces Throughput
      │
      ▼
FIFO Buffers Excess Data
      │
      ▼
Backpressure Propagates
```

The design regulates flow through handshake control rather than packet removal.

---

# 10. FIFO Watermark Protection

A downstream stall can create congestion faster than the statistical monitoring window can react.

Example:

```text
m_axis_tready = 0
```

Output transfers stop.

Incoming traffic continues.

FIFO occupancy rises.

```text
Occupancy >= 410
```

Watermark activates.

```text
fifo_watermark_80 = 1(fifo_prog_full=1)
```

FSM immediately transitions into throttling mode.

This mechanism provides an additional layer of protection independent of the monitoring window.

---

# 11. Runtime Operational Sequence

```text
Reset
 │
 ▼
STATE_IDLE
 │
 ▼
Normal Traffic
 │
 ▼
Traffic Burst
 │
 ▼
Threshold Crossed
 │
 ▼
STATE_THROTTLE
 │
 ▼
FIFO Buffers Traffic
 │
 ▼
Watermark Event (Optional)
 │
 ▼
Traffic Reduces
 │
 ▼
STATE_RECOVERY
 │
 ▼
Cooldown Timer
 │
 ▼
Stable Traffic
 │
 ▼
STATE_IDLE
```

---




# 13. Signal Dictionary

The Secure Bandwidth Throttler exposes a unified AXI-Stream interface together with configuration and status signals. All interface signals operate within the same master clock domain.

| **Signal Handle** | **Direction** | **Bit Width** | **Functional Mapping & Behavior** |
|-------------------|---------------|---------------|-----------------------------------|
| `clk` | Input | 1 bit | Master system clock driving all sequential logic, memory structures, and control modules. |
| `rst` | Input | 1 bit | Synchronous global reset that clears internal pointers, initializes memory contents, and returns the FSM to its default state. |
| `s_axis_tdata` | Input | 32 bits | Incoming AXI-Stream payload from the upstream source. |
| `s_axis_tkeep` | Input | 4 bits | Byte qualifier indicating which bytes of the 32-bit word contain valid data. |
| `s_axis_tvalid` | Input | 1 bit | Indicates that the upstream source is presenting valid data. |
| `s_axis_tready` | Output | 1 bit | Indicates that the throttler is ready to accept incoming data. Deasserted during backpressure conditions. |
| `s_axis_tlast` | Input | 1 bit | Marks the final transfer of an AXI-Stream packet. |
| `m_axis_tdata` | Output | 32 bits | Regulated output payload forwarded toward the downstream receiver. |
| `m_axis_tkeep` | Output | 4 bits | Byte qualifier associated with the output payload. |
| `m_axis_tvalid` | Output | 1 bit | Indicates that valid output data is available. |
| `m_axis_tready` | Input | 1 bit | Downstream receiver readiness signal. Used by the rate limiter and FIFO to regulate data movement. |
| `m_axis_tlast` | Output | 1 bit | Packet boundary indicator propagated to the downstream interface. |
| `cfg_high_threshold_bytes` | Input | 32 bits | Upper traffic threshold used by the FSM to initiate throttling. |
| `cfg_low_threshold_bytes` | Input | 32 bits | Lower traffic threshold used by the FSM to begin recovery. |
| `cfg_rate_limit_mode` | Input | 1 bit | Operating mode selection (`0` = Dynamic throttling, `1` = Direct bypass). |
| `dynamic_num` | Input | 8 bits | Numerator used by the rate limiter to determine the active portion of the duty cycle. |
| `dynamic_denom` | Input | 8 bits | Denominator used by the rate limiter to determine the pacing window length. |
| `fifo_watermark_80` | Output | 1 bit | Status flag asserted when FIFO occupancy reaches approximately 80% capacity (≥410 words). |

---


# 15. Conclusion

The Secure Bandwidth Throttler combines traffic monitoring, dynamic rate control, elastic buffering, and occupancy-based protection into a single hardware subsystem.

The architecture continuously evaluates outgoing traffic volume while simultaneously monitoring FIFO congestion levels. Together, these mechanisms allow the design to regulate throughput, absorb bursts, respond to downstream stalls, and automatically recover once operating conditions return to normal.

## Part II – Verification & Validation

---

# 14. Verification Overview

The Secure Bandwidth Throttler was functionally verified using a directed Verilog testbench that exercises the complete top-level design under multiple operating conditions. The objective of the verification process is to validate the integrated operation of the Register Slice, FIFO Buffer, Rate Limiter, Traffic Monitor, and Control FSM while maintaining correct AXI-Stream protocol behaviour.

The testbench applies deterministic input stimulus through a sequence of predefined operating phases. Each phase targets a specific feature of the design, allowing both normal operation and congestion handling mechanisms to be observed.

---

# 15. Verification Methodology

Verification was performed through behavioral simulation using a single directed Verilog testbench.

The verification process validates the following functional requirements:

* Correct system initialization after reset
* Normal AXI-Stream packet transfer
* Statistical threshold detection
* Automatic transition into THROTTLE mode
* Recovery after traffic decreases
* FIFO occupancy monitoring
* Emergency watermark protection
* Upstream backpressure propagation
* Recovery after downstream congestion is removed

---

## Simulation Configuration

| Parameter           | Value                         |
| ------------------- | ----------------------------- |
| Simulation Language | Verilog                       |
| Verification Method | Directed Testbench            |
| DUT                 | `axi_stream_rate_limiter_top` |
| Clock Domain        | Single                        |



```

The testbench performs the following functions:

* Generates a continuous 10 ns system clock.
* Applies reset during system initialization.
* Configures the statistical threshold registers.
* Generates AXI-Stream input traffic.
* Exercises both statistical throttling and emergency FIFO protection.
* Records waveform activity and console messages for analysis.

---

## 16 Verification Phases

The complete verification sequence is divided into four phases.

### Phase 1 – Statistical Throttling

After reset is released, continuous AXI-Stream traffic is applied to the input interface while the downstream receiver remains ready to accept data.

Configuration:

* `cfg_high_threshold_bytes = 40`
* `cfg_low_threshold_bytes = 10`
* `cfg_rate_limit_mode = 0`
* `m_axis_tready = 1`

As packets leave the output interface, the traffic statistics counter accumulates the transmitted byte count. Once the measured traffic exceeds the configured high threshold, the FSM transitions from **STATE_IDLE** to **STATE_THROTTLE**. The rate limiter changes its pacing ratio to **1/4**, introducing periodic wait states that reduce the effective output bandwidth while allowing the FIFO to absorb excess incoming traffic.

---

### Phase 2 – Statistical Recovery

Input traffic is stopped while the downstream receiver continues accepting data.

Configuration:

* `s_axis_tvalid = 0`
* `m_axis_tready = 1`

With no additional traffic entering the design, the measured byte count decreases. Once the measured traffic falls below the configured low threshold and the FIFO is no longer near its occupancy limit, the FSM transitions into **STATE_RECOVERY**. During this state, the output bandwidth is limited to **1/2** while the internal cooldown timer counts down. If no additional traffic surge occurs before the timer expires, the FSM returns to **STATE_IDLE**.

---

### Phase 3 – Emergency FIFO Protection

To emulate a downstream blockage, the downstream receiver is forced to stop accepting data while traffic continues entering the design.

Configuration:

* `cfg_high_threshold_bytes = 32'hFFFF_FFFF`
* `m_axis_tready = 0`
* Continuous input traffic

Because the output path is completely blocked, data accumulates inside the FIFO. As the FIFO occupancy approaches approximately 80% capacity, the FIFO asserts the `fifo_watermark_80` signal (generated internally from the programmable-full indication). This signal provides an immediate override to the FSM, causing it to enter or remain in **STATE_THROTTLE** without waiting for the next statistical monitoring window. The resulting backpressure propagates toward the source by deasserting `s_axis_tready`, preventing additional data from entering the FIFO under the simulated conditions.

---

### Phase 4 – Recovery After Downstream Stall

The downstream receiver is enabled again by asserting `m_axis_tready`.

Configuration:

* `m_axis_tready = 1`

The stored packets are gradually transmitted from the FIFO to the output interface. As FIFO occupancy decreases, the watermark signal is cleared. The FSM enters **STATE_RECOVERY**, applies the intermediate **1/2** pacing ratio during the cooldown period, and finally returns to **STATE_IDLE** after the cooldown timer expires without detecting another traffic surge.

---

<img width="1337" height="565" alt="image" src="https://github.com/user-attachments/assets/4678da85-d551-44af-a999-7ac2c81ef94b" />
<img width="1339" height="538" alt="image" src="https://github.com/user-attachments/assets/29c7aff9-88c5-4fb0-a4e8-d15ce234bf17" />



---

## 16.1 Simulation Console Output

The directed testbench prints status messages corresponding to each verification phase.

```text
[150000ns]  [TB] PHASE 1: Flooding traffic to trip Statistical Throttling...

[450000ns]  [TB] PHASE 2: Stopping input to let Statistical module recover...

[1950000ns] [TB] PHASE 3: DOWNSTREAM STALL! Slamming ready LOW...

[6450000ns] [TB] PHASE 4: RECOVERY! Re-opening downstream path...

[10950000ns] [TB] Complete Multi-Phase Simulation Cycle Finished.
```

These messages correspond directly to the waveform timeline and indicate the successful execution of each verification phase.

---

The behavioral simulation demonstrates that the Secure Bandwidth Throttler operates as intended under the evaluated scenarios. The design responds to sustained traffic by reducing throughput through controlled pacing, protects the FIFO during downstream stalls using the watermark mechanism, and returns to normal operation after traffic conditions recover.
