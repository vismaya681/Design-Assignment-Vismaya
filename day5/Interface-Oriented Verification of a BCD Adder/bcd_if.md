# BCD Adder Verification Using SystemVerilog Interface



This demonstrates the verification of a **BCD Adder** using a **SystemVerilog Interface**. The interface is used to bundle all DUT signals into a single construct, making the testbench cleaner, more scalable, and easier to maintain.

The design under test (DUT) is a BCD Adder that performs decimal addition of two BCD digits along with an optional carry input.

---



# SystemVerilog Interface

An **Interface** is a SystemVerilog construct that groups related signals into a single reusable block.

Instead of individually connecting many signals:

```verilog
module dut(
    input [3:0] A,
    input [3:0] B,
    input Cin,
    output [3:0] S,
    output Cout
);
```

we can bundle them together:

```systemverilog
interface bcd_adder_if;
    logic [3:0] A;
    logic [3:0] B;
    logic       Cin;
    logic [3:0] S;
    logic       Cout;
endinterface
```

The interface acts like a container that holds all communication signals.

---


### Without Interface

```verilog
dut(
    .A(A_tb),
    .B(B_tb),
    .Cin(Cin_tb),
    .S(S_tb),
    .Cout(Cout_tb)
);
```

For larger designs with 20–50 signals, wiring becomes difficult.

---

### With Interface

```systemverilog
bcd_adder_if bcd_if();

dut(
    bcd_if.A,
    bcd_if.B,
    bcd_if.Cin,
    bcd_if.S,
    bcd_if.Cout
);
```

All signals are organized in one place.

---

## Advantages of Interfaces

✔ Reduces wiring complexity

✔ Improves code readability

✔ Simplifies verification environments

✔ Encourages reusable testbench components

✔ Widely used in UVM (Universal Verification Methodology)

✔ Easier debugging and maintenance

---



## Signals in the Interface

| Signal | Width | Description |
|----------|----------|-------------|
| A | 4 bits | First BCD input |
| B | 4 bits | Second BCD input |
| Cin | 1 bit | Carry input |
| S | 4 bits | BCD sum output |
| Cout | 1 bit | Carry output |

---

# Testbench Architecture

```text
                  +----------------+
                  |   Testbench    |
                  +----------------+
                           |
                           |
                    bcd_adder_if
                           |
                           |
                  +----------------+
                  |   BCD Adder    |
                  +----------------+
```

The interface acts as a communication bridge between the testbench and DUT.

---

## Interface Instantiation

The interface is instantiated as:

```systemverilog
bcd_adder_if bcd_if();
```

This creates a single interface object containing all signals.

---

## DUT Instantiation

The BCD Adder is connected through the interface.

```systemverilog
bcd_adder dut(
    bcd_if.A,
    bcd_if.B,
    bcd_if.Cin,
    bcd_if.S,
    bcd_if.Cout
);
```

---

# Test Cases

The following input combinations are applied.

| Test Case | A | B | Cin |
|------------|---|---|-----|
| 1 | 4 | 4 | 0 |
| 2 | 5 | 5 | 0 |
| 3 | 9 | 9 | 1 |

---

## Expected Results

### Test Case 1

```text
4 + 4 + 0 = 8
```

Output:

```text
S = 8
Cout = 0
```

---

### Test Case 2

```text
5 + 5 + 0 = 10
```

BCD Correction:

```text
S = 0
Cout = 1
```

---

### Test Case 3

```text
9 + 9 + 1 = 19
```

BCD Output:

```text
S = 9
Cout = 1
```

---



## Simulation Output

```text
Time=0 ns  | A=4 B=4 Cin=0 -> Cout=0 S=8

Time=10 ns | A=5 B=5 Cin=0 -> Cout=1 S=0

Time=20 ns | A=9 B=9 Cin=1 -> Cout=1 S=9
```

---



## Simulation Waveform

<img width="1576" height="817" alt="bcd_adder_tb_if" src="https://github.com/user-attachments/assets/01cbed44-9e9b-44ab-9796-3af39ee08960" />
