#!/bin/bash
# War-Meat — Tryb interaktywny z QA capture
# TY GRASZ, QA Mode łapie screenshoty na każdy event (wave_started, shop_opened, level_up...)
# Zamknij grę normalnie kiedy skończysz. Screenshoty będą w tests/screenshots/

GODOT="/Users/magda/Downloads/Godot.app/Contents/MacOS/Godot"

echo "============================================"
echo "  War-Meat — Interactive QA Mode"
echo "============================================"
echo "  Ty grasz, QA łapie screenshoty na eventy:"
echo "    • wave_started / wave_cleared"
echo "    • shop_opened / shop_closed"
echo "    • upgrade_panel / level_up"
echo "    • mission_won / squad_wiped"
echo "  + heartbeat co 5 sekund"
echo ""
echo "  Zamknij grę normalnie kiedy chcesz."
echo "============================================"
echo ""

mkdir -p tests/screenshots tests/reports
rm -f tests/screenshots/*.png

"$GODOT" --path . -- --qa-mode --qa-interactive 2>&1 | grep -E "QA Mode|ERROR" | sed 's/\x1b\[[0-9;]*m//g'

echo ""
echo "============================================"
echo "  Sesja zakończona. Screenshoty:"
ls tests/screenshots/ | wc -l | xargs echo "  Łącznie:"
echo "============================================"
