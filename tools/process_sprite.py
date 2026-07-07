"""
WAR MEAT — Process Sprite (all-in-one pipeline tool)
=====================================================
Converts a raw AI Studio output (JPG or PNG) to a clean game-ready PNG:
  1. Removes magenta #FF00FF (or white) background → transparency
  2. Snaps all colors to WAR MEAT palette
  3. Saves to assets/sprites/<category>/<name>.png

USAGE — drag and drop OR command line:
  process_sprite.py <input_file>
  process_sprite.py <input_file> [--category soldiers|enemies|weapons|loot|fx] [--resize 128] [--outline] [--color FFFFFF]

Category is auto-detected from filename if not specified:
  *assault*, *sniper*, *medic*, *engineer*, *scout*, *heavy*         → soldiers/
  *frankfurter*, *bratwurst*, *weisswurst*, *chorizo*, *kielbasa*    → soldiers/
  *parowka*, *sausage*, *wurst*                                      → soldiers/
  *grunt*, *rusher*, *tank*, *shooter*, *grenadier*                  → enemies/
  *jungle*, *desert*, *bunker*                                       → enemies/
  *karabin*, *pistol*, *strzelba*, *smg*, *sniper_r*, *knife*        → weapons/
  *coin*, *crate*, *gem*                                             → loot/
  *flash*, *splat*, *spark*, *bullet*, *rocket*                      → fx/
  anything else                                                       → sprites/ root
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path


def _pause() -> None:
    """Pause for the user to read — only when running as a standalone EXE
    with a real stdin (i.e. NOT when called from the GUI)."""
    if not getattr(sys, "frozen", False):
        return
    if sys.stdin is None or not getattr(sys.stdin, "isatty", lambda: False)():
        return
    try:
        input("Press Enter to close...")
    except OSError:
        pass

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow not installed. Run:  pip install Pillow")
    _pause()
    sys.exit(1)

# ── WAR MEAT palette ────────────────────────────────────────────────────────
PALETTE: list[tuple[int, int, int]] = [
    # ── Sausage soldier casings (War Meat concept) ──────────────────────────
    (0xE8, 0xA0, 0x60), (0xB8, 0x6A, 0x30),  # frankfurter casing / shadow
    (0xD4, 0x90, 0x50), (0xF0, 0xC0, 0x90),  # bratwurst tan / highlight
    (0xE8, 0xD0, 0xA0), (0xC0, 0xA8, 0x70),  # weisswurst cream / shadow
    (0x9A, 0x4A, 0x20),                        # smoked kielbasa
    (0xC0, 0x60, 0x30),                        # chorizo red-brown
    # ── Legacy skin (kept for backward compat with old sprites) ─────────────
    (0xF2, 0xD2, 0xA9), (0xC4, 0x95, 0x6A),  # human skin
    # ── Military & environment ───────────────────────────────────────────────
    (0x5A, 0x6E, 0x3A), (0x3D, 0x4A, 0x28),  # olive uniform
    (0x8B, 0x73, 0x55), (0x7A, 0x3A, 0x3A),  # enemy / terrain mix
    (0x5A, 0x2A, 0x2A),                        # enemy shadow
    (0x6B, 0x6B, 0x6B), (0x4A, 0x4A, 0x4A), (0x8C, 0x8C, 0x8C),  # grays
    (0x1A, 0x1A, 0x2E),                        # navy outline
    (0x2A, 0x4A, 0x7A), (0x4A, 0x6E, 0x9E),  # blue armor
    (0x4A, 0x9E, 0xFF),                        # blue lens
    (0x8B, 0x69, 0x14), (0x6B, 0x5A, 0x14),  # brown wood
    (0xA0, 0x84, 0x5C),                        # beret
    (0xE0, 0x70, 0x20),                        # orange accent
    (0xFF, 0xD7, 0x00), (0xB8, 0x86, 0x0B),  # gold
    (0xFF, 0xCC, 0x00),                        # glow yellow
    (0xFF, 0x66, 0x00),                        # orange glow
    (0xCC, 0x00, 0x00), (0x8B, 0x00, 0x00),  # red
    (0xFF, 0xFF, 0xFF),                        # white
    (0xD4, 0xC8, 0x9A),                        # sand
    (0x5A, 0x7A, 0x3A),                        # jungle grass
    (0x7A, 0x7A, 0x7A),                        # concrete
    (0x6B, 0x5A, 0x3A),                        # terrain detail
    (0x5A, 0x3A, 0x6A), (0x3A, 0x2A, 0x4A),  # purple (Tank boss)
    (0x3A, 0x5A, 0x7A), (0x8B, 0x7A, 0x2A),  # Shooter blue / Grenadier yellow
]

OUTLINE_COLOR = (0x1A, 0x1A, 0x2E, 255)

# ── Auto-category detection ──────────────────────────────────────────────────
CATEGORY_KEYWORDS: list[tuple[list[str], str]] = [
    ([
        # Klasy po starych nazwach (pliki nadal: Assault.png itp.)
        "assault", "sniper", "medic", "engineer", "scout", "heavy", "soldier", "shadow",
        # Klasy po nazwach kiełbas (War Meat concept)
        "frankfurter", "bratwurst", "weisswurst", "kielbasa", "chorizo", "parowka",
        "sausage", "wurst", "wienerschnitzel",
    ], "soldiers"),
    (["grunt", "rusher", "tank", "shooter", "grenadier", "jungle", "desert", "bunker", "boss",
      "shield"], "enemies"),
    (["karabin", "pistol", "strzelba", "smg", "sniper_r", "rifle", "shotgun", "knife", "noz", "granatnik", "weapon", "bron"], "weapons"),
    (["coin", "crate", "gem", "loot"], "loot"),
    (["flash", "splat", "spark", "bullet", "rocket", "hit", "muzzle", "fx", "effect"], "fx"),
    # UI cards — filenames follow pattern: {item}_{tier}.png or {stat}_{tier}.png
    (["_common", "_uncommon", "_rare", "_epic", "_legendary",
      "card_rifle", "card_shotgun", "card_pistol", "card_smg",
      "card_sniper", "card_grenade_launcher", "card_knife",
      "dmg_", "spd_", "hp_", "luck_", "rng_", "fr_", "arm_", "regen_"], "cards"),
]

# Keywords that indicate shop subfolder (vs upgrade)
_SHOP_KEYWORDS = ["rifle", "shotgun", "pistol", "smg", "sniper", "grenade_launcher", "knife",
                  "assault_class", "sniper_class", "medic_class", "engineer_class",
                  "scout_class", "heavy_class"]
_UPGRADE_KEYWORDS = ["dmg_", "spd_", "hp_", "luck_", "rng_", "fr_", "arm_", "regen_"]


def detect_card_subfolder(stem: str) -> str:
    """Return 'shop' or 'upgrade' based on filename."""
    lower = stem.lower()
    if any(kw in lower for kw in _UPGRADE_KEYWORDS):
        return "upgrade"
    return "shop"


# ── Expected input size and auto-resize target per category ──────────────────
# (expected_input_px, auto_resize_output_px)  — 0 = don't auto-resize
CATEGORY_SIZES: dict[str, tuple[int, int]] = {
    "soldiers": (1024, 128),
    "enemies":  (1024, 80),
    "weapons":  (1024, 0),   # varies — user must pass --resize manually
    "loot":     (512,  48),
    "fx":       (512,  64),
    "cards":    (1024, 0),   # always 192x256 — handled separately
}

# ── Per-asset auto-resize (non-square or special sizes) ──────────────────────
# Maps lowercase filename stem substring → (width, height).
# Takes priority over CATEGORY_SIZES auto-resize when filename matches.
STEM_SIZES: dict[str, tuple[int, int]] = {
    # "hand" removed — hands are baked into weapon sprites (Brotato-style)
    "shadow":         (96, 32),
    "shield_overlay": (128, 128),
    "shield overlay": (128, 128),
}


def detect_category(stem: str) -> str:
    lower = stem.lower()
    for keywords, category in CATEGORY_KEYWORDS:
        if any(kw in lower for kw in keywords):
            return category
    return ""  # root sprites/


def nearest_palette_color(r: int, g: int, b: int) -> tuple[int, int, int]:
    """Find nearest palette color using Redmean — perceptually weighted RGB distance.

    Plain Euclidean RGB treats red/green/blue channels equally, which doesn't
    match human perception: eye is most sensitive to green, least to blue.
    Redmean weights channels based on the average redness of the two colors,
    preventing warm browns from snapping to olive greens (a common failure with
    naive Euclidean distance).
    """
    best = PALETTE[0]
    best_dist = float("inf")
    for pr, pg, pb in PALETTE:
        rmean = (r + pr) / 2.0
        dr = r - pr
        dg = g - pg
        db = b - pb
        d = (2.0 + rmean / 256.0) * dr * dr + 4.0 * dg * dg + (2.0 + (255.0 - rmean) / 256.0) * db * db
        if d < best_dist:
            best_dist = d
            best = (pr, pg, pb)
    return best


def remove_background(
    img: Image.Image,
    key: tuple[int, int, int],
    tolerance: int = 15,
    fringe: int = 10,
) -> Image.Image:
    """Remove background using flood-fill from image edges.

    Only pixels reachable from the border that match the key color
    (within tolerance) are made transparent. Interior pixels of the
    same color (e.g. white eyes, white highlights) are preserved.
    """
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    kr, kg, kb = key

    def _matches(x: int, y: int) -> bool:
        r, g, b, _ = pixels[x, y]
        return max(abs(r - kr), abs(g - kg), abs(b - kb)) <= tolerance + fringe

    # BFS flood-fill starting from all border pixels that match key color
    visited: set[tuple[int, int]] = set()
    queue: list[tuple[int, int]] = []
    for x in range(w):
        for y in (0, h - 1):
            if (x, y) not in visited and _matches(x, y):
                visited.add((x, y))
                queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if (x, y) not in visited and _matches(x, y):
                visited.add((x, y))
                queue.append((x, y))

    head = 0
    while head < len(queue):
        cx, cy = queue[head]
        head += 1
        for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited and _matches(nx, ny):
                visited.add((nx, ny))
                queue.append((nx, ny))

    # Make visited (background) pixels transparent, with fringe falloff
    for x, y in visited:
        r, g, b, a = pixels[x, y]
        dist = max(abs(r - kr), abs(g - kg), abs(b - kb))
        if dist <= tolerance:
            pixels[x, y] = (0, 0, 0, 0)
        else:
            falloff = (dist - tolerance) / max(fringe, 1)
            pixels[x, y] = (r, g, b, int(a * falloff))

    return img


def snap_palette(img: Image.Image) -> Image.Image:
    """Snap all non-transparent pixels to nearest WAR MEAT palette color."""
    img = img.convert("RGBA")
    pixels = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            if a < 128:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            nr, ng, nb = nearest_palette_color(r, g, b)
            pixels[x, y] = (nr, ng, nb, 255)
    return img


def add_outline(img: Image.Image) -> Image.Image:
    """Add 1px dark outline around non-transparent pixels."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    solid = {(x, y) for y in range(h) for x in range(w) if pixels[x, y][3] > 0}
    outline = set()
    for x, y in solid:
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in solid:
                outline.add((nx, ny))
    for x, y in outline:
        pixels[x, y] = OUTLINE_COLOR
    return img


