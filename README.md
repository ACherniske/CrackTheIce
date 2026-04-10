# 🧊 CrackTheIce
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![FPGA: iCE40](https://img.shields.io/badge/FPGA-iCE40UP5K%2FHX1K-blue)](https://www.latticesemi.com/Products/FPGAandCPLD/iCE40)
[![Toolchain: OSS-CAD-Suite](https://img.shields.io/badge/Toolchain-OSS--CAD--Suite-brightgreen)](https://github.com/YosysHQ/oss-cad-suite-build)

**CrackTheIce** is an educational project designed to bridge the gap between "blinking an LED" and understanding how a CPU actually works. It implements a minimal 8-bit soft-core processor (PISC-8) on the iCE40 FPGA using a 3-stage pipeline.

## Project Goals
- **Transparency:** No complex abstractions. See how every bit moves.
- **Portability:** Targets both the **iCEbreaker** and **iCEstick**.
- **Toolchain Mastery:** Uses the 100% open-source flow (Yosys, nextpnr, icestorm).

## The Architecture
The core is a **3-stage pipeline** (Fetch → Decode → Execute). This allows the CPU to work on three different instructions simultaneously, introducing students to the concepts of throughput and timing.

### System Features:
* **Core:** PISC-8 (Pedagogical Instruction Set Computer)
* **Clock:** 12 MHz (Internal Oscillator)
* **Memory:** Initialized BRAM/SPRAM from `.mem` files.
* **Peripherals:** 8N1 UART Transmitter (115200 baud).

### 1. Prerequisites
You will need the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) installed.

### 2. How to build
The project uses a standard `make` flow to handle both the software (Assembly) and hardware (Verilog).

> ⚠️ **Makefile Compatibility Warning:**
> The provided Makefile is **only compatible with Unix/Linux systems**.

### Core Commands

The following commands are available via the `Makefile`. You can run them from the root of the repository.

| Command | Action | Description |
| :--- | :--- | :--- |
| `make asm` | **Assemble** | Converts `asm/hello.s` into `firmware.mem` using the Python assembler. |
| `make` | **Synthesize** | Runs the full hardware flow (Yosys, nextpnr, and icepack) to create the bitstream. |
| `make flash` | **Program** | Uploads the compiled `.bin` file to the FPGA via `iceprog`. |
| `make clean` | **Reset** | Removes the `build/` directory and all generated memory files. |
| `make BOARD=icestick` | **Switch Target** | Overrides the default iCEbreaker target to build for the iCEstick. |

---

### Usage Example

To perform a clean build and program your board in one go, you would run:
```bash
make clean
make flash
```

You can override this by specifying a different assembly file using the ASM variable:

```bash
# Build and flash default program
make flash

# Build and flash a custom program (ex. goodbye.s)
make flash ASM=asm/goodbye.s
```