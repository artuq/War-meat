#!/usr/bin/env python3
"""
Sheet Assembler — combines individual 32×32 PNG frames into sprite sheets.

Usage:
    python sheet_assembler.py <input_dir> <output.png> [--cols N] [--size 32]

Examples:
    # Assemble idle animation (4 frames) into a 128×32 strip:
    python sheet_assembler.py frames/assault_idle/ assault_idle_sheet.png --cols 4

    # Assemble 4 directions × 4 frames into 128×128 grid:
    # Place files as: dir_N_01.png, dir_N_02.png, ..., dir_E_01.png, ...
    python sheet_assembler.py frames/assault_walk/ assault_walk_sheet.png --cols 4

    # Assemble all frames in folder left-to-right, auto-detect column count:
    python sheet_assembler.py frames/ output.png

File naming convention (for multi-row sheets):
    {prefix}_{row}_{col}.png
    Example: assault_0_0.png, assault_0_1.png, assault_1_0.png, ...
    Or simply: 01.png, 02.png, 03.png (single row, sorted alphabetically)
"""

import argparse
import os
import re
import sys
from pathlib import Path

from PIL import Image


def parse_args():
    p = argparse.ArgumentParser(description="Assemble 32×32 frames into sprite sheets")
    p.add_argument("input_dir", help="Directory containing individual frame PNGs")
    p.add_argument("output", help="Output sprite sheet PNG path")
    p.add_argument("--cols", type=int, default=0, help="Columns per row (0=auto: all in one row)")
    p.add_argument("--size", type=int, default=32, help="Frame size in pixels (default: 32)")
    p.add_argument("--pad", type=int, default=0, help="Padding between frames (default: 0)")
    p.add_argument("--bg", default="transparent", help="Background: 'transparent' or hex color like '#FF00FF'")
    return p.parse_args()


def hex_to_rgba(hex_color: str) -> tuple:
    h = hex_color.lstrip("#")
    if len(h) == 6:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)
    elif len(h) == 8:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), int(h[6:8], 16))
    return (255, 0, 255, 255)


def sort_key(filename: str):
    """Sort by row_col pattern if present, otherwise alphabetically."""
    match = re.search(r"(\d+)[_-](\d+)", filename)
    if match:
        return (int(match.group(1)), int(match.group(2)))
    # Try just a number
    match = re.search(r"(\d+)", filename)
    if match:
        return (0, int(match.group(1)))
    return (0, 0)


def detect_grid(filenames: list[str]) -> tuple[int, int]:
    """Detect rows and cols from filename patterns."""
    max_row = 0
    max_col = 0
    has_grid = False
    for f in filenames:
        match = re.search(r"(\d+)[_-](\d+)", f)
        if match:
            has_grid = True
            max_row = max(max_row, int(match.group(1)))
            max_col = max(max_col, int(match.group(2)))
    if has_grid:
        return (max_row + 1, max_col + 1)
    return (1, len(filenames))


def main():
    args = parse_args()
    input_dir = Path(args.input_dir)

    if not input_dir.is_dir():
        print(f"Error: {input_dir} is not a directory")
        sys.exit(1)

    # Collect PNG files
    frames = sorted(
        [f for f in os.listdir(input_dir) if f.lower().endswith(".png")],
        key=sort_key,
    )

    if not frames:
        print(f"Error: No PNG files found in {input_dir}")
        sys.exit(1)

    print(f"Found {len(frames)} frames")

    # Determine grid
    if args.cols > 0:
        cols = args.cols
        rows = (len(frames) + cols - 1) // cols
    else:
        rows, cols = detect_grid(frames)

    frame_size = args.size
    pad = args.pad

    sheet_w = cols * frame_size + (cols - 1) * pad
    sheet_h = rows * frame_size + (rows - 1) * pad

    # Create sheet
    if args.bg == "transparent":
        sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    else:
        sheet = Image.new("RGBA", (sheet_w, sheet_h), hex_to_rgba(args.bg))

    # Place frames
    for i, fname in enumerate(frames):
        # Determine position
        match = re.search(r"(\d+)[_-](\d+)", fname)
        if match and args.cols == 0:
            row = int(match.group(1))
            col = int(match.group(2))
        else:
            row = i // cols
            col = i % cols

        frame = Image.open(input_dir / fname).convert("RGBA")

        # Resize to target if needed (nearest neighbor for pixel art)
        if frame.size != (frame_size, frame_size):
            print(f"  Warning: {fname} is {frame.size}, resizing to {frame_size}×{frame_size}")
            frame = frame.resize((frame_size, frame_size), Image.NEAREST)

        x = col * (frame_size + pad)
        y = row * (frame_size + pad)
        sheet.paste(frame, (x, y))

    # Save
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path)

    print(f"Sheet saved: {output_path}")
    print(f"Size: {sheet_w}×{sheet_h} px ({cols} cols × {rows} rows × {frame_size}px)")
    print(f"Grid: {cols}×{rows} = {cols * rows} slots ({len(frames)} filled)")


if __name__ == "__main__":
    main()