def resolve_output(input_path: Path, category: str, repo_root: Path) -> Path:
    stem = input_path.stem
    # Strip common raw suffixes like _raw, _clean, -raw
    for suffix in ("_raw", "_clean", "-raw", "-clean"):
        if stem.lower().endswith(suffix):
            stem = stem[: -len(suffix)]
    # Strip extra .png if user dropped a file named "rifle_common.png" (stem = "rifle_common.png")
    if stem.lower().endswith(".png"):
        stem = stem[:-4]

    if category == "cards":
        subfolder = detect_card_subfolder(stem)
        out_dir = repo_root / "assets" / "sprites" / "ui" / "cards" / subfolder
    elif category:
        out_dir = repo_root / "assets" / "sprites" / category
    else:
        out_dir = repo_root / "assets" / "sprites"

    out_dir.mkdir(parents=True, exist_ok=True)
    return out_dir / f"{stem}.png"


def parse_hex_color(value: str) -> tuple[int, int, int]:
    v = value.lstrip("#").strip()
    return int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16)


def parse_resize_arg(value: str) -> tuple[int, int]:
    """Accept '128' → (128,128)  or  '96x32' / '96X32' → (96,32)."""
    v = value.strip().lower()
    if "x" in v:
        parts = v.split("x", 1)
        return (int(parts[0]), int(parts[1]))
    n = int(v)
    return (n, n)


