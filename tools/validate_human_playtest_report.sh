#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

usage() {
  cat <<'EOF'
Usage:
  tools/validate_human_playtest_report.sh <report.md>

Example:
  tools/validate_human_playtest_report.sh "production/qa/playtests/playtest-$(date +%F)-manual-01.md"
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi
  if [[ $# -ne 1 ]]; then
    usage
    return 2
  fi

  local report_path="$1"
  if [[ "$report_path" != /* ]]; then
    report_path="$ROOT_DIR/$report_path"
  fi
  local log_dir="$ROOT_DIR/.tmp"
  mkdir -p "$log_dir"

  exec "$GODOT_BIN" \
    --headless \
    --path "$PROJECT_DIR" \
    --log-file "$log_dir/human-playtest-report-validator.log" \
    --script tests/validate_human_playtest_report.gd \
    -- \
    --report-path="$report_path"
}

main "$@"
