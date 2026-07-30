#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

usage() {
  cat <<'EOF'
Usage:
  tools/triage_human_playtest_report.sh <report-path> [triage-path]

Example:
  tools/triage_human_playtest_report.sh "production/qa/playtests/playtest-$(date +%F)-manual-01.md"
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    return 2
  fi

  local report_path="$1"
  local triage_path="${2:-}"
  if [[ "$report_path" != /* ]]; then
    report_path="$ROOT_DIR/$report_path"
  fi
  if [[ -n "$triage_path" && "$triage_path" != /* ]]; then
    triage_path="$ROOT_DIR/$triage_path"
  fi
  if [[ -z "$triage_path" ]]; then
    triage_path="${report_path%.md}.triage.md"
  fi

  mkdir -p "$ROOT_DIR/.tmp"
  "$GODOT_BIN" \
    --headless \
    --path "$PROJECT_DIR" \
    --log-file "$ROOT_DIR/.tmp/human-playtest-triage.log" \
    --script tests/write_human_playtest_triage.gd \
    -- \
    --report-path="$report_path" \
    --triage-path="$triage_path"
}

main "$@"
