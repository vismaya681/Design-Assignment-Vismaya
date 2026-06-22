## Overview

This project implements the functional verification of an **Advanced Peripheral Bus (APB) Slave** using **Basic Object-Oriented Programming (OOP)** concepts in **SystemVerilog**. The verification environment is built without UVM and follows a modular architecture consisting of a **Transaction**, **Generator**, **Driver**, **Monitor**, **Scoreboard**, **Environment**, and **Testbench**.

The APB slave implements a **32-word memory**, supports both **read and write transactions**, detects **invalid address accesses**, and generates appropriate error responses.

---

> Project Structure

```text
APB_Verification/
│
├── Design/
│   └── apb_slave.sv
│
├── Verification/
│   ├── apb_if.sv
│   ├── apb_transaction.sv
│   ├── generator.sv
│   ├── driver.sv
│   ├── monitor.sv
│   ├── scoreboard.sv
│   ├── environment.sv
│   └── tb.sv
│

```

---

>Design Description

The Design Under Test (DUT) is an APB Slave with an internal **32 × 32-bit memory**.

 Input Signals

| Signal    | Width | Description        |
| --------- | ----: | ------------------ |
| `pclk`    |     1 | APB Clock          |
| `presetn` |     1 | Active-low Reset   |
| `paddr`   |    32 | Address Bus        |
| `psel`    |     1 | Slave Select       |
| `penable` |     1 | Enable Signal      |
| `pwrite`  |     1 | Read/Write Control |
| `pwdata`  |    32 | Write Data         |

 Output Signals

| Signal    | Width | Description       |
| --------- | ----: | ----------------- |
| `pready`  |     1 | Transfer Complete |
| `pslverr` |     1 | Error Indicator   |
| `prdata`  |    32 | Read Data         |

---

>APB Slave Operation

The APB Slave uses a finite state machine with three states.

| State      | Description                                                                         |
| ---------- | ----------------------------------------------------------------------------------- |
| **IDLE**   | Waits for `psel` to become high.                                                    |
| **SETUP**  | Waits for both `psel` and `penable` to be asserted.                                 |
| **ACCESS** | Performs the read/write operation, generates `pready`, and checks address validity. |

State Transition:

```text
           +------+
           | IDLE |
           +------+
               |
             psel
               |
               ▼
          +---------+
          | SETUP   |
          +---------+
               |
      psel && penable
               |
               ▼
          +---------+
          | ACCESS  |
          +---------+
           |      |
       psel=1   psel=0
           |      |
           ▼      ▼
        SETUP    IDLE
```

---

> Verification Architecture

```text
                Generator
                    │
            Mailbox (gen2drv)
                    │
                    ▼
                 Driver
                    │
            Virtual Interface
                    │
                    ▼
               APB Slave DUT
                    │
            Virtual Interface
                    │
                    ▼
                 Monitor
                    │
            Mailbox (mon2scb)
                    │
                    ▼
               Scoreboard
```

---

> Verification Components

1. Interface (`apb_if.sv`)

The interface groups all APB signals into a single communication channel shared by the DUT and verification components.

Signals include:

* `pclk`
* `presetn`
* `paddr`
* `psel`
* `penable`
* `pwrite`
* `pwdata`
* `prdata`
* `pready`
* `pslverr`

The interface is connected to the Driver and Monitor through a **virtual interface**.

---

2. Transaction (`apb_transaction.sv`)

The transaction class represents a single APB transaction.

### Random Variables

* `paddr`
* `pwdata`
* `pwrite`

### Response Variables

* `prdata`
* `pslverr`

 Constraint

The address is generated using weighted randomization:

* **80%** of transactions use **valid addresses (0–31)**.
* **20%** of transactions use **invalid addresses (32–100)**.

This ensures that both normal and error scenarios are verified.

---

 3. Generator (`generator.sv`)

The generator creates transactions and sends them to the driver through the `gen2drv` mailbox.

Directed Transactions:

1. Write `32'hAAAA_BBBB` to address `4`
2. Read from address `4`

 Random Transactions:

After the directed tests, the generator creates **20 constrained-random transactions**.

Each transaction is randomized and sent to the driver using:

```systemverilog
gen2drv.put(tr);
```

---

 4. Driver (`driver.sv`)

The driver receives transactions from the generator and converts them into APB bus activity.

The driver performs the following sequence:

1. Initializes all APB control signals.
2. Waits until `presetn` becomes high.
3. Receives a transaction from the mailbox.
4. Drives the **Setup Phase** (`psel = 1`, `penable = 0`).
5. Drives the **Access Phase** (`penable = 1`).
6. Waits until `pready` is asserted.
7. Deasserts `psel` and `penable`.
8. Repeats for the next transaction.

---

 5. Monitor (`monitor.sv`)

The monitor passively observes the APB interface.

Whenever:

* `psel == 1`
* `penable == 1`
* `pready == 1`

the monitor captures:

* `paddr`
* `pwrite`
* `pwdata`
* `prdata`
* `pslverr`

and forwards the transaction to the scoreboard using the `mon2scb` mailbox.

---

 6. Scoreboard (`scoreboard.sv`)

The scoreboard acts as the reference model.

It maintains its own reference memory:

```systemverilog
bit [31:0] ref_mem [32];
```

### Write Verification

For every valid write transaction, the scoreboard stores the expected data into `ref_mem`.

### Read Verification

For every read transaction, the scoreboard compares the DUT output (`prdata`) with the expected value stored in `ref_mem`.

### Invalid Address Verification

For addresses greater than 31, the scoreboard checks that:

* `pslverr == 1`
* `prdata == 32'hDEAD_BEEF`

### Transaction Counter

The scoreboard maintains a transaction counter:

```systemverilog
trans_count
```

This counter is used by the environment to determine when all transactions have been verified.

---

 7. Environment (`environment.sv`)

The environment creates and connects all verification components.

It instantiates:

* Generator
* Driver
* Monitor
* Scoreboard

It also creates two mailboxes:

* `gen2drv`
* `mon2scb`

All components are started concurrently using:

```systemverilog
fork
    gen.run();
    drv.run();
    mon.run();
    scb.run();
join_none
```

The environment waits until the scoreboard verifies all transactions before allowing the simulation to complete.

---

 8. Testbench (`tb.sv`)

The top-level testbench performs the following operations:

* Generates the APB clock.
* Generates the active-low reset.
* Instantiates the APB interface.
* Instantiates the APB Slave DUT.
* Creates the verification environment.
* Starts the verification process.
* Displays the simulation start and completion messages.
* Ends the simulation.

---
