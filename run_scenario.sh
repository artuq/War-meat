#!/bin/bash
# War-Meat QA — Scripted Scenarios
# Użycie: bash run_scenario.sh <scenario>
#   shop_hover    — sprawdza czy hover karty otwiera stats panel
#   shop_unhover  — REGRESJA: czy unhover ZAMYKA stats panel
#   wave_burst    — burst screenshoty z wave 2 (różne typy wrogów)
#   stress_horde  — 20 wrogów blisko siebie, sprawdź separation

GODOT="/Users/magda/Downloads/Godot.app/Contents/MacOS/Godot"
SCENARIO="${1:-shop_unhover}"

echo "============================================"
echo "  QA Scenario: $SCENARIO"
echo "============================================"

mkdir -p tests/screenshots tests/reports
rm -f tests/screenshots/scenario_*.png tests/screenshots/scenario_*.json

"$GODOT" --path . -- --qa-mode --qa-scenario=$SCENARIO 2>&1 \
  | grep -E "QA Scenarios|QA Mode|🐛|BUG|✓ OK|FAIL|ERROR" \
  | sed 's/\x1b\[[0-9;]*m//g'

echo ""
echo "Screenshoty scenariusza:"
ls tests/screenshots/scenario_*.png 2>/dev/null | wc -l | xargs echo "  count:"
