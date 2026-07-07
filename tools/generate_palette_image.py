#!/usr/bin/env python3
"""Generate war_meat_palette.png — visual palette reference for Gem knowledge file."""

from PIL import Image, ImageDraw, ImageFont
import os

# WAR MEAT color palette
PALETTE = {
    "Skóra": [
        ("#f2d2a9", "Jasna"),
        ("#c4956a", "Cień"),
    ],
    "Mundur (gracz)": [
        ("#5a6e3a", "Oliwka"),
        ("#3d4a28", "Cień"),
        ("#8b7355", "Camo"),
    ],
    "Mundur (wróg)": [
        ("#7a3a3a", "Czerwień"),
        ("#5a2a2a", "Cień"),
    ],
    "Ekwipunek": [
        ("#6b6b6b", "Szary"),
        ("#4a4a4a", "Ciemny"),
        ("#8c8c8c", "Metal"),
    ],
    "Broń": [
        ("#4a4a4a", "Korpus"),
        ("#8b6914", "Drewno"),
        ("#6b6b6b", "Lufa"),
    ],
    "Efekty": [
        ("#ffcc00", "Ogień 1"),
        ("#ff6600", "Ogień 2"),
        ("#cc0000", "Krew 1"),
        ("#8b0000", "Krew 2"),
        ("#ffffff", "Flash"),
        ("#ffd700", "Złoto 1"),
        ("#b8860b", "Złoto 2"),
        ("#44cc44", "HP ziel."),
        ("#cc4444", "HP czer."),
    ],
    "Outline": [
        ("#1a1a2e", "Kontur"),
    ],
    "Teren": [
        ("#d4c89a", "Piasek"),
        ("#5a7a3a", "Trawa"),
        ("#7a7a7a", "Beton"),
        ("#6b5a3a", "Ziemia"),
    ],
    "Akcenty klas": [
        ("#a0845c", "Beret Snajp."),
        ("#e07020", "Pasek Inż."),
        ("#3d4a28", "Chusta Zwiad."),
    ],
}


def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    h = hex_color.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def text_color_for_bg(rgb: tuple[int, int, int]) -> tuple[int, int, int]:
    """Return white or black text depending on background luminance."""
    lum = 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]
    return (0, 0, 0) if lum > 128 else (255, 255, 255)


def main():
    swatch_w = 80
    swatch_h = 52
    padding = 4
    header_h = 20
    cols_per_row = 6

    # Calculate max colors in any group for layout
    all_colors = []
    for group_name, colors in PALETTE.items():
        all_colors.append((group_name, colors))

    # Calculate image dimensions
    max_colors = max(len(c) for _, c in all_colors)
    num_groups = len(all_colors)

    img_w = padding + cols_per_row * (swatch_w + padding)
    rows_needed = 0
    col = 0
    for group_name, colors in all_colors:
        needed_cols = len(colors)
        if col + needed_cols > cols_per_row:
            rows_needed += 1
            col = 0
        col += needed_cols
    rows_needed += 1

    img_h = padding + rows_needed * (header_h + swatch_h + padding * 2) + header_h

    img = Image.new("RGB", (img_w, img_h), (24, 24, 28))
    draw = ImageDraw.Draw(img)

    # Try to load a small font
    try:
        font = ImageFont.truetype("arial.ttf", 11)
        font_small = ImageFont.truetype("arial.ttf", 9)
    except (OSError, IOError):
        font = ImageFont.load_default()
        font_small = font

    # Title
    draw.text((padding, padding), "WAR MEAT — PALETA KOLORÓW (OBOWIĄZKOWA)", fill=(255, 255, 255), font=font)

    y = padding + header_h + padding
    x = padding
    col = 0

    for group_name, colors in all_colors:
        needed = len(colors)
        if col + needed > cols_per_row:
            y += header_h + swatch_h + padding * 2
            x = padding
            col = 0

        # Group header
        draw.text((x, y), group_name, fill=(200, 200, 200), font=font_small)

        # Swatches
        sy = y + header_h
        for hex_color, label in colors:
            rgb = hex_to_rgb(hex_color)
            draw.rectangle([x, sy, x + swatch_w - 2, sy + swatch_h - 2], fill=rgb, outline=(60, 60, 60))

            tc = text_color_for_bg(rgb)
            draw.text((x + 3, sy + 3), hex_color, fill=tc, font=font_small)
            draw.text((x + 3, sy + 16), label, fill=tc, font=font_small)

            x += swatch_w + padding
            col += 1

        if col >= cols_per_row:
            y += header_h + swatch_h + padding * 2
            x = padding
            col = 0

    output_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "art_pipeline")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "war_meat_palette.png")
    img.save(output_path)
    print(f"Palette saved to: {output_path}")
    print(f"Size: {img.size[0]}×{img.size[1]} px")


if __name__ == "__main__":
    main()
