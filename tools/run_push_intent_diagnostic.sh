#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
STAMP="${1:-$(date +%F-%H%M%S)}"
BASE_PATH="$ROOT_DIR/production/qa/playtests/push-intent-diagnostic-${STAMP}"

mkdir -p "$ROOT_DIR/production/qa/playtests" "$ROOT_DIR/.tmp"

"$GODOT_BIN" \
  --headless \
  --path "$PROJECT_DIR" \
  --log-file "$ROOT_DIR/.tmp/push-intent-diagnostic.log" \
  --script tests/run_push_intent_diagnostic.gd \
  -- \
  --base-path="$BASE_PATH"

printf '\nPush intent diagnostic report:\n  %s.md\n' "$BASE_PATH"
printf 'Snapshots:\n'
printf '  %s-approach.png\n' "$BASE_PATH"
printf '  %s-center_push.png\n' "$BASE_PATH"
printf '  %s-left_high.png\n' "$BASE_PATH"
printf '  %s-right_high.png\n' "$BASE_PATH"
printf '  %s-look_down.png\n' "$BASE_PATH"
printf '  %s-disengage.png\n' "$BASE_PATH"
