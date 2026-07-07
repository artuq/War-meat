#!/usr/bin/env python3
"""
Produkuje TIMELINE analizę ze wszystkich state JSON-ów w tests/screenshots/.
Wywołuje to Claude przed czytaniem konkretnych PNG-ów.

Użycie:
    python3 tests/analyze_timeline.py
"""

import json
from pathlib import Path
from typing import Any


SCREENSHOTS_DIR = Path(__file__).parent / "screenshots"

# Genre expectations (Brotato/Survivor.io baseline)
EXPECTED_KILL_RATE_WAVE_1 = 1.0   # killi/s minimum
EXPECTED_GOLD_PER_KILL = 8        # min gold za kill
SEPARATION_RULE = 18.0            # >= 18px między wrogami
OVERLAP_RULE_FRAMES = 3           # max kolejnych klatek z przyklejaniem


def load_timeline() -> list[dict]:
    """Wczytaj wszystkie state JSON-y w kolejności."""
    files = sorted(SCREENSHOTS_DIR.glob("*.json"))
    timeline = []
    for f in files:
        with open(f) as fp:
            d = json.load(fp)
        timeline.append({
            "file": f.stem,
            "png": f.with_suffix(".png").name,
            "elapsed": d.get("elapsed", 0),
            "wave": d.get("game", {}).get("current_wave", 0),
            "gold": d.get("game", {}).get("gold", 0),
            "kills": d.get("game", {}).get("enemies_killed", 0),
            "level": d.get("game", {}).get("level", 1),
            "streak_dmg": d.get("game", {}).get("streak_damage_bonus", 0),
            "enemy_count": d.get("metrics", {}).get("enemy_count", 0),
            "min_sep": d.get("metrics", {}).get("min_enemy_separation", -1),
            "overlap": d.get("metrics", {}).get("enemies_overlap_soldier", 0),
            "knockback": d.get("metrics", {}).get("enemies_with_knockback", 0),
            "projectiles": d.get("metrics", {}).get("projectile_count", 0),
            "shop_visible": d.get("ui", {}).get("shop_visible", False),
        })
    return timeline


def print_timeline(timeline: list[dict]) -> None:
    print(f"\n{'='*100}")
    print(f"TIMELINE: {len(timeline)} klatek, "
          f"{timeline[-1]['elapsed']:.1f}s total" if timeline else "PUSTY")
    print(f"{'='*100}\n")
    cols = ["time", "wave", "gold", "kills", "lvl", "enemy", "sep", "ovr", "kb", "bul"]
    print(" ".join(f"{c:>5}" for c in cols), "| file")
    print("-" * 100)
    for t in timeline:
        sep_str = f"{t['min_sep']:>5.1f}" if t['min_sep'] >= 0 else "  —  "
        sep_marker = " ⚠" if 0 < t['min_sep'] < SEPARATION_RULE else ""
        print(
            f"{t['elapsed']:>5.1f} {t['wave']:>5} {t['gold']:>5} {t['kills']:>5} "
            f"{t['level']:>5} {t['enemy_count']:>5} {sep_str} {t['overlap']:>5} "
            f"{t['knockback']:>5} {t['projectiles']:>5}{sep_marker} | {t['file']}"
        )


