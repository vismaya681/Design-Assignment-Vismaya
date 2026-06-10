# Mealy Sequence Detector for "1110" (Overlapping)


## Task Overview

This task implements a **Mealy Sequence Detector** that detects the binary sequence **1110** using Verilog HDL and verifies its functionality through simulation.

A sequence detector is a Finite State Machine (FSM) used to detect a specific pattern in a serial bit stream. This design uses the **Mealy FSM model**, where the output depends on both the present state and the current input.

The detector is designed to identify the sequence **1110** and supports **overlapping sequence detection**.

---

## Objective

- Design a Mealy FSM to detect the sequence **1110**.
- Implement overlapping sequence detection.
- Simulate and verify the design using Vivado.
- Understand state transitions and FSM operation.

---

## Design Description

### Inputs

| Signal | Width | Description |
|----------|----------|-------------|
| clk | 1 bit | Clock input |
| rst | 1 bit | Reset input |
| din | 1 bit | Serial data input |

### Output

| Signal | Width | Description |
|----------|----------|-------------|
| detected | 1 bit | Sequence detected output |

---

## Sequence to Detect

```text
1110
```

Whenever the input stream contains the pattern **1110**, the output `detected` becomes HIGH (`1`).

---

## Why Mealy FSM?

In a Mealy machine:

- Output depends on the current state and input.
- Detection occurs immediately when the final input bit arrives.
- Requires fewer states compared to a Moore machine.

---

## State Diagram

### States

| State | Meaning |
|---------|---------|
| IDLE | No valid bits detected |
| S1 | Detected "1" |
| S2 | Detected "11" |
| S3 | Detected "111" |

---

### State Transitions

```text
          1
      +------+
      |      v
+------+    +------+
| IDLE |--->|  S1  |
+------+    +------+
   ^           |
   |0          |1
   |           v
   |        +------+
   |        |  S2  |
   |        +------+
   |           |
   |           |1
   |           v
   |        +------+
   +--------|  S3  |
            +------+
              |
              |0
              | Detected = 1
              v
            IDLE
```

---

## State Encoding

```verilog
parameter idle = 2'b00;
parameter s1   = 2'b01;
parameter s2   = 2'b10;
parameter s3   = 2'b11;
```

---

## Working Principle

### State: IDLE

No valid sequence detected yet.

```text
Input 0 → Stay in IDLE
Input 1 → Move to S1
```

---

### State: S1

Detected first '1'.

```text
Input 0 → Return to IDLE
Input 1 → Move to S2
```

---

### State: S2

Detected "11".

```text
Input 0 → Return to IDLE
Input 1 → Move to S3
```

---

### State: S3

Detected "111".

```text
Input 0 → Sequence 1110 Detected
Input 1 → Stay in S3
```

When input is `0` in state `S3`:

```verilog
detected = 1;
```

---

## Overlapping Detection

The detector supports overlapping sequences.

Example:

```text
Input Stream:
11101110

Detected:
   ↑   ↑
```

The detector can identify multiple occurrences of the target sequence in a continuous bit stream.

---

## RTL Structure

```text
             +----------------------+
din -------->|                      |
clk -------->| Mealy Sequence       |
rst -------->| Detector (1110)      |
             |                      |
             +----------------------+
                        |
                        |
                    detected
```

---

## Design Code Explanation

### Present State Logic

The current state is updated on every positive clock edge.

```verilog
always @(posedge clk)
begin
    if(rst)
        ps <= idle;
    else
        ps <= ns;
end
```

---

### Next State Logic

The next state is determined based on:

- Present State (`ps`)
- Current Input (`din`)

```verilog
always @(*)
```

This creates combinational next-state logic.

---

### Detection Logic

The sequence is detected in state `S3` when the input becomes `0`.

```verilog
if(din == 0)
begin
    ns = idle;
    detected = 1;
end
```

This corresponds to receiving:

```text
1110
```

---

## Testbench Description

The testbench verifies the detector using the input sequence:

```text
1 → 1 → 1 → 0
```

Expected operation:

```text
1110 detected
```

Clock generation:

```verilog
always #5 clk_tb = ~clk_tb;
```

Clock period:

```text
10 ns
```

---

## Test Sequence

| Time (ns) | Input (din) |
|------------|------------|
| 10 | 1 |
| 20 | 1 |
| 30 | 1 |
| 40 | 0 |

---

## Expected Results

### Input Stream

```text
1 1 1 0
```

### State Progression

```text
IDLE → S1 → S2 → S3 → DETECT
```

### Detection Output

```text
detected = 1
```

when the final `0` is received.

---

## Simulation

### Tool Used

- Vivado Design Suite
- Verilog HDL

### Steps to Run

1. Create a new Vivado project.
2. Add the following source files:
   - `seq_det1110.v`
   - `seq_det1110_tb.v`
3. Set `seq_det1110_tb.v` as the simulation source.
4. Run **Behavioral Simulation**.
5. Observe the waveform and verify sequence detection.

---

## Simulation Waveform
<img width="1587" height="823" alt="seq_det" src="https://github.com/user-attachments/assets/a09d292f-3d0c-433c-a896-529a0f41777c" />


## Applications

- Pattern Recognition Systems
- Communication Receivers
- Data Stream Monitoring
- Protocol Verification
- Digital Signal Processing
- Error Detection Systems

---

## Features

✔ Mealy FSM Design  
✔ Detects Sequence "1110"  
✔ Overlapping Detection Support  
✔ Synchronous State Transition  
✔ Reset Functionality  
✔ Vivado Simulation Verified

---

## Advantages of Mealy FSM

- Fewer states compared to Moore FSM.
- Faster output response.
- Efficient hardware implementation.
- Reduced resource utilization.

---

## Conclusion

The Mealy Sequence Detector for the pattern **1110** was successfully designed and simulated. The FSM correctly transitions through the required states and generates a detection signal immediately when the sequence **1110** is received. The design demonstrates the effectiveness of Mealy machines in pattern detection applications and serves as a fundamental example of sequential circuit design.
