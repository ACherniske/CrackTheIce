# 🧊 PISC-8 Instruction Set Architecture

This document defines the 8-bit Pedagogical Instruction Set Computer (PISC-8) used in **CrackTheIce**.

## Architecture Overview
* **Data Width:** 8-bit
* **Instruction Width:** 16-bit
* **Registers:** 8 General Purpose Registers (`r0` through `r7`)
    * `r0` is hardwired to `0x00`. Any write to `r0` is ignored.
* **Flags:**
    * `Z` (Zero): Set if the last result was zero.
    * `C` (Carry): Set if the last arithmetic operation resulted in a carry/borrow.

## Instruction Format
Instructions are 16 bits wide, divided into the following fields:

| 15:12 | 11:9 | 8:6 | 5:0 (or 7:0) |
| :--- | :--- | :--- | :--- |
| **Opcode** | **Destination (rd)** | **Source (rs)** | **Immediate / Padding** |

---

## 🕹️ Opcode Table

| Opcode | Hex | Binary Encoding | Operation | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **LDI** | `0x0` | `0000_ddd_iiiiiiii` | `rd ← imm8` | Load 8-bit immediate |
| **MOV** | `0x1` | `0001_ddd_sss_xxxxx` | `rd ← rs` | Register to register copy |
| **ADD** | `0x2` | `0010_ddd_sss_xxxxx` | `rd ← rd + rs` | 8-bit add, updates Z, C |
| **SUB** | `0x3` | `0011_ddd_sss_xxxxx` | `rd ← rd - rs` | 8-bit sub, updates Z, C |
| **AND** | `0x4` | `0100_ddd_sss_xxxxx` | `rd ← rd & rs` | Bitwise AND, updates Z |
| **OR** | `0x5` | `0101_ddd_sss_xxxxx` | `rd ← rd \| rs` | Bitwise OR, updates Z |
| **XOR** | `0x6` | `0110_ddd_sss_xxxxx` | `rd ← rd ^ rs` | Bitwise XOR, updates Z |
| **SHL** | `0x7` | `0111_ddd_xxxxxxxxx` | `rd ← rd << 1` | Left shift, bit 7 to Carry |
| **SHR** | `0x8` | `1000_ddd_xxxxxxxxx` | `rd ← rd >> 1` | Right shift, bit 0 to Carry |
| **ST** | `0x9` | `1001_ddd_sss_xxxxx` | `IO[rd] ← rs` | Write `rs` to I/O port `rd` |
| **LD** | `0xA` | `1010_ddd_sss_xxxxx` | `rd ← IO[rs]` | Read I/O port `rs` into `rd` |
| **JMP** | `0xB` | `1011_xxx_aaaaaaaa` | `PC ← addr8` | Unconditional jump |
| **BZ** | `0xC` | `1100_xxx_aaaaaaaa` | `if Z: PC ← addr8` | Branch if Zero flag set |
| **BNZ** | `0xD` | `1101_xxx_aaaaaaaa` | `if !Z: PC ← addr8` | Branch if Zero flag clear |
| **NOP** | `0xE` | `1110_xxxxxxxxxxxx` | — | No operation (1-cycle bubble) |
| **HALT** | `0xF` | `1111_xxxxxxxxxxxx` | — | Stop execution (PC loop) |

*Legend: `ddd` = destination register, `sss` = source register, `iiiiiiii` = immediate, `aaaaaaaa` = address.*

---

## I/O Mapping (iCEbreaker/iCEstick)

Communication with the outside world (LEDs, UART, Switches) occurs via the `LD` and `ST` instructions.

| Port | Name | Direction | Description |
| :--- | :--- | :--- | :--- |
| **0x00** | `UART_DATA` | Write | Writing a byte here starts UART transmission. |
| **0x01** | `UART_BUSY` | Read | Returns `1` if busy, `0` if ready for next byte. |
| **0x02** | `GPIO_OUT` | Write | Drive output pins (LEDs). |
| **0x03** | `GPIO_IN` | Read | Read input pins (Buttons/Switches). |

---

## Register Conventions
The PISC-8 features 8 general-purpose registers (`r0`–`r7`). While most are interchangeable at the hardware level, the following software conventions are used:

| Register | Alias | Convention | Description |
| :--- | :--- | :--- | :--- |
| **r0** | `zero` | Hardwired Zero | Always reads `0x00`. Writes are ignored. |
| **r1** | `acc` | Accumulator | Primary working register for math and logic. |
| **r2** | `tmp` | Scratch | Secondary operand for ALU operations. |
| **r3–r5** | `t0–t2` | Temporaries | General purpose storage. |
| **r6** | `cnt` | Loop Counter | Conventionally used for iteration counting. |
| **r7** | `ptr` | Pointer | Conventionally used for memory/IO indexing. |