# FIFO Verification Using SystemVerilog Interface

This demonstrates the verification of an **8-bit FIFO (First-In First-Out) Memory** using a **SystemVerilog Interface**. The interface groups all FIFO signals into a single communication block, making the testbench more organized, scalable, and easier to maintain.

The FIFO temporarily stores incoming data and retrieves it in the same order it was written, ensuring reliable data transfer between producer and consumer modules operating at different speeds.

---

## Advantages of Interfaces

✔ Groups related signals together

✔ Reduces connection errors

✔ Improves readability

✔ Supports reusable verification environments

✔ Widely used in UVM-based verification

✔ Easier debugging and maintenance

---



## Signals in the Interface

| Signal   | Width  | Description          |
| -------- | ------ | -------------------- |
| clk      | 1 bit  | Clock signal         |
| rst      | 1 bit  | Reset signal         |
| wr_enb   | 1 bit  | Write enable         |
| rd_enb   | 1 bit  | Read enable          |
| data_in  | 8 bits | Input data           |
| data_out | 8 bits | Output data          |
| full     | 1 bit  | FIFO full indicator  |
| empty    | 1 bit  | FIFO empty indicator |

---

# Testbench Architecture

```text
                +------------------+
                |    Testbench     |
                +------------------+
                          |
                          |
                     fifo_if
                          |
                          |
                +------------------+
                |      FIFO DUT    |
                +------------------+
```

The interface acts as a communication channel between the testbench and DUT.

---

## Interface Instantiation

```systemverilog
fifo_if fif();
```

This creates a single interface instance containing all FIFO signals.

---


## DUT Instantiation

The FIFO is connected through interface signals.

```systemverilog
fifo_des dut (
    fif.clk,
    fif.rst,
    fif.wr_enb,
    fif.rd_enb,
    fif.data_in,
    fif.full,
    fif.empty,
    fif.data_out
);
```

---

# Clock Generation

The testbench generates a clock with a period of 10 ns.

```systemverilog
initial begin
    clk_tb = 0;
    forever #5 clk_tb = ~clk_tb;
end
```

---

# Verification Sequence

The testbench performs the following operations:

### Step 1: Reset FIFO

```text
rst = 1
```

FIFO contents are cleared.

---

### Step 2: Write Data AA

```text
Data = 0xAA
wr_enb = 1
```

Stored in FIFO.

---

### Step 3: Write Data BB

```text
Data = 0xBB
wr_enb = 1
```

Stored after AA.

FIFO contents:

```text
AA
BB
```

---

### Step 4: Read Data

```text
rd_enb = 1
```

Expected output:

```text
AA
```

---

### Step 5: Read Data

```text
rd_enb = 1
```

Expected output:

```text
BB
```

FIFO maintains First-In First-Out ordering.

---

# Expected Results

| Operation | Data |
| --------- | ---- |
| Write 1   | AA   |
| Write 2   | BB   |
| Read 1    | AA   |
| Read 2    | BB   |

---

## Simulation Output

```text
Time=0 ns  | rst=1 | wr=0 din=00 | rd=0 dout=00 | full=0 empty=1

Time=25 ns | rst=0 | wr=1 din=AA | rd=0 dout=00 | full=0 empty=0

Time=35 ns | rst=0 | wr=1 din=BB | rd=0 dout=00 | full=0 empty=0

Time=55 ns | rst=0 | wr=0 din=BB | rd=1 dout=AA | full=0 empty=0

Time=65 ns | rst=0 | wr=0 din=BB | rd=1 dout=BB | full=0 empty=1
```

---




## Simulation Waveform

<img width="1547" height="816" alt="fifo_if" src="https://github.com/user-attachments/assets/8cedb8ca-461a-4c40-b074-8c1f7980bf16" />
