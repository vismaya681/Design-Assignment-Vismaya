# SR Flip-Flop (SRFF)

## Task Overview

This task implements a **Synchronous SR (Set-Reset) Flip-Flop** using Verilog HDL and verifies its functionality through simulation.

An SR Flip-Flop is a sequential circuit used for storing a single bit of information. The output changes only on the positive edge of the clock signal based on the values of the Set (S) and Reset (R) inputs.

---

## Objective

- Design a synchronous SR Flip-Flop using Verilog HDL.
- Implement reset functionality.
- Simulate and verify the design using Vivado.
- Observe the behavior for all possible input combinations.

---

## Design Description

### Inputs

| Signal | Width | Description |
|----------|----------|-------------|
| s | 1 bit | Set input |
| r | 1 bit | Reset input |
| rst | 1 bit | Reset signal |
| clk | 1 bit | Clock input |

### Outputs

| Signal | Width | Description |
|----------|----------|-------------|
| q | 1 bit | Stored output |
| qbar | 1 bit | Complement of output |

---

## Working Principle

The SR Flip-Flop operates on the **positive edge of the clock**.

### Reset Condition

When `rst = 1`:

- `q = 0`
- `qbar = 1`

### Normal Operation (`rst = 0`)

The output depends on the values of `s` and `r`.

| S | R | Operation | Q(next) | Q̅(next) |
|---|---|-----------|----------|-----------|
| 0 | 0 | Hold | Q | Q̅ |
| 0 | 1 | Reset | 0 | 1 |
| 1 | 0 | Set | 1 | 0 |
| 1 | 1 | Invalid State | X | X |

---

## Truth Table

| Reset | Clock Edge | S | R | Q(next) | Q̅(next) |
|--------|------------|---|---|----------|-----------|
| 1 | ↑ | X | X | 0 | 1 |
| 0 | ↑ | 0 | 0 | Hold | Hold |
| 0 | ↑ | 0 | 1 | 0 | 1 |
| 0 | ↑ | 1 | 0 | 1 | 0 |
| 0 | ↑ | 1 | 1 | X | X |

---

## Design Code Explanation

The SR Flip-Flop is triggered on every positive edge of the clock:

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

Input combinations are handled using a case statement:

### Hold State

```verilog
2'b00:
begin
    q <= q;
    qbar <= qbar;
end
```

### Reset State

```verilog
2'b01:
begin
    q <= 1'b0;
    qbar <= 1'b1;
end
```

### Set State

```verilog
2'b10:
begin
    q <= 1'b1;
    qbar <= 1'b0;
end
```

### Invalid State

```verilog
2'b11:
begin
    q <= 'bx;
    qbar <= 'bx;
end
```

---

## RTL Structure

```text
           +--------------+
S -------->|              |
R -------->|   SR Flip-   |-----> Q
CLK ------>|    Flop      |
RST ------>|              |-----> Q̅
           +--------------+
```

---

## Testbench Description

The testbench verifies:

1. Reset operation.
2. Hold condition.
3. Reset state.
4. Set state.
5. Invalid state.

Clock generation:

```verilog
always #5 clk_tb = ~clk_tb;
```

This creates a clock with a period of 10 ns.

---

## Test Cases

| Time (ns) | Reset | S | R | Operation |
|------------|--------|---|---|-----------|
| 0 | 1 | X | X | Reset |
| 10 | 0 | 0 | 0 | Hold |
| 20 | 0 | 0 | 1 | Reset |
| 30 | 0 | 1 | 0 | Set |
| 40 | 0 | 1 | 1 | Invalid |

---

## Expected Results

| S | R | Reset | Q | Q̅ |
|---|---|--------|---|---|
| X | X | 1 | 0 | 1 |
| 0 | 0 | 0 | Hold | Hold |
| 0 | 1 | 0 | 0 | 1 |
| 1 | 0 | 0 | 1 | 0 |
| 1 | 1 | 0 | X | X |

---

## Simulation

### Steps to Run

1. Create a new Vivado project.
2. Add the following source files:
   - `srff.v`
   - `srff_tb.v`
3. Set `srff_tb.v` as the simulation source.
4. Run **Behavioral Simulation**.
5. Observe the waveform and verify the outputs.

---

## Simulation Waveform

<img width="1588" height="826" alt="srff" src="https://github.com/user-attachments/assets/c9d3274a-61c1-447f-9125-80318fc82cf9" />





## Applications

- Memory Elements
- Control Circuits
- Finite State Machines (FSMs)
- Digital Storage Systems
- Sequential Logic Design
- Educational Study of Flip-Flops

---

## Conclusion

The SR Flip-Flop was successfully designed and simulated. The simulation verified correct operation for hold, set, reset, and invalid input conditions. The design demonstrates the fundamental behavior of a clocked SR Flip-Flop and serves as a building block for more complex sequential circuits.
