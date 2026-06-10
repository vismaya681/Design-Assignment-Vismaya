# BCD Adder

## Task Overview

This task implements a Binary Coded Decimal (BCD) Adder using Verilog HDL and verifies its functionality through simulation in Vivado.

A BCD adder adds two BCD digits along with an optional carry input. If the binary sum exceeds 9 (1001) or generates a carry, a correction factor of 6 (0110) is added to obtain a valid BCD result.

## Design Description

| Signal | Width  | Description      |
| ------ | ------ | ---------------- |
| A      | 4 bits | First BCD digit  |
| B      | 4 bits | Second BCD digit |
| Cin    | 1 bit  | Carry input      |

## Outputs

| Signal | Width  | Description          |
| ------ | ------ | -------------------- |
| S      | 4 bits | BCD Sum              |
| Cout   | 1 bit  | Decimal carry output |

## Working Principle

1)The first Ripple Carry Adder (RCA1) adds: A + B + Cin
2)The intermediate sum (S1) is checked for BCD validity.
3)If:
- A carry is generated, or
- The sum is greater than 9,
then a correction value of 0110 (decimal 6) is added.
4)The second Ripple Carry Adder (RCA2) performs the correction.
5)The corrected sum appears at S, and the decimal carry is provided by Cout.
<img width="1080" height="881" alt="bcd adder" src="https://github.com/user-attachments/assets/936dc858-433b-43c2-b6df-6646afe3544a" />


## BCD Correction Condition
  
assign adjust = Cout1 | (S1[3] & S1[2]) | (S1[3] & S1[1]);
When adjust = 1, the value 0110 is added to the intermediate sum.

## Module Hierarchy
```text
BCD Adder
│
├── RCA1 (Binary Addition)
│
├── Correction Logic
│
└── RCA2 (Add 6 if required)
```

## Testbench Description

The testbench verifies different operating conditions including:
| Test Case | A | B | Cin |
| --------- | - | - | --- |
| 1         | 3 | 5 | 0   |
| 2         | 4 | 2 | 1   |
| 3         | 6 | 4 | 0   |
| 4         | 8 | 7 | 0   |
| 5         | 9 | 9 | 1   |

## Expected Results

| A | B | Cin | Decimal Result | BCD Sum (S) | Cout |
| - | - | --- | -------------- | ----------- | ---- |
| 3 | 5 | 0   | 8              | 1000        | 0    |
| 4 | 2 | 1   | 7              | 0111        | 0    |
| 6 | 4 | 0   | 10             | 0000        | 1    |
| 8 | 7 | 0   | 15             | 0101        | 1    |
| 9 | 9 | 1   | 19             | 1001        | 1    |

## Simulation
### Tool Used
- Vivado Design Suite
- Verilog HDL
### Steps to Run
1.Create a new Vivado project.
2.Add:
-bcd.v
-rca.v
-bcd_tb.v
3.Set bcd_tb.v as the simulation source.
4.Run Behavioral Simulation.
5.Observe the waveform and verify outputs.

## Simulation Waveform

<img width="1576" height="810" alt="bcd" src="https://github.com/user-attachments/assets/4e73e2cb-4724-4640-acc9-f81362ee970b" />

## Conclusion
The BCD Adder was successfully designed and simulated. The correction logic correctly adds 6 whenever the binary sum exceeds 9, producing valid BCD outputs and the appropriate carry signal.

