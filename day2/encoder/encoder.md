# 4-to-2 Encoder Using Verilog

## Task Overview

This task implements a **4-to-2 Encoder** using Verilog HDL and verifies its functionality through simulation.

An encoder is a combinational logic circuit that converts multiple input lines into a smaller number of output lines. A 4-to-2 encoder converts one active input out of four possible inputs into a 2-bit binary code.

---

## Objective

- Design a 4-to-2 Encoder using Verilog HDL.
- Implement combinational logic using a case statement.
- Simulate and verify the design using Vivado.
- Observe the binary encoding of active input lines.

---

## Design Description

### Inputs

| Signal | Width | Description |
|----------|----------|-------------|
| D | 4 bits | Encoder input lines |

### Outputs

| Signal | Width | Description |
|----------|----------|-------------|
| b | 2 bits | Encoded binary output |

---

## Working Principle

The encoder assumes that **only one input line is active (logic 1) at a time**.

Depending on which input bit is high, the corresponding binary code is generated at the output.

### Input-Output Mapping

| Input D | Output b |
|----------|-----------|
| 0001 | 00 |
| 0010 | 01 |
| 0100 | 10 |
| 1000 | 11 |

---

## Truth Table

| D3 | D2 | D1 | D0 | Output (b1 b0) |
|----|----|----|----|----------------|
| 0 | 0 | 0 | 1 | 00 |
| 0 | 0 | 1 | 0 | 01 |
| 0 | 1 | 0 | 0 | 10 |
| 1 | 0 | 0 | 0 | 11 |

---

## RTL Structure

```text
          +----------------+
D[3:0] -->| 4-to-2 Encoder |--> b[1:0]
          +----------------+
```

---

## Design Code Explanation

The encoder continuously monitors the input using:

```verilog
always @(*)
```

A case statement is used to generate the corresponding binary output:

```verilog
case(D)
    4'b0001: b = 2'b00;
    4'b0010: b = 2'b01;
    4'b0100: b = 2'b10;
    4'b1000: b = 2'b11;
endcase
```

### Encoding Logic

```text
Input 0001 → Output 00
Input 0010 → Output 01
Input 0100 → Output 10
Input 1000 → Output 11
```

---

## Testbench Description

The testbench verifies all valid input combinations by applying one active input at a time.

### Test Cases

| Test Case | Input D | Expected Output b |
|------------|---------|-------------------|
| 1 | 0001 | 00 |
| 2 | 0010 | 01 |
| 3 | 0100 | 10 |
| 4 | 1000 | 11 |

---

## Expected Results

| Input D | Decimal Input Position | Output b |
|----------|-----------------------|----------|
| 0001 | 0 | 00 |
| 0010 | 1 | 01 |
| 0100 | 2 | 10 |
| 1000 | 3 | 11 |

---

## Simulation

### Tool Used

- Vivado Design Suite
- Verilog HDL

### Steps to Run

1. Create a new Vivado project.
2. Add the following source files:
   - `encoder4by2.v`
   - `encoder4by2_tb.v`
3. Set `encoder4by2_tb.v` as the simulation source.
4. Run **Behavioral Simulation**.
5. Observe the waveform and verify the encoded outputs.

---

## Simulation Waveform

<img width="1587" height="820" alt="encoder" src="https://github.com/user-attachments/assets/8a576b1b-3c14-477d-a578-0092910aae4a" />


## Applications

- Data Compression
- Keyboard Encoding
- Digital Communication Systems
- Address Encoding
- Microprocessor Interfaces
- Control Systems

---

## Features

✔ Combinational Logic Design  
✔ 4 Input Lines  
✔ 2 Output Lines  
✔ Case Statement Implementation  
✔ Simple and Efficient Encoding  
✔ Vivado Simulation Verified

---

## Limitations

- This encoder assumes that only one input is active at a time.
- Multiple active inputs may produce undefined results.
- No priority mechanism is implemented.

---

## Conclusion

The 4-to-2 Encoder was successfully designed and simulated. The simulation verified that each active input line is correctly converted into its corresponding 2-bit binary code. This project demonstrates the fundamental operation of encoder circuits used in digital systems.
