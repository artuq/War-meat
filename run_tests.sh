#!/bin/bash
# War-Meat Test Runner
# Użycie: bash run_tests.sh [opcja]
#   (brak)     — wszystkie testy unit
#   --health   — tylko HealthComponent
#   --waves    — tylko WaveData
#   --upgrades — tylko UpgradeSystem
#   --sanity   — szybki smoke test (8 testów, ~1s)

GODOT="/Users/magda/Downloads/Godot.app/Contents/MacOS/Godot"
RUNNER="addons/gdUnit4/runtest.sh"

case "${1}" in
  --health)   SUITES="--add res://tests/unit/test_health_component.gd" ;;
  --waves)    SUITES="--add res://tests/unit/test_wave_data.gd" ;;
  --upgrades) SUITES="--add res://tests/unit/test_upgrade_system.gd" ;;
  --sanity)   SUITES="--add res://tests/unit/test_sanity.gd" ;;
  *)
    SUITES="--add res://tests/unit/"
    ;;
esac

bash "$RUNNER" \
  --godot_binary "$GODOT" \
  $SUITES \
  --report-directory tests/reports \
  2>&1 | grep -v "Case mismatch\|open_internal\|at: open" \
       | grep -v "^$" \
       | grep -E "PASSED|FAILED|Statistics|Total execution|Run tests ends|ERROR" \
       | sed 's/\x1b\[[0-9;]*m//g'
