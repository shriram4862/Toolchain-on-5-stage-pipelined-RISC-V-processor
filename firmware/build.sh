
#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

OUTPUT_DIR="build_output"
FIRMWARE_HEX="firmware.hex"

echo "Building Snake Game for FPGA..."
echo "Working directory: $(pwd)"

# Check for toolchain
command -v riscv64-unknown-elf-gcc >/dev/null 2>&1 || {
    echo >&2 "ERROR: RISC-V toolchain not found."
    echo >&2 "Install with: sudo apt install gcc-riscv64-unknown-elf"
    exit 1
}

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Clean previous builds
rm -f "$OUTPUT_DIR"/*.o "$OUTPUT_DIR"/*.elf "$OUTPUT_DIR"/*.bin "$OUTPUT_DIR"/*.lst "$FIRMWARE_HEX"

# Compile with optimization
echo "Compiling source files..."
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -Os -c start.S -o "$OUTPUT_DIR/start.o"
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -Os -c vga.c -o "$OUTPUT_DIR/vga.o"
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -Os -c input.c -o "$OUTPUT_DIR/input.o"
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib -Os -c snake.c -o "$OUTPUT_DIR/snake.o"

# Link with proper memory sections
echo "Linking snake.elf..."
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -ffreestanding -nostdlib \
    -T linker.ld -Wl,--gc-sections -o "$OUTPUT_DIR/snake.elf" \
    "$OUTPUT_DIR/start.o" "$OUTPUT_DIR/vga.o" "$OUTPUT_DIR/input.o" "$OUTPUT_DIR/snake.o"

# Generate binary and hex files
echo "Generating output files..."
riscv64-unknown-elf-objcopy -O binary "$OUTPUT_DIR/snake.elf" "$OUTPUT_DIR/snake.bin"
riscv64-unknown-elf-objdump -d "$OUTPUT_DIR/snake.elf" > "$OUTPUT_DIR/snake.lst"
riscv64-unknown-elf-size "$OUTPUT_DIR/snake.elf"

# Convert to Verilog hex format
echo "Converting to firmware.hex..."
python3 bin_to_hex.py "$OUTPUT_DIR/snake.bin" "$FIRMWARE_HEX"

echo "Build successful!"
echo "Binary size: $(stat -c%s "$OUTPUT_DIR/snake.bin") bytes"
echo "Files generated in $OUTPUT_DIR/"
ls -la "$OUTPUT_DIR/"
