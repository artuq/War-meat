#!/usr/bin/env bash
# run_record.sh — interactive recording session for replay testing.
# Usage: ./run_record.sh [seed]
#   seed: optional integer RNG seed (default: auto from clock)
set -euo pipefail
cd "$(dirname "$0")"

SEED="${1:-0}"
GODOT="${GODOT_BIN:-/Users/magda/Downloads/Godot.app/Contents/MacOS/Godot}"
ARGS=(--path . -- --qa-mode --qa-record)
if [[ "$SEED" != "0" ]]; then
  ARGS+=(--qa-seed="$SEED")
fi

echo "🎬 Recording session — play normally, then close the window to save."
echo "   seed = $SEED (0 = auto)"
echo "   output → tests/recordings/<timestamp>.json"
"$GODOT" "${ARGS[@]}"
