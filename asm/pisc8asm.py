import sys
import re
import argparse
from typing import Optional, List, Dict


# ---------------------------------------------------------------------------
# ISA encoding tables
# ---------------------------------------------------------------------------

OPCODES = {
    "LDI":  0x0, "MOV":  0x1, "ADD":  0x2, "SUB":  0x3,
    "AND":  0x4, "OR":   0x5, "XOR":  0x6, "SHL":  0x7,
    "SHR":  0x8, "ST":   0x9, "LD":   0xA, "JMP":  0xB,
    "BZ":   0xC, "BNZ":  0xD, "NOP":  0xE, "HALT": 0xF,
}

REGISTERS = {
    "r0": 0, "r1": 1, "r2": 2, "r3": 3,
    "r4": 4, "r5": 5, "r6": 6, "r7": 7,
    # Aliases
    "zero": 0, "acc": 1, "tmp": 2,
    "t0": 3, "t1": 4, "t2": 5,
    "cnt": 6, "ptr": 7,
}

PORT_CONSTANTS = {
    "UART_DATA": 0x00,
    "UART_BUSY": 0x01,
    "GPIO_OUT":  0x02,
    "GPIO_IN":   0x03,
}


# ---------------------------------------------------------------------------
# Error class
# ---------------------------------------------------------------------------

class AssemblerError(Exception):
    """Custom exception for assembler errors with line number tracking."""
    def __init__(self, msg: str, line_num: Optional[int] = None):
        self.line_num = line_num
        super().__init__(msg)


# ---------------------------------------------------------------------------
# Helper: parsing
# ---------------------------------------------------------------------------

def parse_imm(token: str, labels: Dict[str, int]) -> int:
    """
    Parse an immediate value token. Handles:
        - Decimal:    42
        - Hex:       0x2A
        - Binary:    0b101010
        - Character: 'H'
        - Port name: UART_DATA
        - Label:     loop_start

    Args:
        token (str): The token to parse.
        labels (dict): Mapping of label names to addresses.

    Returns:
        int: The parsed immediate value.
    """
    token = token.strip().lstrip('#').strip()

    if token.upper() in PORT_CONSTANTS:
        return PORT_CONSTANTS[token.upper()]

    if token in labels:
        return labels[token]

    if token.startswith("'") and token.endswith("'") and len(token) == 3:
        return ord(token[1])

    try:
        return int(token, 0)  # auto-detect base (0x for hex, 0b for binary)
    except ValueError:
        raise ValueError(f"Invalid immediate value: {token}")


def parse_reg(token: str) -> int:
    """
    Parse a register token. Handles:
        - r0, r1, ..., r7
        - Aliases: zero, acc, tmp, t0, t1, t2, cnt, ptr

    Args:
        token (str): The token to parse.

    Returns:
        int: The register number (0-7).
    """
    token = token.strip().lower()
    if token not in REGISTERS:
        raise AssemblerError(f"Invalid register: {token}")
    return REGISTERS[token]


# ---------------------------------------------------------------------------
# Encoding functions - one per instruction form
# ---------------------------------------------------------------------------

def enc_ldi(rd: int, imm8: int) -> int:
    """LDI rd, #imm8  →  0000_ddd_iiiiiiii"""
    if not (0 <= imm8 <= 255):
        raise ValueError(f"LDI immediate out of range: {imm8}")
    return (0x0 << 12) | (rd << 9) | (imm8 & 0xFF)


def enc_reg_reg(op: int, rd: int, rs: int) -> int:
    """MOV/ADD/SUB/AND/OR/XOR/ST/LD  →  oooo_ddd_sss_000000"""
    return (op << 12) | (rd << 9) | (rs << 6)


def enc_reg_only(op: int, rd: int) -> int:
    """SHL/SHR  →  oooo_ddd_000_000000"""
    return (op << 12) | (rd << 9)


def enc_branch(op: int, addr8: int) -> int:
    """JMP/BZ/BNZ  →  oooo_000_aaaaaaaa"""
    if not (0 <= addr8 <= 255):
        raise ValueError(f"Branch target out of range: {addr8}")
    return (op << 12) | (addr8 & 0xFF)


def enc_no_arg(op: int) -> int:
    """NOP/HALT  →  oooo_000_000_000000"""
    return op << 12


# ---------------------------------------------------------------------------
# Assembler: two-pass
# ---------------------------------------------------------------------------

