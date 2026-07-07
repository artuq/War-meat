#!/bin/bash
# War-Meat Visual QA — automatyczny pilot gry + screenshoty
# Użycie: bash run_visual_qa.sh [duration_in_seconds]
#   bash run_visual_qa.sh          # 60s domyślnie
#   bash run_visual_qa.sh 120      # 2 minuty

GODOT="/Users/magda/Downloads/Godot.app/Contents/MacOS/Godot"
DURATION="${1:-60}"

echo "============================================"
echo "  War-Meat Visual QA Runner"
echo "============================================"
echo "  Duration: ${DURATION}s"
echo "  Screenshots → tests/screenshots/"
echo "  Report      → tests/reports/qa_mode_report.json"
echo "============================================"
echo ""

# Wyczyść stare screenshoty (qa_mode.gd też to robi, podwójny safety)
mkdir -p tests/screenshots tests/reports
rm -f tests/screenshots/*.png

# Uruchom Godot z flagą --qa-mode
# UWAGA: nie używamy --headless bo główny viewport nie renderuje screenshotów
"$GODOT" \
  --path . \
  -- --qa-mode --qa-duration=${DURATION} \
  2>&1 | grep -E "QA Mode|ERROR|ENABLE" | sed 's/\x1b\[[0-9;]*m//g'

echo ""
echo "============================================"
echo "  Wyniki:"
ls tests/screenshots/ 2>/dev/null | wc -l | xargs echo "  Screenshoty:"
if [ -f tests/reports/qa_mode_report.json ]; then
  echo "  Raport:"
  cat tests/reports/qa_mode_report.json
fi
echo "============================================"
