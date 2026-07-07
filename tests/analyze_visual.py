#!/usr/bin/env python3
"""
Visual QA Analyzer — ROI cropping + color sampling + (opcjonalne) OCR.
Bez reference baseline. Sprawdza CO MUSI być w jakim stanie gry.

Użycie:
    python3 tests/analyze_visual.py                # wszystkie screenshoty
    python3 tests/analyze_visual.py 020*           # konkretny plik
"""

import json
import sys
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageStat
    HAS_PIL = True
except ImportError:
    print("❌ Pillow nie zainstalowane. pip install Pillow")
    sys.exit(1)

# Optional OCR
try:
    import pytesseract
    HAS_OCR = True
except ImportError:
    HAS_OCR = False

SCREENSHOTS_DIR = Path(__file__).parent / "screenshots"

# ──────────────────────────────────────────────────────────────
# ROI definitions — dla 640x360 viewport (Godot default na mobile)
# Jeśli rozdzielczość inna, przeskaluje się proporcjonalnie.
# ──────────────────────────────────────────────────────────────

BASE_W, BASE_H = 640, 360

REGIONS_BASE = {
    "hud_topleft":     (0,   0,   220, 80),    # HP bar + LV + Gold
    "hud_topright":    (440, 0,   640, 100),   # WAVE + timer + pause
    "action_center":   (60,  100, 580, 460),   # gameplay area
    "joystick_zone":   (0,   200, 220, 360),   # bottom-left (touch)
    "footer":          (0,   300, 640, 360),   # bottom row (kill streak, banner)
    "kill_streak":     (200, 50,  440, 130),   # gdzie pojawia się "ON FIRE!"
    "full_screen":     (0,   0,   640, 360),   # cały viewport — do edge-clipping detection
    "upgrade_strip":   (0,   100, 640, 360),   # pasek gdzie pojawiają się upgrade cards
}


# ──────────────────────────────────────────────────────────────
# Expected UI elements per game state
# ──────────────────────────────────────────────────────────────

def expected_for_state(state: dict) -> list[dict]:
    """Zwraca listę reguł co MUSI być widoczne w tym stanie."""
    rules = []
    game = state.get("game", {})
    ui = state.get("ui", {})
    label = state.get("label", "")

    # Reguły dla gameplay (heartbeat, kill, soldier_hit, wave_start)
    in_gameplay = (
        game.get("is_mission_active", False)
        and not ui.get("shop_visible", False)
        and not ui.get("upgrade_panel_visible", False)
    )
    if in_gameplay and game.get("current_wave", 0) > 0:
        rules.append({"region": "hud_topleft", "check": "hp_bar_red",
                      "desc": "HP bar widoczny, czerwony"})
        rules.append({"region": "hud_topright", "check": "wave_indicator",
                      "desc": "WAVE N widoczne"})
        rules.append({"region": "action_center", "check": "not_empty",
                      "desc": "Action area ma zawartość (soldier/enemies)"})

    # Reguły dla streak active
    if game.get("streak_damage_bonus", 0) > 0 or game.get("streak_speed_bonus", 0) > 0:
        rules.append({"region": "kill_streak", "check": "has_bright_text",
                      "desc": "Kill streak text widoczny (jasne piksele na czarnym outline)"})

    # Shop opened
    if ui.get("shop_visible", False):
        # Dimmer check: middle of action area should be dark
        rules.append({"region": "action_center", "check": "darker_than_gameplay",
                      "desc": "Shop dimmer aktywny"})
        # Stats panel state check wymaga OCR — bez OCR pomijamy
        # (📊 ikona daje false positive bez OCR)

    # Upgrade panel — detekcja overflow kart (REGRESJA znaleziona ręcznie)
    if ui.get("upgrade_panel_visible", False) or "upgrade_panel" in label:
        rules.append({"region": "upgrade_strip", "check": "no_edge_clipping",
                      "desc": "Karty upgrade nie wychodzą poza widoczny obszar"})

    return rules


