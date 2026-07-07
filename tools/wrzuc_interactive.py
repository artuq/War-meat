#!/usr/bin/env python3
"""
WRZUC SPRITE — Interactive terminal mode (macOS)
Otwiera natywny file picker → opcje w terminalu → przetwarza → log w terminalu.
"""
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    import process_sprite as ps
except ImportError as e:
    print(f"BLAD: Nie mozna zaladowac process_sprite: {e}")
    sys.exit(1)


def pick_files() -> list[Path]:
    """Natywny file picker bez okna głównego (działa na każdym macOS Python)."""
    import tkinter as tk
    from tkinter import filedialog
    root = tk.Tk()
    root.withdraw()
    root.attributes("-topmost", True)
    paths = filedialog.askopenfilenames(
        title="Wybierz sprite'y do przetworzenia",
        filetypes=[("Obrazy", "*.jpg *.jpeg *.png"), ("Wszystkie", "*.*")],
    )
    root.destroy()
    return [Path(p) for p in paths]


def ask(prompt: str, default: str = "") -> str:
    hint = f" [{default}]" if default else ""
    try:
        val = input(f"{prompt}{hint}: ").strip()
    except (EOFError, KeyboardInterrupt):
        print()
        return default
    return val or default


def main() -> None:
    print()
    print("=" * 54)
    print("  WAR MEAT — WRZUC SPRITE  (macOS terminal mode)")
    print("=" * 54)

    # ── Wybór plików ──────────────────────────────────────────
    print("\nOtwieranie file picker...")
    files = pick_files()
    if not files:
        print("Anulowano — nie wybrano plików.")
        return

    print(f"\nWybrano {len(files)} plik(ow):")
    for f in files:
        print(f"  {f.name}")

    # ── Opcje ─────────────────────────────────────────────────
    print()
    print("--- Opcje (Enter = domyslne) ---")
    print("Kategoria:  auto / soldiers / enemies / weapons / loot / fx")
    cat_raw  = ask("Kategoria", "auto")
    category = "" if cat_raw == "auto" else cat_raw

    print("Resize:     auto / 128 / 128x64 / 96x32 itp.")
    resize   = ask("Resize", "auto")

    no_pal   = ask("Pomin palete?       (t/N)", "N").lower() in ("t", "tak", "y")
    no_bg    = ask("Pomin usuwanie tla? (t/N)", "N").lower() in ("t", "tak", "y")
    outline  = ask("Dodaj outline?      (t/N)", "N").lower() in ("t", "tak", "y")

    # ── Przetwarzanie ─────────────────────────────────────────
    print()
    print("=" * 54)
    ok = fail = 0

    for fp in files:
        print(f"\n>>> {fp.name}")
        argv: list[str] = [str(fp)]
        if category:
            argv += ["--category", category]
        if resize.lower() != "auto":
            argv += ["--resize", resize]
        if no_pal:
            argv.append("--no-palette")
        if no_bg:
            argv.append("--no-bg")
        if outline:
            argv.append("--outline")

        try:
            code = ps.main(argv)
            if code == 0:
                ok += 1
            else:
                fail += 1
                print(f"  BLAD: exit code {code}")
        except Exception as exc:
            fail += 1
            print(f"  WYJATEK: {exc}")

    # ── Podsumowanie ──────────────────────────────────────────
    print()
    print("=" * 54)
    print(f"  Gotowe:  {ok} OK  |  {fail} bledow")
    print("=" * 54)

    # Opcja: przetworz kolejne pliki
    print()
    again = ask("Przetworzyc kolejne pliki? (t/N)", "N").lower()
    if again in ("t", "tak", "y"):
        main()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nPrzerwano.")
    finally:
        print()
        input("Nacisnij Enter aby zamknac terminal...")
