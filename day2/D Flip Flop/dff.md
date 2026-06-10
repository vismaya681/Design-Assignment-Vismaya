# D Flip-Flop (DFF)

## Task Overview

This task implements a **D Flip-Flop (DFF)** using Verilog HDL and verifies its functionality through simulation .

A D Flip-Flop is a sequential circuit used to store one bit of data. The output changes only on the positive edge of the clock signal and retains its value until the next clock edge.

---

## Objective

- Design a D Flip-Flop using Verilog HDL.
- Implement synchronous reset functionality.
- Simulate and verify the design using Vivado.
- Observe data storage and clock-triggered operation.

---

## Design Description

### Inputs

| Signal | Width | Description |
|----------|----------|-------------|
| d | 1 bit | Data input |
| rst | 1 bit | Reset input |
| clk | 1 bit | Clock input |

### Outputs

| Signal | Width | Description |
|----------|----------|-------------|
| q | 1 bit | Stored output |
| qbar | 1 bit | Complement of stored output |

---

## Working Principle

The D Flip-Flop operates on the **positive edge of the clock**.

1. When `rst = 1`, the flip-flop is reset:
   - `q = 0`
   - `qbar = 1`

2. When `rst = 0`, the value present at input `d` is transferred to output `q` on the next positive clock edge.

3. The complementary output `qbar` always holds the inverse of `q`.

---

## Truth Table

| Reset (rst) | Clock Edge | D | Q(next) | Q̅(next) |
|-------------|------------|---|----------|-----------|
| 1 | ↑ | X | 0 | 1 |
| 0 | ↑ | 0 | 0 | 1 |
| 0 | ↑ | 1 | 1 | 0 |

---

## Design Code Explanation

The flip-flop is triggered on every positive edge of the clock:

```verilog
always @(posedge clk)
```

Reset condition:

```verilog
if (rst) begin
    q <= 1'b0;
    qbar <= 1'b1;
end
```

Normal operation:

```verilog
else begin
    q <= d;
    qbar <= ~d;
end
```

---

## RTL Structure

```text
        +-------------+
 D ---->|             |
        |    DFF      |----> Q
CLK --->|             |
        |             |
RST --->|             |----> Q̅
        +-------------+
```

---

## Testbench Description

The testbench verifies the following operations:

1. Reset operation.
2. Storing logic 1.
3. Storing logic 0.
4. Storing logic 1 again.
5. Clock-triggered output changes.

Clock generation:

```verilog
always #5 clk_tb = ~clk_tb;
```

This generates a clock with a period of 10 ns.

---

## Test Cases

| Time (ns) | Reset | D | Expected Q | Expected Q̅ |
|------------|--------|---|------------|------------|
| 0 | 1 | 0 | 0 | 1 |
| 10 | 0 | 1 | 1 | 0 |
| 20 | 0 | 0 | 0 | 1 |
| 30 | 0 | 1 | 1 | 0 |

---

## Expected Results

| D | Reset | Clock Edge | Q | Q̅ |
|---|--------|------------|---|---|
| X | 1 | ↑ | 0 | 1 |
| 1 | 0 | ↑ | 1 | 0 |
| 0 | 0 | ↑ | 0 | 1 |
| 1 | 0 | ↑ | 1 | 0 |

---

## Simulation

### Tool Used

- Vivado Design Suite
- Verilog HDL

### Steps to Run

1. Create a new Vivado project.
2. Add the following source files:
   - `dff.v`
   - `dff_tb.v`
3. Set `dff_tb.v` as the simulation source.
4. Run **Behavioral Simulation**.
5. Observe the waveform and verify the outputs.

---

## Simulation Waveform
<img width="1582" height="812" alt="dff" src="https://github.com/user-attachments/assets/8783f8fd-bcd6-4bcc-b2c6-85c35879fa96" />


## Applications

- Registers
- Counters
- Shift Registers
- Memory Elements
- Finite State Machines (FSMs)
- Data Synchronization Circuits

---

## Conclusion

The D Flip-Flop was successfully designed and simulated. The simulation verified that the output changes only on the positive edge of the clock and correctly stores the input data while supporting synchronous reset functionality.
