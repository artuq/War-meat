#!/usr/bin/env python3
"""
Palette Enforcer — post-processes AI-generated sprites to snap colors to WAR MEAT palette.

Usage:
    python palette_enforcer.py <input.png> <output.png> [--outline] [--resize 32]

What it does:
1. Resize to target size (nearest neighbor — no anti-aliasing)
2. Snap every non-transparent pixel to the nearest WAR MEAT palette color
3. Optionally add 1px dark outline (#1a1a2e) around non-transparent regions
"""

import argparse
import math
import sys
from pathlib import Path

from PIL import Image

# WAR MEAT mandatory palette — every color that's allowed
PALETTE = [
    # Skin
    (0xF2, 0xD2, 0xA9),
    (0xC4, 0x95, 0x6A),
    # Player uniform
    (0x5A, 0x6E, 0x3A),
    (0x3D, 0x4A, 0x28),
    (0x8B, 0x73, 0x55),
    # Enemy uniform
    (0x7A, 0x3A, 0x3A),
    (0x5A, 0x2A, 0x2A),
    # Equipment
    (0x6B, 0x6B, 0x6B),
    (0x4A, 0x4A, 0x4A),
    (0x8C, 0x8C, 0x8C),
    # Weapon
    (0x8B, 0x69, 0x14),
    # Effects
    (0xFF, 0xCC, 0x00),
    (0xFF, 0x66, 0x00),
    (0xCC, 0x00, 0x00),
    (0x8B, 0x00, 0x00),
    (0xFF, 0xFF, 0xFF),
    (0xFF, 0xD7, 0x00),
    (0xB8, 0x86, 0x0B),
    (0x44, 0xCC, 0x44),
    (0xCC, 0x44, 0x44),
    # Outline
    (0x1A, 0x1A, 0x2E),
    # Terrain
    (0xD4, 0xC8, 0x9A),
    (0x5A, 0x7A, 0x3A),
    (0x7A, 0x7A, 0x7A),
    (0x6B, 0x5A, 0x3A),
    # Class accents
    (0xA0, 0x84, 0x5C),
    (0xE0, 0x70, 0x20),
]

OUTLINE_COLOR = (0x1A, 0x1A, 0x2E, 255)


def nearest_palette_color(r: int, g: int, b: int) -> tuple[int, int, int]:
    """Find the closest palette color by Euclidean distance in RGB."""
    best = PALETTE[0]
    best_dist = float("inf")
    for pr, pg, pb in PALETTE:
        d = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2
        if d < best_dist:
            best_dist = d
            best = (pr, pg, pb)
    return best


def snap_palette(img: Image.Image) -> Image.Image:
    """Snap all non-transparent pixels to nearest palette color."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 128:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            nr, ng, nb = nearest_palette_color(r, g, b)
            pixels[x, y] = (nr, ng, nb, 255)
    return img


def add_outline(img: Image.Image) -> Image.Image:
    """Add 1px outline around non-transparent pixels."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size

    # Find non-transparent pixel coords
    solid = set()
    for y in range(h):
        for x in range(w):
            if pixels[x, y][3] > 0:
                solid.add((x, y))

    # Find outline pixels (transparent but adjacent to solid)
    outline_pixels = set()
    for x, y in solid:
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in solid:
                outline_pixels.add((nx, ny))

    # Paint outline
    for x, y in outline_pixels:
        pixels[x, y] = OUTLINE_COLOR

    return img


def main():
    p = argparse.ArgumentParser(description="Enforce WAR MEAT palette on AI-generated sprites")
    p.add_argument("input", help="Input PNG file")
    p.add_argument("output", help="Output PNG file")
    p.add_argument("--resize", type=int, default=0, help="Resize to NxN pixels (nearest neighbor)")
    p.add_argument("--outline", action="store_true", help="Add 1px dark outline around sprite")
    args = p.parse_args()

    img = Image.open(args.input).convert("RGBA")
    print(f"Input: {img.size[0]}×{img.size[1]} px")

    # Resize if requested
    if args.resize > 0:
        src_w, src_h = img.size
        target = args.resize
        ratio = max(src_w, src_h) / target
        if ratio > 4:
            # Large AI image → use LANCZOS to preserve detail, then palette snap handles the rest
            img = img.resize((target, target), Image.LANCZOS)
            print(f"Resized to: {target}×{target} px (LANCZOS — source was {ratio:.0f}× larger)")
        else:
            # Already small/pixel art → nearest neighbor to keep crisp pixels
            img = img.resize((target, target), Image.NEAREST)
            print(f"Resized to: {target}×{target} px (NEAREST)")

    # Snap to palette
    img = snap_palette(img)
    unique_colors = set()
    px = img.load()
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a > 0:
                unique_colors.add(f"#{r:02x}{g:02x}{b:02x}")
    print(f"Colors after snap: {len(unique_colors)} ({', '.join(sorted(unique_colors))})")

    # Add outline
    if args.outline:
        img = add_outline(img)
        print("Outline added (1px #1a1a2e)")

    # Save
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path)
    print(f"Saved: {output_path}")


if __name__ == "__main__":
    main()
