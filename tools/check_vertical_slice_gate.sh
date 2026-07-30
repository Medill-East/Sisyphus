#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

usage() {
  cat <<'EOF'
Usage:
  tools/check_vertical_slice_gate.sh [--require-proceed] [playtests-dir]

Example:
  tools/check_vertical_slice_gate.sh production/qa/playtests
  tools/check_vertical_slice_gate.sh --require-proceed production/qa/playtests
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi

  local require_proceed="false"
  if [[ "${1:-}" == "--require-proceed" ]]; then
    require_proceed="true"
    shift
  fi

  local playtests_dir="${1:-production/qa/playtests}"
  if [[ "$playtests_dir" != /* ]]; then
    playtests_dir="$ROOT_DIR/$playtests_dir"
  fi
  local log_dir="$ROOT_DIR/.tmp"
  mkdir -p "$log_dir"

  local args=(
    "$GODOT_BIN"
    --headless \
    --path "$PROJECT_DIR" \
    --log-file "$log_dir/vertical-slice-gate.log" \
    --script tests/check_vertical_slice_gate.gd \
    -- \
    --playtests-dir="$playtests_dir"
  )
  if [[ "$require_proceed" == "true" ]]; then
    args+=(--require-proceed)
  fi

  exec "${args[@]}"
}

main "$@"
