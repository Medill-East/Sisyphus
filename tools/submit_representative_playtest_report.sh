#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  tools/submit_representative_playtest_report.sh <playtest-report.md>

Example:
  tools/submit_representative_playtest_report.sh production/qa/playtests/playtest-2026-05-27-manual-01.md

Validates a filled representative human playtest report, writes focused triage,
refreshes Milestone 2 readiness and Milestone 3 handoff state, then runs the
strict vertical-slice gate.
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi

  local report_path="${1:-}"
  if [[ -z "$report_path" ]]; then
    usage >&2
    return 2
  fi

  if [[ ! -f "$report_path" ]]; then
    printf 'Representative playtest report not found: %s\n' "$report_path" >&2
    return 1
  fi

  printf 'Submitting representative playtest report:\n  %s\n' "$report_path"

  printf '\nValidating filled human report...\n'
  set +e
  "$ROOT_DIR/tools/validate_human_playtest_report.sh" "$report_path"
  local validation_status=$?
  set -e

  printf '\nWriting focused human playtest triage...\n'
  "$ROOT_DIR/tools/triage_human_playtest_report.sh" "$report_path"

  printf '\nChecking strict vertical-slice gate...\n'
  set +e
  "$ROOT_DIR/tools/check_vertical_slice_gate.sh" --require-proceed production/qa/playtests
  local gate_status=$?
  set -e

  printf '\nRefreshing Milestone 2 readiness report...\n'
  "$ROOT_DIR/tools/write_milestone2_readiness_report.sh"

  printf '\nRefreshing Milestone 3 handoff report...\n'
  "$ROOT_DIR/tools/write_milestone3_handoff_report.sh"

  if [[ "$validation_status" -ne 0 ]]; then
    printf '\nReport validation failed; see triage and readiness report for next action.\n' >&2
    return "$validation_status"
  fi

  if [[ "$gate_status" -ne 0 ]]; then
    printf '\nStrict milestone gate did not pass; see readiness report for current PIVOT/KILL reason.\n' >&2
    return "$gate_status"
  fi

  printf '\nRepresentative playtest report accepted by the strict Milestone 2 gate.\n'
}

main "$@"
