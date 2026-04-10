# CrackTheIce - PISC-8 iCE40 Build System
BOARD   ?= icebreaker
TOP     := pisc8_top
DEVICE  := up5k
PCF     := constraints/icebreaker.pcf

# Toolchain Path Setup
OSS_CAD_SUITE_PATH ?= $(HOME)/oss-cad-suite
ifneq ($(wildcard $(OSS_CAD_SUITE_PATH)/bin/yosys),)
    export PATH := $(OSS_CAD_SUITE_PATH)/bin:$(PATH)
endif

# Files
SOURCES := rtl/pisc8_top.v rtl/pisc8_core.v rtl/uart_tx.v
ASM_SRC := asm/hello.s
MEM_OUT := asm/firmware.mem

# Tools
YOSYS    := yosys
NEXTPNR  := nextpnr-ice40
ICEPACK  := icepack
ICEPROG  := iceprog
PYTHON   := python3

.PHONY: all clean flash asm

all: build/$(TOP).bin

# 1. Assemble the software
asm: $(MEM_OUT)

$(MEM_OUT): $(ASM_SRC)
	@echo "  ASM   $<"
	$(PYTHON) asm/pisc8asm.py $< -o $@

# 2. Synthesis
build/$(TOP).json: $(SOURCES) $(MEM_OUT)
	@echo "  SYN   $@"
	@mkdir -p build
	$(YOSYS) -q -p "synth_ice40 -top $(TOP) -json $@" $(SOURCES)

# 3. Place and Route
build/$(TOP).asc: build/$(TOP).json $(PCF)
	@echo "  PNR   $@"
	$(NEXTPNR) -q --$(DEVICE) --pcf $(PCF) --json $< --asc $@

# 4. Pack Bitstream
build/$(TOP).bin: build/$(TOP).asc
	@echo "  PACK  $@"
	$(ICEPACK) $< $@

# 5. Flash to Hardware
flash: build/$(TOP).bin
	@echo "  PROG  $<"
	$(ICEPROG) $<

clean:
	rm -rf build/ asm/*.mem