#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

usage() {
  cat <<'EOF'
Usage:
  tools/check_milestone2_ready.sh [--skip-tests]

Runs the Milestone 2 vertical-slice exit gate:
  1. Fast Godot regression checks for playtest/report/gate tooling.
  2. Headless project startup.
  3. Strict vertical-slice gate requiring a filled human PROCEED report.

The command is expected to fail until a representative human playtest report
passes `tools/check_vertical_slice_gate.sh --require-proceed`.
EOF
}

run_godot_test() {
  local script="$1"
  local log_name="${script##*/}"
  log_name="${log_name%.gd}"
  printf '\n==> Godot test: %s\n' "$script"
  "$GODOT_BIN" \
    --headless \
    --path "$PROJECT_DIR" \
    --log-file "$ROOT_DIR/.tmp/milestone2-${log_name}.log" \
    --script "$script"
}

main() {
  local skip_tests="false"
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi
  if [[ "${1:-}" == "--skip-tests" ]]; then
    skip_tests="true"
    shift
  fi
  if [[ $# -ne 0 ]]; then
    usage
    return 2
  fi

  if [[ "$skip_tests" != "true" ]]; then
    mkdir -p "$ROOT_DIR/.tmp"
    run_godot_test tests/test_human_playtest_report_validator.gd
    run_godot_test tests/test_vertical_slice_gate_checker.gd
    run_godot_test tests/test_playtest_report_builder.gd
    run_godot_test tests/test_milestone2_readiness_report.gd
    run_godot_test tests/test_release_tooling.gd
    run_godot_test tests/test_push_intent_diagnostic.gd
    printf '\n==> Godot startup check\n'
    "$GODOT_BIN" \
      --headless \
      --path "$PROJECT_DIR" \
      --log-file "$ROOT_DIR/.tmp/milestone2-startup.log" \
      --quit-after 120
  fi

  printf '\n==> Strict vertical-slice gate\n'
  set +e
  "$ROOT_DIR/tools/check_vertical_slice_gate.sh" --require-proceed production/qa/playtests
  local gate_status=$?
  set -e

  if [[ "$gate_status" -ne 0 ]]; then
    printf '\n==> Current representative handoff\n'
    set +e
    "$ROOT_DIR/tools/check_current_representative_handoff.sh"
    local handoff_status=$?
    set -e
    if [[ "$handoff_status" -ne 0 ]]; then
      printf 'Current handoff check did not pass; fix the reported handoff issue before another human run.\n' >&2
    fi
  fi

  return "$gate_status"
}

main "$@"