def detect_bugs(timeline: list[dict]) -> dict:
    bugs = {"critical": [], "warning": [], "info": [], "ok": []}
    if not timeline:
        return bugs

    last = timeline[-1]
    total_time = last["elapsed"]

    # ── BUG: Gold nie kapie mimo killów ──────────────────
    if last["kills"] > 0 and last["gold"] == 0:
        bugs["critical"].append(
            f"🔴 Gold = $0 mimo {last['kills']} killów po {total_time:.1f}s. "
            f"Loot drop emituje się ale gold nigdy nie wzrósł. "
            f"Sprawdź: LootDrop._on_body_entered, EventBus.loot_collected → GameManager.gold."
        )

    # ── BUG: Separation degraduje pod presją ──────────
    violations = [t for t in timeline if 0 < t["min_sep"] < SEPARATION_RULE]
    if violations:
        worst = min(violations, key=lambda t: t["min_sep"])
        bugs["critical"].append(
            f"🔴 Separation < {SEPARATION_RULE}px w {len(violations)}/{len(timeline)} klatkach. "
            f"Najgorzej: {worst['min_sep']:.1f}px @ {worst['elapsed']:.1f}s "
            f"(file: {worst['file']}, {worst['enemy_count']} wrogów). "
            f"Reguła SEPARATION_STRENGTH=120 nie skaluje się z hordą. "
            f"Fix: enemy.gd:272 — zwiększyć siłę lub radius."
        )

    # ── BUG: Spawn rate vs kill rate ────────────────────
    if total_time > 0:
        kill_rate = last["kills"] / total_time
        enemy_growth = last["enemy_count"] - timeline[0]["enemy_count"]
        spawn_rate_min = enemy_growth / total_time + kill_rate
        if kill_rate < EXPECTED_KILL_RATE_WAVE_1 and last["wave"] == 1:
            bugs["critical"].append(
                f"🔴 Kill rate = {kill_rate:.2f}/s (oczekiwane {EXPECTED_KILL_RATE_WAVE_1}+/s na wave 1). "
                f"Spawn rate ~{spawn_rate_min:.1f}/s — gracz NIE WYRÓWNA. "
                f"Fix: zwiększ DMG soldier lub zmniejsz min_spawn_interval w wave_default.tres."
            )

    # ── BUG: Stuck on player ─────────────────────────────
    overlap_frames = [t for t in timeline if t["overlap"] > 0]
    if len(overlap_frames) >= OVERLAP_RULE_FRAMES:
        # Sprawdź czy consecutive
        consecutive_max = 0
        consecutive = 0
        prev_idx = -2
        for i, t in enumerate(timeline):
            if t["overlap"] > 0:
                if i == prev_idx + 1:
                    consecutive += 1
                    consecutive_max = max(consecutive_max, consecutive)
                else:
                    consecutive = 1
                prev_idx = i
        if consecutive_max >= OVERLAP_RULE_FRAMES:
            bugs["warning"].append(
                f"🟡 Wrogowie przyklejeni do soldiera w {consecutive_max} kolejnych klatkach. "
                f"Knockback od pocisku może być za słaby. "
                f"Fix: projectile.gd:38 — zwiększ knockback force (obecnie 90.0)."
            )

    # ── INFO: Brak strzałów ──────────────────────────────
    ever_shot = any(t["projectiles"] > 0 for t in timeline)
    if not ever_shot:
        bugs["critical"].append(
            f"🔴 ZERO pocisków w całym runie. Soldier nie strzela. "
            f"Sprawdź: AttackTimer, _shoot_at, weapon.attack_range."
        )

    # ── OK: rzeczy które działają ────────────────────────
    if ever_shot:
        max_p = max(t["projectiles"] for t in timeline)
        bugs["ok"].append(f"✓ Soldier strzela (max {max_p} pocisków na klatce)")
    if any(t["knockback"] > 0 for t in timeline):
        bugs["ok"].append("✓ Knockback działa (wykryty w sekwencji)")
    if last["wave"] > timeline[0]["wave"]:
        bugs["ok"].append(f"✓ Wave progresja działa (z {timeline[0]['wave']} → {last['wave']})")
    if last["kills"] > 0:
        bugs["ok"].append(f"✓ Kill counter rośnie (total {last['kills']})")

    return bugs


def print_report(timeline: list[dict], bugs: dict) -> None:
    print(f"\n{'='*100}")
    print("RAPORT QA — wnioski z sekwencji")
    print(f"{'='*100}\n")

    if bugs["critical"]:
        print(f"🔴 KRYTYCZNE ({len(bugs['critical'])}):\n")
        for b in bugs["critical"]:
            print(f"  • {b}\n")

    if bugs["warning"]:
        print(f"🟡 OSTRZEŻENIA ({len(bugs['warning'])}):\n")
        for b in bugs["warning"]:
            print(f"  • {b}\n")

    if bugs["info"]:
        print(f"ℹ️  INFO ({len(bugs['info'])}):\n")
        for b in bugs["info"]:
            print(f"  • {b}\n")

    if bugs["ok"]:
        print(f"🟢 DZIAŁA POPRAWNIE ({len(bugs['ok'])}):\n")
        for b in bugs["ok"]:
            print(f"  {b}")

    print(f"\n{'='*100}")
    print("Następny krok dla Claude'a:")
    print("Przeczytaj 2-3 kluczowe PNG-y z momentów anomalii (timeline pokazuje czas)")
    print("Visual confirmation + zaproponuj konkretne fixy.")
    print(f"{'='*100}\n")


def main():
    timeline = load_timeline()
    if not timeline:
        print(f"❌ Brak state JSON-ów w {SCREENSHOTS_DIR}")
        print("   Uruchom najpierw: bash run_visual_qa.sh 30")
        return 1
    print_timeline(timeline)
    bugs = detect_bugs(timeline)
    print_report(timeline, bugs)
    return 0


if __name__ == "__main__":
    exit(main())
