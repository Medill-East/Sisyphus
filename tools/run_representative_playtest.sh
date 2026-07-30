#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/godot"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

usage() {
  cat <<'EOF'
Usage:
  tools/run_representative_playtest.sh [--preflight] [tester-id] [report-date]

Examples:
  tools/run_representative_playtest.sh --preflight manual-01 "$(date +%F)"
  tools/run_representative_playtest.sh manual-01 "$(date +%F)"
  tools/run_representative_playtest.sh haodong

Press F9 in-game to save the manual playtest report and screenshot.
After Godot exits, this script validates the saved report and strict milestone gate.
EOF
}

run_godot_preflight_test() {
  local script="$1"
  local log_name="${script##*/}"
  log_name="${log_name%.gd}"
  "$GODOT_BIN" \
    --headless \
    --path "$PROJECT_DIR" \
    --log-file "$ROOT_DIR/.tmp/representative-preflight-${log_name}.log" \
    --script "$script"
}

run_push_intent_preflight() {
  local tester_id="$1"
  local report_date="$2"
  local stamp="preflight-${report_date}-${tester_id}"
  printf '\nRunning short push-intent diagnostic...\n'
  "$ROOT_DIR/tools/run_push_intent_diagnostic.sh" "$stamp"
  printf '\nPush-intent diagnostic evidence prefix:\n'
  printf '  %s/production/qa/playtests/push-intent-diagnostic-%s\n' "$ROOT_DIR" "$stamp"
  printf 'This verifies hand/contact/camera intent before the representative run; it does not replace the filled Human Feel Gate.\n'
}

print_push_feel_retest_focus() {
  cat <<'EOF'

Push-Feel Retest Focus:
  1. Transition sanity: approaching and entering push view does not show long or detached arms.
  2. Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands.
  3. Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point.
  4. Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder.
  5. Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view.
  6. Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view.
  7. Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it.
  8. Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use.
  9. Pressure angle mastery: centered/sweet pressure makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill.
  10. Rollback honesty: releasing W or losing contact lets the stone stall or roll downhill under weight.
  11. Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than debug clutter.
  12. Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again.
EOF
}

run_preflight() {
  local tester_id="$1"
  local report_date="$2"
  local report_path="$ROOT_DIR/production/qa/playtests/playtest-${report_date}-${tester_id}.md"

  mkdir -p "$ROOT_DIR/.tmp"
  printf 'Representative playtest preflight.\n'
  printf 'Tester: %s\n' "$tester_id"
  printf 'Planned F9 report path: %s\n\n' "$report_path"

  printf 'Checking F9 playtest capture contract...\n'
  run_godot_preflight_test tests/test_vertical_slice_playtest_capture.gd

  printf '\nChecking human report validator contract...\n'
  run_godot_preflight_test tests/test_human_playtest_report_validator.gd

  run_push_intent_preflight "$tester_id" "$report_date"

  printf '\nWriting current Milestone 2 readiness report...\n'
  "$ROOT_DIR/tools/write_milestone2_readiness_report.sh"

  printf '\nPreflight passed. Start the human run with:\n'
  printf '  %s/tools/run_representative_playtest.sh %s %s\n' "$ROOT_DIR" "$tester_id" "$report_date"
  print_push_feel_retest_focus
  printf '\nDuring the run: complete Chapter I, press F9 at `complete / Chapter I End`, then fill Push-Feel Retest Focus and Human Feel Gate fields in %s.\n' "$report_path"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi

  local preflight="false"
  if [[ "${1:-}" == "--preflight" ]]; then
    preflight="true"
    shift
  fi

  local tester_id="${1:-manual-representative}"
  local report_date="${2:-$(date +%F)}"
  local report_path="$ROOT_DIR/production/qa/playtests/playtest-${report_date}-${tester_id}.md"

  if [[ "$preflight" == "true" ]]; then
    run_preflight "$tester_id" "$report_date"
    return 0
  fi

  printf 'Starting representative playtest.\n'
  printf 'Tester: %s\n' "$tester_id"
  printf 'F9 report path: %s\n' "$report_path"
  print_push_feel_retest_focus

  set +e
  "$GODOT_BIN" \
    --path "$PROJECT_DIR" \
    --scene res://scenes/VerticalSlice.tscn \
    -- \
    --slice-pacing=representative \
    --playtest-tester-id="$tester_id" \
    --playtest-report-path="$report_path"
  local godot_status=$?
  set -e

  if [[ "$godot_status" -ne 0 ]]; then
    printf 'Godot exited with status %d; skipping report validation.\n' "$godot_status" >&2
    return "$godot_status"
  fi

  if [[ ! -f "$report_path" ]]; then
    printf '\nRepresentative playtest report missing.\n' >&2
    printf 'Press F9 at `complete / Chapter I End` before quitting the run.\n' >&2
    printf 'Expected report path: %s\n' "$report_path" >&2
    return 1
  fi

  printf '\nValidating representative playtest report...\n'
  set +e
  "$ROOT_DIR/tools/validate_human_playtest_report.sh" "$report_path"
  local validation_status=$?
  set -e

  if [[ -f "$report_path" ]]; then
    printf '\nWriting human playtest triage...\n'
    "$ROOT_DIR/tools/triage_human_playtest_report.sh" "$report_path"
  else
    printf 'Report was not found; skipping triage: %s\n' "$report_path" >&2
  fi

  if [[ "$validation_status" -ne 0 ]]; then
    return "$validation_status"
  fi

  printf '\nChecking Milestone 2 strict gate...\n'
  "$ROOT_DIR/tools/check_vertical_slice_gate.sh" --require-proceed production/qa/playtests
}

main "$@"
