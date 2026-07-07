#!/bin/bash
# WRZUC_SPRITE_MAC.command — kliknij dwukrotnie w Finderze

cd "$(dirname "$0")"

echo "╔══════════════════════════════════════════╗"
echo "║   WAR MEAT — WRZUC SPRITE  (macOS)       ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Sprawdź Python3
if ! command -v python3 &>/dev/null; then
    echo "❌  Python3 nie znaleziony."
    echo "    Zainstaluj z: https://www.python.org/downloads/"
    read -rp "Naciśnij Enter aby zamknąć..."; exit 1
fi
echo "✓  $(python3 --version)"

# Pillow
if ! python3 -c "import PIL" &>/dev/null; then
    echo "Instaluję Pillow..."
    pip3 install --quiet Pillow && echo "✓  Pillow OK" || {
        echo "❌  Błąd instalacji Pillow."; read -rp "Enter..."; exit 1; }
else
    echo "✓  Pillow OK"
fi

echo ""
echo "Wybierz tryb:"
echo "  1) Web UI  — przeglądarka (zalecane, działa zawsze)"
echo "  2) Terminal — file picker + prompty w terminalu"
echo ""
read -rp "Wybór [1]: " MODE
MODE="${MODE:-1}"

echo ""
if [ "$MODE" = "2" ]; then
    echo "Uruchamiam tryb terminalowy..."
    echo "════════════════════════════════════════════"
    python3 wrzuc_interactive.py
else
    echo "Uruchamiam web UI na http://localhost:8765 ..."
    echo "Przeglądarka otworzy się automatycznie."
    echo "Ctrl+C w tym terminalu aby zatrzymać serwer."
    echo "════════════════════════════════════════════"
    python3 wrzuc_web.py
fi