# ──────────────────────────────────────────────────────────────
# Region helpers
# ──────────────────────────────────────────────────────────────

def scale_region(region: tuple, img_w: int, img_h: int) -> tuple:
    """Przeskaluj region z BASE do rzeczywistych wymiarów obrazu."""
    sx, sy = img_w / BASE_W, img_h / BASE_H
    return (
        int(region[0] * sx),
        int(region[1] * sy),
        int(region[2] * sx),
        int(region[3] * sy),
    )


def crop_region(img: Image.Image, region_name: str) -> Image.Image:
    base = REGIONS_BASE[region_name]
    scaled = scale_region(base, img.width, img.height)
    return img.crop(scaled)


# ──────────────────────────────────────────────────────────────
# Visual checks
# ──────────────────────────────────────────────────────────────

def check_hp_bar_red(region: Image.Image) -> dict:
    """HP bar w lewej-górze powinien mieć czerwone piksele."""
    # Sample top-left strip gdzie zwykle jest HP bar
    sample = region.crop((10, 5, 200, 20))
    pixels = list(sample.getdata())
    if not pixels:
        return {"pass": False, "reason": "Region pusty"}
    # Szukaj jasnoczerwonych pikseli (R > 200, G < 100)
    red_count = sum(1 for p in pixels if p[0] > 180 and p[1] < 100 and p[2] < 100)
    ratio = red_count / len(pixels)
    return {
        "pass": ratio > 0.05,  # co najmniej 5% pikseli wyraźnie czerwone
        "metric": f"red_pixel_ratio={ratio:.1%}",
        "reason": "HP bar niewidoczny lub niewłaściwy kolor" if ratio <= 0.05 else "OK"
    }


def check_wave_indicator(region: Image.Image) -> dict:
    """W prawej-górze powinien być tekst z 'WAVE' lub timer — białe piksele."""
    pixels = list(region.getdata())
    if not pixels:
        return {"pass": False, "reason": "Region pusty"}
    # Bardzo białe piksele (font white) — tekst zajmuje ~1-2% region
    bright_count = sum(1 for p in pixels if min(p[:3]) > 220)
    ratio = bright_count / len(pixels)
    return {
        "pass": ratio > 0.003,  # min 0.3% — tekst jest mały vs region
        "metric": f"bright_pixel_ratio={ratio:.2%}",
        "reason": "Brak białego tekstu (WAVE indicator)" if ratio <= 0.003 else "OK"
    }


def check_not_empty(region: Image.Image) -> dict:
    """Action center nie powinno być jednorodne (= martwy gameplay)."""
    stat = ImageStat.Stat(region)
    stddev_avg = sum(stat.stddev[:3]) / 3
    return {
        "pass": stddev_avg > 15,  # heuristic: > 15 std dev = jest coś
        "metric": f"color_stddev={stddev_avg:.1f}",
        "reason": "Action area pusta lub jednorodna" if stddev_avg <= 15 else "OK"
    }


def check_has_bright_text(region: Image.Image) -> dict:
    """Kill streak — jasne piksele (czerwono-żółte) z outline."""
    pixels = list(region.getdata())
    if not pixels:
        return {"pass": False, "reason": "Region pusty"}
    bright = sum(1 for p in pixels if p[0] > 180 and p[1] > 100)
    ratio = bright / len(pixels)
    return {
        "pass": ratio > 0.005,  # tekst zajmuje mało, 0.5% wystarczy
        "metric": f"warm_bright={ratio:.2%}",
        "reason": "Kill streak text niewidoczny" if ratio <= 0.005 else "OK"
    }


def check_darker_than_gameplay(region: Image.Image) -> dict:
    """Shop ma dimmer — region powinien być znacznie ciemniejszy niż normal gameplay."""
    stat = ImageStat.Stat(region)
    brightness = sum(stat.mean[:3]) / 3
    return {
        "pass": brightness < 60,  # heuristic: < 60 = dimmed background
        "metric": f"brightness={brightness:.1f}",
        "reason": "Shop dimmer może nie działać" if brightness >= 60 else "OK"
    }


