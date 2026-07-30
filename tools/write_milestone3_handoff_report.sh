#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

usage() {
  cat <<'EOF'
Usage:
  tools/write_milestone3_handoff_report.sh [report-path]

Example:
  tools/write_milestone3_handoff_report.sh production/milestones/milestone3-alpha-handoff.md
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi

  local report_path="${1:-production/milestones/milestone3-alpha-handoff.md}"
  if [[ "$report_path" != /* ]]; then
    report_path="$ROOT_DIR/$report_path"
  fi
  local log_dir="$ROOT_DIR/.tmp"
  mkdir -p "$log_dir"

  "$GODOT_BIN" \
    --headless \
    --path "$PROJECT_DIR" \
    --log-file "$log_dir/milestone3-handoff-report.log" \
    --script tests/write_milestone3_handoff_report.gd \
    -- \
    --playtests-dir="$ROOT_DIR/production/qa/playtests" \
    --report-path="$report_path"
}

main "$@"
