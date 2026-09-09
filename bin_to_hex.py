
#!/usr/bin/env python3

def bin_to_hex(input_file, output_file):
    """Convert binary file to Verilog $readmemh compatible format"""
    try:
        with open(input_file, 'rb') as f:
            data = f.read()

        print(f"Read {len(data)} bytes from {input_file}")

        with open(output_file, 'w') as f:
            # Fill entire instruction memory (921 words)
            for i in range(0, 921 * 4, 4):
                if i < len(data):
                    # Read 4 bytes (little-endian)
                    word = data[i] | (data[i+1] << 8) | (data[i+2] << 16) | (data[i+3] << 24)
                else:
                    word = 0x00000013  # nop instruction for empty locations

                f.write('{:08x}\n'.format(word))

        print(f"Generated {output_file} with 921 words")

    except FileNotFoundError:
        print(f"Error: File {input_file} not found")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) == 3:
        bin_to_hex(sys.argv[1], sys.argv[2])
    else:
        bin_to_hex('build_output/snake.bin', 'firmware.hex')
