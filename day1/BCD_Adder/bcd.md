Task Overview

This task implements a Binary Coded Decimal (BCD) Adder using Verilog HDL and verifies its functionality through simulation in Vivado.

A BCD adder adds two BCD digits along with an optional carry input. If the binary sum exceeds 9 (1001) or generates a carry, a correction factor of 6 (0110) is added to obtain a valid BCD result.

Design Description

| Signal | Width  | Description      |
| ------ | ------ | ---------------- |
| A      | 4 bits | First BCD digit  |
| B      | 4 bits | Second BCD digit |
| Cin    | 1 bit  | Carry input      |








<img width="1576" height="810" alt="bcd" src="https://github.com/user-attachments/assets/4e73e2cb-4724-4640-acc9-f81362ee970b" />

