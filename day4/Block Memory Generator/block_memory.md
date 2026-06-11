# Block Memory Generator 



This project implements an **8×8 Block Memory Generator (Block RAM)** using Verilog HDL and verifies its functionality through simulation in **Vivado**.

A Block RAM (BRAM) is an internal memory resource available in FPGAs that is used for efficient storage and retrieval of data. Here , an 8-location memory is modeled, where each location stores 8 bits of data.

The design supports:

- Write Operation
- Read Operation
- Asynchronous Active-Low Reset

---

## Design Description

### Inputs

| Signal | Width | Description |
|----------|----------|-------------|
| clk | 1 bit | Clock input |
| arstn | 1 bit | Active-low asynchronous reset |
| wrenb | 1 bit | Write enable |
| wr_address | 8 bits | Write address |
| rd_address | 8 bits | Read address |
| data_in | 8 bits | Input data |

### Outputs

| Signal | Width | Description |
|----------|----------|-------------|
| data_out | 8 bits | Output data |

---

## Memory Organization

The memory contains:

```text
8 Locations × 8 Bits
```

Memory Structure:

```text
Address      Data
-------      --------
0            XXXXXXXX
1            XXXXXXXX
2            XXXXXXXX
3            XXXXXXXX
4            XXXXXXXX
5            XXXXXXXX
6            XXXXXXXX
7            XXXXXXXX
```

---

## Working Principle

The Block RAM performs operations on the positive edge of the clock.

### Reset Operation

When:

```text
arstn = 0
```

All memory locations are cleared.

```verilog
for(i=0;i<8;i=i+1)
    memory[i] <= 8'b0;
```

Output is also reset.

```verilog
data_out <= 8'b0;
```

---

### Write Operation

When:

```text
wrenb = 1
```

Data is written into the specified memory location.

```verilog
memory[wr_address] <= data_in;
```

Example:

```text
Address = 000
Data    = AA
```

Memory after write:

```text
Memory[0] = AA
```

---

### Read Operation

When:

```text
wrenb = 0
```

Stored data is read from the selected address.

```verilog
data_out <= memory[rd_address];
```

Example:

```text
Address = 001
```

Output:

```text
Data Out = 4B
```

---

## RTL Structure

```text
                 +------------------+
                 |   Block Memory   |
                 |     8 × 8 RAM    |
                 |                  |
 data_in ------->|                  |
 wr_address ---->|                  |
 rd_address ---->|                  |----> data_out
 wrenb --------->|                  |
 clk ----------->|                  |
 arstn --------->|                  |
                 +------------------+
```

---

## Design Code Explanation

### Memory Declaration

```verilog
reg [7:0] memory [7:0];
```

Creates:

```text
8 Memory Locations
Each Location = 8 Bits
```

---

### Asynchronous Reset

```verilog
if(!arstn)
```

Clears:

- Memory contents
- Output register

---

### Write Logic

```verilog
if(wrenb == 1'b1)
```

Stores incoming data into memory.

---

### Read Logic

```verilog
else
```

Reads data from memory and updates output.

---

## Testbench Description

The testbench verifies:

1. Reset operation
2. Multiple write operations
3. Multiple read operations
4. Memory retention
5. Asynchronous reset

Clock generation:

```verilog
always #5 clk_tb = ~clk_tb;
```

Clock period:

```text
10 ns
```

---

## Test Cases

### Write Operations

| Address | Data Written |
|----------|-------------|
| 000 | AA |
| 001 | 4B |
| 010 | 78 |
| 011 | 41 |

---

### Read Operations

| Address | Expected Data |
|----------|--------------|
| 000 | AA |
| 001 | 4B |
| 010 | 78 |
| 011 | 41 |

---

## Expected Results

### Memory Contents After Writing

```text
Memory[0] = AA
Memory[1] = 4B
Memory[2] = 78
Memory[3] = 41
```

### Read Results

```text
Address 000 → AA
Address 001 → 4B
Address 010 → 78
Address 011 → 41
```

### Reset Result

When:

```text
arstn = 0
```

Memory becomes:

```text
Memory[0] = 00
Memory[1] = 00
Memory[2] = 00
Memory[3] = 00
Memory[4] = 00
Memory[5] = 00
Memory[6] = 00
Memory[7] = 00
```

Output:

```text
data_out = 00
```

---


## Simulation Waveform

<img width="1555" height="812" alt="block_ram" src="https://github.com/user-attachments/assets/d4f3faf7-d191-40ba-890a-bef947e9ad4a" />


## Conclusion

The 8×8 Block Memory Generator was successfully modeled and simulated. The design correctly performs memory write, memory read, and asynchronous reset operations. It demonstrates the fundamental principles of memory implementation in FPGA-based digital systems and serves as a foundation for larger RAM and FIFO architectures.