def main(argv: list[str] | None = None) -> int:
    # Find repo root (directory containing this tools/ folder)
    repo_root = Path(__file__).resolve().parent.parent

    parser = argparse.ArgumentParser(
        description="WAR MEAT sprite post-processor: BG removal + palette snap → assets/sprites/"
    )
    parser.add_argument("input", type=Path, help="Input file (JPG or PNG from AI Studio)")
    parser.add_argument(
        "--category", "-c",
        choices=["soldiers", "enemies", "weapons", "loot", "fx", "cards", ""],
        default=None,
        help="Output subfolder. Auto-detected from filename if not set.",
    )
    parser.add_argument(
        "--resize", "-r",
        type=parse_resize_arg,
        default=(0, 0),
        help="Resize output: '128' → 128×128, '96x32' → 96×32 (Nearest Neighbor)",
    )
    parser.add_argument(
        "--outline", "-o",
        action="store_true",
        help="Add 1px navy outline around sprite",
    )
    parser.add_argument(
        "--color",
        type=parse_hex_color,
        default=(255, 255, 255),
        help="Background color to remove (default: FFFFFF white — what AI Studio outputs as JPG). Use FF00FF for magenta.",
    )
    parser.add_argument(
        "--no-palette",
        action="store_true",
        help="Skip palette snapping (keep original colors)",
    )
    parser.add_argument(
        "--no-bg",
        action="store_true",
        help="Skip background removal (input already has transparency)",
    )

    args = parser.parse_args(argv)

    if not args.input.exists():
        print(f"ERROR: File not found: {args.input}")
        _pause()
        return 1

    category = args.category if args.category is not None else detect_category(args.input.stem)
    out_path = resolve_output(args.input, category, repo_root)

    # Cards: force 192×256 resize + skip palette snap automatically
    if category == "cards":
        if args.resize == (0, 0):
            args.resize = (192, 256)
        if not args.no_palette:
            args.no_palette = True
            print(f"  ℹ Cards: palette snap wyłączona automatycznie (UI asset).")

    print(f"\n{'='*50}")
    print(f"  WAR MEAT Sprite Processor")
    print(f"{'='*50}")
    print(f"  Input  : {args.input}")
    print(f"  Output : {out_path}")
    print(f"  Steps  : {'BG removal' if not args.no_bg else '(skip BG)'} → {'Palette snap' if not args.no_palette else '(skip palette)'} {'-> Resize ' + str(args.resize[0]) + 'x' + str(args.resize[1]) + 'px' if args.resize[0] else ''} {'-> Outline' if args.outline else ''}")
    print(f"{'='*50}\n")

    img = Image.open(args.input)
    print(f"  Loaded: {img.size[0]}×{img.size[1]} px, mode={img.mode}")

    # ── Size validation ──────────────────────────────────────────────────────
    expected_input, auto_target = CATEGORY_SIZES.get(category, (1024, 0))
    w, h = img.size
    if w != h:
        print(f"  ⚠ WARNING: Image is not square ({w}×{h}). Expected square input for game sprites.")
    if expected_input > 0 and (w != expected_input or h != expected_input):
        print(f"  ⚠ WARNING: Expected {expected_input}×{expected_input} px for category '{category or '?'}', got {w}×{h} px.")
        print(f"          In AI Studio: aspect ratio 1:1, resolution 1K = 1024×1024.")
    else:
        print(f"  ✓ Size OK ({w}×{h} px)")

    # Auto-resize: check per-stem sizes first, then category default
    if args.resize == (0, 0):
        stem_lower = args.input.stem.lower()
        stem_target = next((v for k, v in STEM_SIZES.items() if k in stem_lower), None)
        if stem_target:
            print(f"  ℹ Auto-resize: {w}×{h} → {stem_target[0]}×{stem_target[1]} px (asset '{args.input.stem}' default)")
            args.resize = stem_target
        elif auto_target > 0:
            print(f"  ℹ Auto-resize: {w}×{h} → {auto_target}×{auto_target} px (category '{category}' default)")
            args.resize = (auto_target, auto_target)

    # Auto-detect pixel art with existing palette → skip palette snap
    # Heuristic: if source has >40 unique colors it's pre-made pixel art, not
    # an AI-generated draft that needs WAR MEAT palette correction.
    if not args.no_palette:
        sample = img.convert("RGBA")
        unique_colors = len(set(sample.getdata()))
        if unique_colors > 40:
            args.no_palette = True
            print(f"  ℹ Auto: {unique_colors} unikalnych kolorów → wykryto gotową pixel art, pomijam paletę.")
            print(f"         (Użyj --no-palette ręcznie aby wyłączyć to ostrzeżenie)")

    # Step 1: Remove background
    if not args.no_bg:
        key_hex = "#{:02X}{:02X}{:02X}".format(*args.color)
        print(f"  [1/4] Removing background ({key_hex})...")
        img = remove_background(img, args.color)
    else:
        print(f"  [1/4] Background removal skipped.")

    # Step 1b: Cards — crop transparent padding before resize
    if category == "cards":
        rgba = img.convert("RGBA")
        bbox = rgba.getbbox()  # bounding box of non-transparent content
        if bbox:
            img = img.crop(bbox)
            print(f"  [1b] Cards: przycięto przezroczyste marginesy → {img.size[0]}×{img.size[1]} px")
        else:
            print(f"  [1b] Cards: brak zawartości po usunięciu tła — plik może być pusty!")

    # Step 2: Snap palette
    if not args.no_palette:
        print(f"  [2/4] Snapping to WAR MEAT palette...")
        img = snap_palette(img)
    else:
        print(f"  [2/4] Palette snap skipped.")

    # Step 3: Resize
    if args.resize[0] > 0:
        rw, rh = args.resize
        label = f"{rw}×{rh}" if rw != rh else f"{rw}×{rh}"
        resize_filter = Image.LANCZOS if category == "cards" else Image.NEAREST
        filter_name = "Lanczos" if category == "cards" else "Nearest Neighbor"
        print(f"  [3/4] Resizing to {label} ({filter_name})...")
        img = img.resize((rw, rh), resize_filter)
    else:
        print(f"  [3/4] Resize skipped (keeping source resolution).")

    # Step 4: Outline
    if args.outline:
        print(f"  [4/4] Adding 1px navy outline...")
        img = add_outline(img)
    else:
        print(f"  [4/4] Outline skipped.")

    # Save
    img.save(out_path, "PNG")
    final = Image.open(out_path)
    print(f"\n  ✓ Saved: {out_path}")
    print(f"    Size: {final.size[0]}×{final.size[1]} px, PNG")

    # Count transparent pixels
    arr = final.convert("RGBA")
    pixels = arr.load()
    transparent = sum(
        1 for y in range(arr.height) for x in range(arr.width)
        if pixels[x, y][3] == 0
    )
    total = arr.width * arr.height
    print(f"    Alpha: {transparent}/{total} px transparent ({transparent*100//total}%)")
    print()

    if getattr(sys, "frozen", False):
        # Running as EXE — pause so user can read output
        _pause()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
