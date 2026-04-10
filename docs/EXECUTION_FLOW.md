# 🧠 How Assembly Becomes Hardware Execution (PISC-8)

This section explains how a `.s` assembly file is transformed into something the FPGA can execute.

---

## The Full Flow

hello.s  →  assembler  →  hello.mem  →  Verilog ROM  →  CPU executes

---

## Assembly (`.s` file)

The `.s` file contains **human-readable instructions** written for the PISC-8 CPU:

```bash
LDI r1, #'H'
ST  r3, r1
```

These instructions describe *what you want the CPU to do*, but they are not directly understood by hardware.

---

## Assembler (Python)

The assembler (`pisc8asm.py`) converts each instruction into a **16-bit machine code value**.

Example:

```bash
LDI r1, #'H'
```

Becomes something like:

```
1248
```

Each instruction is encoded according to the PISC-8 instruction format.

---

## Memory File (`.mem`)

The assembler outputs a `.mem` file, which is just a list of hexadecimal values:

```
0120
1340
9C00
...
```

* Each line = **one 16-bit instruction**
* Stored in **hexadecimal format**
* Represents the actual machine code the CPU executes

---

## Loading into Verilog (ROM)

Inside the CPU (`pisc8_core.v`), the `.mem` file is loaded into a ROM using:

```bash
reg [15:0] rom [0:255];

initial begin
$readmemh("asm/hello.mem", rom);
end
```

### What `$readmemh` does:

* Reads the `.mem` file at synthesis/simulation time
* Loads each line into memory:

```
rom[0] = first instruction
rom[1] = second instruction
rom[2] = third instruction
...
```

---

## 5️⃣ CPU Execution

The CPU uses a **Program Counter (PC)** to step through instructions:

```
PC = 0 → rom[0]
PC = 1 → rom[1]
PC = 2 → rom[2]
```

Each clock cycle:

#### 1. Fetch

```
instruction = rom[PC]
```

#### 2. Decode

```
opcode = instruction[15:12]
rd     = instruction[11:9]
rs     = instruction[8:6]
```

#### 3. Execute

* Perform ALU operation
* Access I/O
* Or jump/branch

---

## Example End-to-End

```
Assembly:
LDI r1, #'A'

`.mem`:
0241

In ROM:
rom[0] = 16'b0000_001_01000001

Execution:
r1 ← 0x41
```

---

## I/O and UART Example

When your program writes to UART:

```
ST r3, r1   ; write to UART_DATA
```

The CPU generates signals:

```bash
io_addr  = 0x00
io_wdata = 0x41
io_we    = 1
```

Your Verilog peripheral sees this and sends the byte:

```bash
uart_tx_data  <= io_wdata;
uart_tx_valid <= 1;
```