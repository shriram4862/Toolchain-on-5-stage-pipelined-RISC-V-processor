#!/bin/bash
set -e

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

OUTPUT_DIR="build_output"
mkdir -p "$OUTPUT_DIR"

echo "Building from: $(pwd)"
echo "Output to: $OUTPUT_DIR/"

# Check for toolchain
command -v riscv64-unknown-elf-gcc >/dev/null 2>&1 || {
    echo >&2 "ERROR: RISC-V toolchain not found."
    echo >&2 "Install with: sudo apt install gcc-riscv64-unknown-elf"
    exit 1
}

# Clean previous builds
rm -f "$OUTPUT_DIR"/*.o "$OUTPUT_DIR"/*.elf "$OUTPUT_DIR"/*.bin "$OUTPUT_DIR"/*.lst

# Compile each file with explicit output paths
echo "Compiling source files..."
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -c start.S -o "$OUTPUT_DIR/start.o"
echo "✓ Compiled start.S -> $OUTPUT_DIR/start.o"

riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -c vga.c -o "$OUTPUT_DIR/vga.o"
echo "✓ Compiled vga.c -> $OUTPUT_DIR/vga.o"

riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -c input.c -o "$OUTPUT_DIR/input.o"
echo "✓ Compiled input.c -> $OUTPUT_DIR/input.o"

riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -c snake.c -o "$OUTPUT_DIR/snake.o"
echo "✓ Compiled snake.c -> $OUTPUT_DIR/snake.o"

# Link everything together
echo "Linking snake.elf..."
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib \
    -T linker.ld -o "$OUTPUT_DIR/snake.elf" \
    "$OUTPUT_DIR/start.o" "$OUTPUT_DIR/vga.o" "$OUTPUT_DIR/input.o" "$OUTPUT_DIR/snake.o"

# Generate binary
echo "Generating snake.bin..."
riscv64-unknown-elf-objcopy -O binary "$OUTPUT_DIR/snake.elf" "$OUTPUT_DIR/snake.bin"

# Generate disassembly
echo "Generating disassembly..."
riscv64-unknown-elf-objdump -d "$OUTPUT_DIR/snake.elf" > "$OUTPUT_DIR/snake.lst"

echo "Build successful! Files in $OUTPUT_DIR/:"
ls -la "$OUTPUT_DIR/"
