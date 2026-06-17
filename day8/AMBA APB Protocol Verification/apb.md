# APB Slave Verification using SystemVerilog

## Overview

This project implements and verifies an APB (Advanced Peripheral Bus) Slave using SystemVerilog. The design includes a simple APB-compliant slave memory with support for read and write transactions, address checking, error generation, and a self-checking verification environment.

---

## Features

### APB Slave Design

* 32 x 32-bit internal memory.
* Supports APB read and write operations.
* Implements APB state machine:

  * IDLE
  * SETUP
  * ACCESS
* Generates:

  * `PREADY` for transaction completion.
  * `PSLVERR` for invalid address accesses.
* Returns `32'hDEAD_BEEF` for out-of-range addresses.

### Verification Environment

The verification environment is built using SystemVerilog OOP concepts and consists of:

#### Transaction

Represents an APB transaction containing:

* Address (`PADDR`)
* Write Data (`PWDATA`)
* Read/Write Control (`PWRITE`)
* Read Data (`PRDATA`)
* Error Status (`PSLVERR`)

#### Generator

* Generates directed and random transactions.
* Produces both valid and invalid addresses.
* Sends transactions to the driver through a mailbox.

#### Driver

* Converts transactions into APB protocol signals.
* Drives transactions onto the DUT interface.
* Handles APB setup and access phases.

#### Monitor

* Observes DUT activity.
* Captures completed APB transactions.
* Sends collected information to the scoreboard.

#### Scoreboard

* Maintains a reference memory model.
* Compares DUT outputs against expected values.
* Verifies:

  * Write operations
  * Read operations
  * Invalid address handling
* Reports PASS/FAIL messages.

#### Environment

Integrates:

* Generator
* Driver
* Monitor
* Scoreboard

and manages communication using mailboxes.

---

## Test Scenarios

### Directed Tests

#### Write Transaction

* Address: 4
* Data: `0xAAAA_BBBB`

#### Read Transaction

* Reads back data from Address 4
* Verifies correctness

### Random Tests

* 20 randomized APB transactions
* Mix of:

  * Read operations
  * Write operations
  * Valid addresses (0–31)
  * Invalid addresses (32–100)

---

## APB Transaction Flow

```text
IDLE
  |
  V
SETUP (PSEL = 1, PENABLE = 0)
  |
  V
ACCESS (PSEL = 1, PENABLE = 1)
  |
  +--> WRITE : Memory Update
  |
  +--> READ  : Data Returned
```

---

## Project Structure

```text
apb_slave.sv          --> APB Slave DUT
apb_if.sv             --> APB Interface
apb_transaction.sv    --> Transaction Class
generator.sv          --> Stimulus Generator
driver.sv             --> APB Driver
monitor.sv            --> APB Monitor
scoreboard.sv         --> Self-checking Scoreboard
environment.sv        --> Verification Environment
tb_top.sv             --> Top Testbench
```

---

## Simulation Flow

```text
Generator
    |
    V
 Driver
    |
    V
   DUT
    |
    V
 Monitor
    |
    V
Scoreboard
```

1. Generator creates transactions.
2. Driver applies them to the DUT.
3. DUT processes APB transfers.
4. Monitor captures transaction results.
5. Scoreboard checks DUT behavior against the reference model.

---


<img width="1550" height="781" alt="WhatsApp Image 2026-06-17 at 3 46 23 PM" src="https://github.com/user-attachments/assets/16d9c1da-b697-49de-9ccf-f3ba489b7a73" />







