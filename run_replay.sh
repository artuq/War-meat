#!/usr/bin/env bash
# run_replay.sh — deterministically replay a recorded session.
# Usage: ./run_replay.sh <path-to-recording.json>
set -euo pipefail
cd "$(dirname "$0")"

REPLAY="${1:-}"
if [[ -z "$REPLAY" ]]; then
  echo "Usage: $0 <path-to-recording.json>" >&2
  echo "Available recordings:" >&2
  ls -1 tests/recordings/*.json 2>/dev/null || echo "  (none)" >&2
  exit 2
fi
if [[ ! -f "$REPLAY" ]]; then
  echo "❌ Recording not found: $REPLAY" >&2
  exit 2
fi

GODOT="${GODOT_BIN:-/Users/magda/Downloads/Godot.app/Contents/MacOS/Godot}"
echo "▶️  Replaying: $REPLAY"
"$GODOT" --path . -- --qa-mode --qa-replay="$REPLAY"

echo ""
echo "🔎 Validating recorded state machine…"
python3 tests/check_state_model.py