class Assembler:
    """Handles the two-pass assembly process for PISC-8 source code."""

    def __init__(self, rom_depth: int = 256):
        self.rom_depth = rom_depth

    def assemble(self, source: str) -> List[int]:
        """
        Translates assembly source string into a list of machine code words.
        
        Args:
            source (str): The PISC-8 assembly source code.
            
        Returns:
            List[int]: List of 16-bit instruction words.
        """
        lines = source.splitlines()
        labels = {}
        pc = 0
        cleaned = []  # List of (line_number, stripped_text)

        # --- Pass 1: collect labels and count addresses ---
        for line_no, raw in enumerate(lines, start=1):
            # Strip comments and whitespace
            line = raw.split(';')[0].strip()
            if not line:
                continue

            # Handle .org directive
            if line.lower().startswith('.org'):
                parts = line.split()
                if len(parts) < 2:
                    raise AssemblerError(".org requires address", line_no)
                pc = int(parts[1], 0)
                cleaned.append((line_no, line))
                continue

            # Handle label definitions
            if line.endswith(':'):
                label_name = line[:-1].strip()
                if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', label_name):
                    raise AssemblerError(f"Invalid label: {label_name}", line_no)
                if label_name in labels:
                    raise AssemblerError(f"Duplicate label: {label_name}", line_no)
                labels[label_name] = pc
                continue

            cleaned.append((line_no, line))
            pc += 1

        # --- Pass 2: encode instructions ---
        # Initialize memory with NOPs
        words = [enc_no_arg(OPCODES["NOP"])] * self.rom_depth
        pc = 0

        for line_no, line in cleaned:
            if line.lower().startswith('.org'):
                pc = int(line.split()[1], 0)
                continue

            try:
                word = self._encode_instruction(line, labels, pc)
                if pc < self.rom_depth:
                    words[pc] = word
                pc += 1
            except Exception as e:
                raise AssemblerError(str(e), line_no)

        if pc > self.rom_depth:
            raise AssemblerError(f"Program exceeds ROM: {pc}/{self.rom_depth}")

        return words

    def _encode_instruction(self, line: str, labels: dict, pc: int) -> int:
        """Internal helper to parse a single line and return its bit-encoding."""
        parts = line.split(None, 1)
        mnemonic = parts[0].upper()
        op_str = parts[1] if len(parts) > 1 else ""

        # Comma-separation logic (respects character literals like ',')
        operands = []
        if op_str:
            curr, in_quote = "", False
            for ch in op_str:
                if ch == "'":
                    in_quote = not in_quote
                    curr += ch
                elif ch == ',' and not in_quote:
                    operands.append(curr.strip())
                    curr = ""
                else:
                    curr += ch
            if curr.strip():
                operands.append(curr.strip())

        if mnemonic not in OPCODES:
            raise ValueError(f"Unknown mnemonic: {mnemonic}")

        op = OPCODES[mnemonic]

        if mnemonic in ("NOP", "HALT"):
            if operands:
                raise ValueError(f"{mnemonic} takes no operands")
            return enc_no_arg(op)

        if mnemonic == "LDI":
            if len(operands) != 2:
                raise ValueError("LDI requires: rd, #imm8")
            return enc_ldi(parse_reg(operands[0]), parse_imm(operands[1], labels))

        if mnemonic in ("MOV", "ADD", "SUB", "AND", "OR", "XOR", "ST", "LD"):
            if len(operands) != 2:
                raise ValueError(f"{mnemonic} requires: rd, rs")
            return enc_reg_reg(op, parse_reg(operands[0]), parse_reg(operands[1]))

        if mnemonic in ("SHL", "SHR"):
            if len(operands) != 1:
                raise ValueError(f"{mnemonic} requires: rd")
            return enc_reg_only(op, parse_reg(operands[0]))

        if mnemonic in ("JMP", "BZ", "BNZ"):
            if len(operands) != 1:
                raise ValueError(f"{mnemonic} requires: label or address")
            return enc_branch(op, parse_imm(operands[0], labels))

        raise ValueError(f"Unhandled mnemonic: {mnemonic}")


# ---------------------------------------------------------------------------
# Main: CLI entry point
# ---------------------------------------------------------------------------

def main():
    """Main CLI entry point for the PISC-8 assembler."""
    parser = argparse.ArgumentParser(
        description="PISC-8 Assembler - produces Verilog $readmemh .mem files"
    )
    parser.add_argument("source", help="Assembly source file (.s)")
    parser.add_argument("-o", "--output", help="Output .mem file")
    parser.add_argument("--depth", type=int, default=256,
                        help="ROM depth in 16-bit words (default: 256)")
    parser.add_argument("--list", action="store_true",
                        help="Print annotated listing to stdout")
    args = parser.parse_args()

    out_path = args.output or (args.source.rsplit('.', 1)[0] + '.mem')

    try:
        with open(args.source) as f:
            source = f.read()

        asm = Assembler(rom_depth=args.depth)
        words = asm.assemble(source)
    except (AssemblerError, FileNotFoundError) as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    # Write .mem file (4-digit hex words)
    with open(out_path, 'w') as f:
        for w in words:
            f.write(f"{w:04X}\n")

    print(f"Assembled {len(words)} instruction(s) → {out_path}")

    # Optional listing output
    if args.list:
        print(f"\n{'Addr':>4}  {'Word':>6}  Bits")
        print("-" * 42)
        for i, w in enumerate(words):
            bits = f"{w:016b}"
            grouped = f"{bits[0:4]}_{bits[4:7]}_{bits[7:10]}_{bits[10:]}"
            print(f"  {i:02X}   {w:04X}   {grouped}")


if __name__ == "__main__":
    main()