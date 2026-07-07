#!/usr/bin/env python3
"""
check_state_model.py — Model-Based Testing for War-Meat.

Reads tests/reports/transition_log.json (chronological list of EventBus
transitions captured by qa_mode.gd) and validates the sequence against
the game's declared state machine.

Usage:
    python3 tests/check_state_model.py
    python3 tests/check_state_model.py path/to/transition_log.json
"""
from __future__ import annotations
import json
import sys
from pathlib import Path

# Declared state machine. Key = current state, value = set of legal next states.
# "*" means "from any state" (used for unconditional events like soldier_damaged
# or enemy_killed which we don't model here — they are filtered out).
VALID_TRANSITIONS: dict[str, set[str]] = {
    "START": {"mission_started"},
    "mission_started": {"wave_started"},
    "wave_started": {"wave_cleared", "squad_wiped"},
    "wave_cleared": {"upgrade_panel_requested", "mission_won"},
    "upgrade_panel_requested": {"upgrade_panel_completed"},
    "upgrade_panel_completed": {"shop_opened"},
    "shop_opened": {"shop_closed"},
    "shop_closed": {"wave_started"},
    "squad_wiped": {"mission_lost"},
    "mission_won": set(),
    "mission_lost": set(),
}

# Events excluded from the state-machine check (counted separately).
IGNORED = {"soldier_damaged", "enemy_killed", "level_up"}


def load_transitions(path: Path) -> list[dict]:
    data = json.loads(path.read_text())
    if isinstance(data, dict):
        return data.get("transitions", [])
    return data


def validate(transitions: list[dict]) -> tuple[list[str], dict]:
    errors: list[str] = []
    state = "START"
    counts: dict[str, int] = {}
    for i, t in enumerate(transitions):
        ev = t.get("event", "?")
        counts[ev] = counts.get(ev, 0) + 1
        if ev in IGNORED:
            continue
        legal = VALID_TRANSITIONS.get(state, set())
        if ev not in legal:
            errors.append(
                f"  #{i:03d} t={t.get('time', 0):.2f}s  "
                f"INVALID: {state} → {ev}  (expected one of: {sorted(legal) or '∅'})"
            )
        state = ev
    return errors, counts


def main(argv: list[str]) -> int:
    default = Path(__file__).parent.parent / "tests/reports/transition_log.json"
    path = Path(argv[1]) if len(argv) > 1 else default
    if not path.exists():
        print(f"❌ Not found: {path}")
        print("   Run with --qa-mode first to generate a transition log.")
        return 2
    transitions = load_transitions(path)
    if not transitions:
        print(f"⚠️  Empty transition log: {path}")
        return 1
    errors, counts = validate(transitions)
    print(f"📋 State-model check — {path}")
    print(f"   transitions: {len(transitions)}  unique events: {len(counts)}")
    for ev, n in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"     {ev:32s} ×{n}")
    if errors:
        print(f"\n❌ {len(errors)} invalid transitions:")
        for e in errors:
            print(e)
        return 1
    print("\n✅ All transitions valid against declared state machine.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