def check_no_stats_panel(region: Image.Image) -> dict:
    """Stats panel zamknięty — pierwsze 30px od lewej powinny być puste/dim shop dimmer."""
    # Szukamy STATS COLUMN która (gdy otwarta) ma jasny tekst statystyk
    # w pierwszych 30px od lewej. Sklep ma kart NA PRAWO od pozycji 80px.
    sample = region.crop((0, 0, 30, region.height))
    pixels = list(sample.getdata())
    if not pixels:
        return {"pass": True, "reason": "OK"}
    # Czy są jakieś WYRAŹNIE jasne piksele (text statystyk)?
    very_bright = sum(1 for p in pixels if min(p[:3]) > 180)
    ratio = very_bright / len(pixels)
    return {
        "pass": ratio < 0.03,  # < 3% w wąskim pasku 30px
        "metric": f"text_in_leftmost_30px={ratio:.1%}",
        "reason": "Stats panel otwarty mimo że powinien być zamknięty" if ratio >= 0.03 else "OK"
    }


def check_no_edge_clipping(region: Image.Image) -> dict:
    """
    Wykrywa UI obcięte na krawędzi EKRANU przez stddev koloru.
    Czyste tło = niska stddev (~13). Ucięta karta (tekst, border, content) = wysoka (~29).
    Threshold 22.
    """
    w, h = region.size
    left = region.crop((0, h // 5, 8, h * 4 // 5))
    right = region.crop((w - 8, h // 5, w, h * 4 // 5))

    def edge_stddev(strip: Image.Image) -> float:
        return sum(ImageStat.Stat(strip).stddev[:3]) / 3

    left_sd = edge_stddev(left)
    right_sd = edge_stddev(right)
    # Jeśli OBA brzegi mają stddev > 22 → coś jest ucinane (content na brzegach)
    severe = left_sd > 22.0 and right_sd > 22.0
    return {
        "pass": not severe,
        "metric": f"left_sd={left_sd:.0f}, right_sd={right_sd:.0f}",
        "reason": "Content obcięty na obu krawędziach (UI overflow)" if severe else "OK"
    }


CHECK_FUNCTIONS = {
    "hp_bar_red": check_hp_bar_red,
    "wave_indicator": check_wave_indicator,
    "not_empty": check_not_empty,
    "has_bright_text": check_has_bright_text,
    "darker_than_gameplay": check_darker_than_gameplay,
    "no_stats_panel": check_no_stats_panel,
    "no_edge_clipping": check_no_edge_clipping,
}


# ──────────────────────────────────────────────────────────────
# Sprite fringing detection
# ──────────────────────────────────────────────────────────────

def check_sprite_fringing(img: Image.Image, state: dict) -> dict:
    """Sample pikseli wokół soldier pos — szukaj jasnego halo na ciemnym tle."""
    soldiers = state.get("soldiers", [])
    if not soldiers:
        return None
    s = soldiers[0]
    sx, sy = s.get("pos", [0, 0])
    # Soldier może być daleko od (0,0) — sprawdzamy ekran w centrum
    # bo kamera nim śledzi
    center_x, center_y = img.width // 2, img.height // 2
    # Sample 30x30 box wokół centrum
    box_size = 30
    sample = img.crop((center_x - box_size, center_y - box_size,
                       center_x + box_size, center_y + box_size))
    pixels = list(sample.getdata())
    # Szukaj jasnoszarych/białych pikseli OUTSIDE the sprite (ramka)
    # to byłoby halo. Sprite postaci ma color, halo byłoby białe (>220).
    edge_pixels = []
    w, h = sample.size
    for x in range(w):
        for y in range(h):
            if x < 3 or x > w-4 or y < 3 or y > h-4:  # tylko brzeg samplowanej ramki
                edge_pixels.append(sample.getpixel((x, y)))
    if not edge_pixels:
        return None
    # Halo = white-ish (>220 all channels) na lekko-ciemnym tle
    halo_count = sum(1 for p in edge_pixels if min(p[:3]) > 200 and max(p[:3]) - min(p[:3]) < 30)
    ratio = halo_count / len(edge_pixels)
    return {
        "check": "sprite_fringing",
        "pass": ratio < 0.10,  # < 10% jasnych edge = OK
        "metric": f"halo_ratio={ratio:.1%}",
        "reason": "Możliwe halo wokół sprite'a (fringing)" if ratio >= 0.10 else "OK"
    }


# ──────────────────────────────────────────────────────────────
# OCR (optional)
# ──────────────────────────────────────────────────────────────

def ocr_region(region: Image.Image) -> str:
    if not HAS_OCR:
        return ""
    try:
        # Preprocess: scale up, increase contrast
        bigger = region.resize((region.width * 3, region.height * 3))
        return pytesseract.image_to_string(bigger, config='--psm 6').strip()
    except Exception:
        return ""


# ──────────────────────────────────────────────────────────────
# Main analysis
# ──────────────────────────────────────────────────────────────

def analyze_screenshot(png_path: Path) -> dict:
    json_path = png_path.with_suffix(".json")
    if not json_path.exists():
        return {"error": f"Brak state JSON dla {png_path.name}"}

    with open(json_path) as f:
        state = json.load(f)

    img = Image.open(png_path).convert("RGB")
    rules = expected_for_state(state)
    findings = {"file": png_path.name, "passes": [], "fails": [], "info": []}

    # Run each rule
    for rule in rules:
        region = crop_region(img, rule["region"])
        check_fn = CHECK_FUNCTIONS.get(rule["check"])
        if not check_fn:
            continue
        result = check_fn(region)
        entry = {**rule, **result}
        if result.get("pass"):
            findings["passes"].append(entry)
        else:
            findings["fails"].append(entry)

    # Fringing check (universal, dla każdego stanu z soldierem)
    fr = check_sprite_fringing(img, state)
    if fr:
        target = findings["passes"] if fr["pass"] else findings["fails"]
        target.append(fr)

    # OCR info (jeśli dostępne)
    if HAS_OCR:
        for region_name in ["hud_topleft", "hud_topright", "footer"]:
            text = ocr_region(crop_region(img, region_name))
            if text:
                findings["info"].append({"region": region_name, "ocr": text})

    return findings


def print_findings(findings: list[dict]) -> None:
    print(f"\n{'='*80}")
    print(f"  Visual QA Report — {len(findings)} screenshotów")
    if HAS_OCR:
        print("  OCR: ✓ włączone")
    else:
        print("  OCR: ⚠ wyłączone (pip install pytesseract && brew install tesseract)")
    print(f"{'='*80}\n")

    total_fails = 0
    for f in findings:
        if "error" in f:
            print(f"  ❌ {f['file']}: {f['error']}")
            continue
        fails = f.get("fails", [])
        passes = f.get("passes", [])
        if fails:
            total_fails += len(fails)
            print(f"  🔴 {f['file']}")
            for fail in fails:
                desc = fail.get("desc", fail.get("check", "?"))
                metric = fail.get("metric", "")
                print(f"      └─ {desc} [{metric}]")
        else:
            print(f"  ✅ {f['file']:<35} {len(passes)} reguł OK")

    print(f"\n{'='*80}")
    print(f"  TOTAL: {total_fails} naruszeń visual rules w {len(findings)} screenshotach")
    print(f"{'='*80}\n")


def main():
    pattern = sys.argv[1] if len(sys.argv) > 1 else "*.png"
    screenshots = sorted(SCREENSHOTS_DIR.glob(pattern))
    if not screenshots:
        print(f"❌ Brak screenshotów w {SCREENSHOTS_DIR}")
        return 1
    findings = [analyze_screenshot(p) for p in screenshots]
    print_findings(findings)
    return 0


if __name__ == "__main__":
    exit(main())
