# Universal Shift Register (USR) 

## Task Overview

This task implements a **4-bit Universal Shift Register (USR)** using Verilog HDL and verifies its functionality through simulation.

A Universal Shift Register is a versatile sequential circuit capable of performing multiple operations such as serial shifting, parallel loading, and data storage. It is widely used in digital communication systems, data transfer applications, and sequential logic circuits.

---

## Objective

- Design a 4-bit Universal Shift Register using Verilog HDL.
- Implement serial input and serial output functionality.
- Implement parallel loading of data.
- Verify different operating modes through simulation in Vivado.
- Observe shift and load operations using waveforms.

---

## Design Description

### Inputs

| Signal | Width | Description |
|----------|----------|-------------|
| clk | 1 bit | Clock input |
| rst | 1 bit | Reset input |
| sin | 1 bit | Serial input |
| pin | 4 bits | Parallel input |
| mod | 2 bits | Mode selection |
| load | 1 bit | Parallel load enable |

### Outputs

| Signal | Width | Description |
|----------|----------|-------------|
| sout | 1 bit | Serial output |
| pout | 4 bits | Parallel output |

---

## Working Principle

The Universal Shift Register operates on the **positive edge of the clock**.

When the reset signal is active:

- Register contents are cleared.
- Parallel output becomes `0000`.
- Serial output becomes `0`.

The operation performed depends on the value of the mode input (`mod`).

---

## Mode Selection

| Mode (`mod`) | Operation |
|-------------|------------|
| `00` | Serial Input with Serial Output |
| `01` | Serial Input Parallel Output |
| `10` | Parallel Input with Serial Output |
| `11` | Parallel Input Parallel Output |

---

## Functional Description

### Mode 00 – Serial Input with Serial Output

- Data shifts right.
- Serial input enters the MSB position.
- LSB is provided at serial output.

```text
sin → [D3 D2 D1 D0] → sout
```

---

### Mode 01 – Serial Input Parallel Output

- Data shifts right.
- Serial input enters MSB.
- Parallel output is updated.

---

### Mode 10 – Parallel Input with Serial Output

If `load = 1`:

```text
temp ← pin
```

If `load = 0`:

```text
Shift Right Operation
```

---

### Mode 11 – Parallel Input Parallel Output

If `load = 1`:

```text
temp ← pin
```

If `load = 0`:

```text
Hold Current Data
```

---

## RTL Structure

```text
                 +------------------+
sin -----------> |                  |
pin[3:0] ------> | Universal Shift  | -----> sout
mod[1:0] ------> |    Register      |
load ----------> |                  |
clk -----------> |                  |
rst -----------> |                  |
                 +------------------+
                           |
                           |
                       pout[3:0]
```

---

## Design Code Explanation

### Reset Condition

```verilog
if (rst)
begin
    temp <= 4'b0000;
    pout <= 4'b0000;
    sout <= 1'b0;
end
```

This clears all stored data.

---

### Shift Operation

```verilog
temp <= temp >> 1'b1;
temp[3] <= sin;
```

- Data shifts one position to the right.
- New serial data enters the MSB.

---

### Parallel Load

```verilog
temp <= pin;
```

Loads all four bits simultaneously.

---

### Serial Output

```verilog
sout <= temp[0];
```

The least significant bit is transmitted as serial output.

---

## Testbench Description

The testbench verifies:

1. Reset operation.
2. Serial shifting in Mode 00.
3. Serial shifting in Mode 01.
4. Parallel loading in Mode 10.
5. Shift operation after loading.
6. Parallel loading in Mode 11.
7. Hold operation.

Clock generation:

```verilog
always #5 clk_tb = ~clk_tb;
```

This produces a clock with a period of 10 ns.

---

## Test Cases

### Reset Operation

| Time | rst | Expected Output |
|--------|--------|----------------|
| 0 ns | 1 | Register cleared |

---

### Mode 00: Serial Input with Serial Output 

| Serial Input |
|-------------|
| 1 |
| 0 |
| 1 |
| 1 |

Expected behavior:

```text
Shift Right with Serial Output
```

---

### Mode 01: Serial Input Parallel Output

| Serial Input |
|-------------|
| 1 |
| 0 |
| 1 |
| 0 |

Expected behavior:

```text
Shift Right Operation
```

---

### Mode 10: Parallel Input with Serial Output

Parallel Input:

```text
1101
```

Load enabled:

```text
load = 1
```

Expected Output:

```text
pout = 1101
```

---

### Mode 11: Parallel Input Parallel Output

Parallel Input:

```text
1010
```

Load enabled:

```text
load = 1
```

Expected Output:

```text
pout = 1010
```

---

## Expected Results

| Mode | Load | Input | Operation |
|--------|--------|--------|------------|
| 00 | 0 | sin | Shift Right + Serial Output |
| 01 | 0 | sin | Shift Right |
| 10 | 1 | pin | Parallel Load |
| 10 | 0 | sin | Shift Right |
| 11 | 1 | pin | Parallel Load |
| 11 | 0 | - | Hold Data |

---

## Simulation

### Tool Used

- Vivado Design Suite
- Verilog HDL

### Steps to Run

1. Create a new Vivado project.
2. Add the following source files:
   - `usr.v`
   - `usr_tb.v`
3. Set `usr_tb.v` as the simulation source.
4. Run **Behavioral Simulation**.
5. Observe the waveform and verify each operating mode.

---

## Simulation Waveform
<img width="1592" height="828" alt="usr" src="https://github.com/user-attachments/assets/ef9ff060-2c58-4132-a8d0-53e4fdd4611c" />



## Applications

- Serial-to-Parallel Data Conversion
- Parallel-to-Serial Data Conversion
- Data Storage Systems
- Communication Interfaces
- Shift Operations in Processors
- Digital Signal Processing Systems

---

## Features

✔ 4-bit Register Implementation  
✔ Serial Input Support  
✔ Serial Output Support  
✔ Parallel Data Loading  
✔ Multiple Operating Modes  
✔ Synchronous Operation  
✔ Reset Functionality

---

## Conclusion

The 4-bit Universal Shift Register was successfully designed and simulated . The simulation verified serial shifting, parallel loading, hold functionality, and serial data transmission. The design demonstrates the flexibility of a Universal Shift Register and its importance in digital communication and sequential logic systems.
