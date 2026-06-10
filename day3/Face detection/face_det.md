# Face Detection using FIFO 

## Task Overview

This task implements a simple **Face Data Transfer System** using Verilog HDL and verifies its functionality through simulation in **Vivado**.

The system consists of three major modules:

1. **Face Module** – Generates/transmits 8-bit face data packets.
2. **FIFO Buffer** – Stores incoming data packets temporarily.
3. **Output Module (FSM Based)** – Represents a slow device that accepts data only once every three clock cycles.

Since the output device is slower than the face module, a FIFO is inserted between them to prevent data loss.

---

## Problem Statement

The face module continuously generates 8-bit data packets at every positive clock edge.

```text
Face Module
     |
     v
   FIFO
     |
     v
 Slow Output Device
```

The output device can process data only once every **third clock cycle**.

Without buffering:

```text
Clock 1 -> Data1
Clock 2 -> Data2
Clock 3 -> Data3 (Read)

Data1 and Data2 are lost.
```

To avoid losing packets, a FIFO buffer is introduced between the producer and consumer.

---

## Objective

- Design a face data transmitter.
- Design a FIFO memory buffer.
- Design an FSM-based slow output device.
- Transfer data without packet loss.
- Verify the complete system through simulation.

---

# System Architecture

```text
         +------------+
         | Face Module|
         +------------+
                |
                v
         +------------+
         |    FIFO    |
         +------------+
                |
                v
         +------------+
         | Output FSM |
         +------------+
                |
                v
            Data Out
```

---

## Module 1: Face Module

### Description

The face module represents a camera or image sensor that continuously generates 8-bit data packets.

### Inputs

| Signal | Width | Description |
|---------|---------|-------------|
| clk | 1 bit | Clock |
| sin | 8 bits | Input data packet |

### Output

| Signal | Width | Description |
|---------|---------|-------------|
| sout | 8 bits | Output data packet |

### Functionality

At every positive clock edge:

```verilog
always @(posedge clk)
begin
    sout <= sin;
end
```

The module simply forwards the incoming data.

---

## Module 2: FIFO Buffer

### Description

The FIFO (First-In First-Out) stores incoming data packets and releases them in the same order they were received.

### Inputs

| Signal | Width | Description |
|---------|---------|-------------|
| clk | 1 bit | Clock |
| rst | 1 bit | Reset |
| wr_enb | 1 bit | Write Enable |
| rd_enb | 1 bit | Read Enable |
| data_in | 8 bits | Input Data |

### Outputs

| Signal | Width | Description |
|---------|---------|-------------|
| data_out | 8 bits | Output Data |
| full | 1 bit | FIFO Full Flag |
| empty | 1 bit | FIFO Empty Flag |

---

### Internal Structure

```text
FIFO Memory
+----+----+----+----+----+----+----+----+
| M0 | M1 | M2 | M3 | M4 | M5 | M6 | M7 |
+----+----+----+----+----+----+----+----+
   ↑                           ↑
Write Pointer             Read Pointer
```

The FIFO contains:

- 8 memory locations
- Write Pointer (`wr_ptr`)
- Read Pointer (`rd_ptr`)

---

### Write Operation

```verilog
if(wr_enb && !full)
begin
    mem[wr_ptr] <= data_in;
    wr_ptr <= wr_ptr + 1'b1;
end
```

Stores incoming data into FIFO.

---

### Read Operation

```verilog
if(rd_enb && !empty)
begin
    data_out <= mem[rd_ptr];
    rd_ptr <= rd_ptr + 1'b1;
end
```

Retrieves stored data from FIFO.

---

## Module 3: Output Module (FSM Based)

### Description

The output device is intentionally slower.

It accepts data only once every **third clock cycle**.

This behavior is implemented using a **Finite State Machine (FSM)**.

---

## FSM Design

### States

| State | Meaning |
|---------|----------|
| S0 | Clock Count = 1 |
| S1 | Clock Count = 2 |
| S2 | Clock Count = 3 (Read Data) |

---

### State Diagram

```text
      +-----+
      | S0  |
      +-----+
         |
         v
      +-----+
      | S1  |
      +-----+
         |
         v
      +-----+
      | S2  |
      +-----+
         |
         v
      +-----+
      | S0  |
      +-----+
```

---

### FSM Operation

```text
Clock 1 -> S0
Clock 2 -> S1
Clock 3 -> S2 -> Read Enable = 1
```

The read enable signal is asserted only in state `S2`.

```text
Read every 3 clocks
```

---

# Top Module

### Description

The top module connects:

- Face Module
- FIFO
- Output FSM

### Data Flow

```text
Input Data
    |
    v
 Face Module
    |
    v
 FIFO Buffer
    |
    v
 Output FSM
    |
    v
 Output Data
```

---

## Why FIFO is Required

Assume the face module generates:

```text
Clock 1 -> 4F
Clock 2 -> 2C
Clock 3 -> 13
Clock 4 -> 46
Clock 5 -> 59
Clock 6 -> 21
```

The output device reads only at:

```text
Clock 3
Clock 6
Clock 9
...
```

Without FIFO:

```text
4F Lost
2C Lost
13 Read
46 Lost
59 Lost
21 Read
```

With FIFO:

```text
4F Stored
2C Stored
13 Stored
46 Stored
59 Stored
21 Stored

Read Order:
4F
2C
13
46
59
21
```

No data is lost.

---

## Testbench Description

The testbench provides several 8-bit data packets to simulate continuous face data transmission.

### Test Data

| Clock | Input Data |
|---------|-----------|
| 1 | 4F |
| 2 | 2C |
| 3 | 13 |
| 4 | 46 |
| 5 | 59 |
| 6 | 21 |
| 7 | 19 |
| 8 | AA |

---

## Expected Behavior

### FIFO Storage

```text
4F
2C
13
46
59
21
19
AA
```

### Output Sequence

Since reading occurs once every three clocks:

```text
4F
2C
13
46
59
21
19
AA
```

All packets are received in the correct order.

---

## Simulation

### Tool Used

- Vivado Design Suite
- Verilog HDL

### Steps to Run

1. Create a new Vivado project.
2. Add the following source files:
   - `face.v`
   - `fifo.v`
   - `out.v`
   - `top.v`
   - `top_tb.v`
3. Set `top_tb.v` as the simulation source.
4. Run **Behavioral Simulation**.
5. Observe FIFO storage and delayed output behavior.

---

## Simulation Waveform

<img width="1791" height="825" alt="facedet" src="https://github.com/user-attachments/assets/2fa7c1bd-2a5f-42fb-80f8-3c480fd92f63" />




## Features

✔ 8-bit Face Data Transfer  
✔ FIFO-Based Data Buffering  
✔ FSM-Controlled Slow Output Device  
✔ No Data Loss During Transfer  
✔ Synchronous Design  


---

## Conclusion

This project successfully demonstrates a face-data transfer system using a FIFO buffer and an FSM-controlled slow output device. The face module continuously generates 8-bit data packets, while the output module processes data only once every three clock cycles. By introducing a FIFO between the producer and consumer, all incoming packets are stored and transmitted without loss, ensuring reliable communication between modules operating at different speeds.
