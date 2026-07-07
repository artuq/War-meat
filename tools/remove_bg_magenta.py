"""Remove a chroma-key background color from a PNG and replace it with transparency.

Default key color is magenta (#FF00FF), the WAR MEAT pipeline standard.
Pixels within ``--tolerance`` of the key color are made fully transparent;
pixels close to (but not exactly) the key color are partially faded to reduce
the "halo" / colored fringe that survives a hard threshold cutoff.

Usage:
    python tools/remove_bg_magenta.py input.png output.png
    python tools/remove_bg_magenta.py input.png output.png --color FFFFFF
    python tools/remove_bg_magenta.py input.png output.png --tolerance 24
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


def parse_hex_color(value: str) -> tuple[int, int, int]:
    v = value.lstrip("#").strip()
    if len(v) != 6:
        raise argparse.ArgumentTypeError(f"Color must be 6 hex digits, got: {value!r}")
    try:
        return int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"Invalid hex color: {value!r}") from exc


def remove_background(
    src: Path,
    dst: Path,
    key: tuple[int, int, int],
    tolerance: int,
    fringe: int,
) -> int:
    img = Image.open(src).convert("RGBA")
    pixels = img.load()
    kr, kg, kb = key
    cleared = 0

    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            dr, dg, db = abs(r - kr), abs(g - kg), abs(b - kb)
            dist = max(dr, dg, db)
            if dist <= tolerance:
                pixels[x, y] = (0, 0, 0, 0)
                cleared += 1
            elif dist <= tolerance + fringe:
                # Fade fringe pixels to soften the edge
                falloff = (dist - tolerance) / max(fringe, 1)
                pixels[x, y] = (r, g, b, int(a * falloff))

    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, "PNG")
    return cleared


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="Input PNG file")
    parser.add_argument("output", type=Path, help="Output PNG file")
    parser.add_argument(
        "--color",
        type=parse_hex_color,
        default=(255, 0, 255),
        help="Chroma-key color as 6 hex digits (default: FF00FF magenta)",
    )
    parser.add_argument(
        "--tolerance",
        type=int,
        default=12,
        help="Per-channel max distance treated as exact key (default: 12)",
    )
    parser.add_argument(
        "--fringe",
        type=int,
        default=8,
        help="Extra distance band that fades to transparent (default: 8)",
    )
    args = parser.parse_args(argv)

    if not args.input.exists():
        print(f"Input file not found: {args.input}", file=sys.stderr)
        return 1

    cleared = remove_background(
        args.input, args.output, args.color, args.tolerance, args.fringe
    )
    total = Image.open(args.input).size
    print(
        f"Wrote {args.output} ({cleared} of {total[0] * total[1]} pixels cleared)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
