# PPM-to-ASCII Converter (Zig)

A simple Zig program to convert PPM images to ASCII art. It supports multiple output modes, scaling, and optional saving of the output image.

---

## Build

To build the project:

```bash
zig build
```

This will produce the executable at `zig-out/bin/ppm_to_ascii.exe`.

---

## Usage

```bash
zig-out/bin/ppm_to_ascii.exe <image.ppm> [print_type] [scale] [--save]
```

### Parameters

- `image.ppm`  
  The path to the PPM image file you want to convert.

- `print_type` (optional)  
  Determines the ASCII output style. Options:
  - `normal` → standard grayscale ASCII
  - `color` → colored ASCII using ANSI escape codes
  - `full_color` → retains full RGB coloring in ASCII
  **Default:** `normal`

- `scale` (optional)  
  A positive float that scales the image.
  - Values < 1 → downscale
  - Values > 1 → upscale
  **Default:** `1.0`

- `--save` (optional)  
  Saves the converted ASCII output to `output.ppm`. Without this flag, it only prints to the terminal.

---

### Examples

1. Convert `image.ppm` to normal ASCII and print to terminal:

```bash
zig-out/bin/ppm_to_ascii.exe image.ppm
```

2. Convert `image.ppm` to colored ASCII and save the output:

```bash
zig-out/bin/ppm_to_ascii.exe image.ppm color 1.0 --save
```

3. Convert `image.ppm` to full-color ASCII, upscale by 2x, and save:

```bash
zig-out/bin/ppm_to_ascii.exe image.ppm full_color 2.0 --save
```

---

### Notes

- Scaling affects both terminal output and saved PPM file.
- Colors in `color` and `full_color` modes require a terminal that supports ANSI colors.
- The program only supports PPM input.
- ASCII mapping uses an 8x16 font internally. Modify the font array for different ASCII styles.

---

### License

This project is fully open source under the MIT License.

