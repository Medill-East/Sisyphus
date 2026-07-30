#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYTESTS_DIR="$ROOT_DIR/production/qa/playtests"

usage() {
  cat <<'EOF'
Usage:
  tools/check_current_representative_handoff.sh [--packet <packet.md>]

Checks the latest representative human playtest packet and reports whether the
preflight evidence exists, whether the expected F9 report exists, and which
command should run next. This does not replace the Human Feel Gate.
EOF
}

latest_packet_path() {
  local latest=""
  while IFS= read -r candidate; do
    latest="$candidate"
  done < <(find "$PLAYTESTS_DIR" -maxdepth 1 -type f -name 'playtest-*.packet.md' | sort)
  printf '%s' "$latest"
}

packet_field() {
  local packet_path="$1"
  local field_name="$2"
  awk -v field="$field_name" '
    $0 ~ "^- \\*\\*" field "\\*\\*:" {
      line=$0
      sub("^- \\*\\*" field "\\*\\*: `?", "", line)
      sub("`$", "", line)
      print line
      exit
    }
  ' "$packet_path"
}

check_file() {
  local label="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    printf 'OK %s: %s\n' "$label" "$path"
    return 0
  fi
  printf 'MISSING %s: %s\n' "$label" "$path"
  return 1
}

main() {
  local packet_path=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        return 0
        ;;
      --packet)
        packet_path="${2:-}"
        if [[ -z "$packet_path" ]]; then
          printf 'Missing value for --packet.\n' >&2
          return 2
        fi
        shift 2
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        return 2
        ;;
    esac
  done

  if [[ -z "$packet_path" ]]; then
    packet_path="$(latest_packet_path)"
  elif [[ "$packet_path" != /* ]]; then
    packet_path="$ROOT_DIR/$packet_path"
  fi

  if [[ -z "$packet_path" || ! -f "$packet_path" ]]; then
    printf 'HANDOFF_STATUS=NOT_READY\n'
    printf 'HANDOFF_REASON=no representative playtest packet found\n'
    printf 'NEXT_COMMAND=tools/prepare_representative_playtest_packet.sh tester-id YYYY-MM-DD\n'
    return 1
  fi

  local tester_id
  local report_date
  local expected_report
  local expected_screenshot
  local diagnostic_report
  tester_id="$(packet_field "$packet_path" "Tester ID")"
  report_date="$(packet_field "$packet_path" "Date")"
  expected_report="$(packet_field "$packet_path" "Expected F9 Report")"
  expected_screenshot="$(packet_field "$packet_path" "Expected F9 Screenshot")"
  diagnostic_report="$(packet_field "$packet_path" "Push Intent Diagnostic")"

  printf 'HANDOFF_PACKET=%s\n' "$packet_path"
  printf 'HANDOFF_TESTER=%s\n' "$tester_id"
  printf 'HANDOFF_DATE=%s\n' "$report_date"

  local missing_required=0
  [[ -n "$tester_id" ]] || missing_required=1
  [[ -n "$report_date" ]] || missing_required=1
  [[ -n "$expected_report" ]] || missing_required=1
  [[ -n "$expected_screenshot" ]] || missing_required=1
  [[ -n "$diagnostic_report" ]] || missing_required=1

  if [[ "$missing_required" -ne 0 ]]; then
    printf 'HANDOFF_STATUS=NOT_READY\n'
    printf 'HANDOFF_REASON=packet is missing required fields\n'
    printf 'NEXT_COMMAND=tools/prepare_representative_playtest_packet.sh tester-id YYYY-MM-DD\n'
    return 1
  fi

  local missing_preflight=0
  check_file "push-intent diagnostic" "$diagnostic_report" || missing_preflight=1
  local base="${diagnostic_report%.md}"
  for suffix in approach center_push left_high right_high look_down disengage; do
    check_file "push-intent snapshot $suffix" "$base-$suffix.png" || missing_preflight=1
  done

  local report_exists=0
  local screenshot_exists=0
  [[ -f "$expected_report" ]] && report_exists=1
  [[ -f "$expected_screenshot" ]] && screenshot_exists=1

  if [[ "$missing_preflight" -ne 0 ]]; then
    printf 'HANDOFF_STATUS=NOT_READY\n'
    printf 'HANDOFF_REASON=preflight evidence missing\n'
    printf 'NEXT_COMMAND=tools/run_current_representative_playtest.sh --preflight\n'
    return 1
  fi

  if [[ "$report_exists" -eq 0 ]]; then
    printf 'HANDOFF_STATUS=READY_FOR_HUMAN_RUN\n'
    printf 'HANDOFF_REASON=preflight evidence is present; expected F9 report is not present yet\n'
    printf 'EXPECTED_F9_REPORT=%s\n' "$expected_report"
    printf 'NEXT_COMMAND=tools/run_current_representative_playtest.sh\n'
    return 0
  fi

  if [[ "$screenshot_exists" -eq 0 ]]; then
    printf 'HANDOFF_STATUS=REPORT_INCOMPLETE\n'
    printf 'HANDOFF_REASON=F9 report exists but expected screenshot is missing\n'
    printf 'EXPECTED_F9_SCREENSHOT=%s\n' "$expected_screenshot"
    printf 'NEXT_COMMAND=tools/run_current_representative_playtest.sh\n'
    return 1
  fi

  printf 'HANDOFF_STATUS=READY_TO_SUBMIT\n'
  printf 'HANDOFF_REASON=F9 report and screenshot exist; submit after required human fields are filled\n'
  printf 'EXPECTED_F9_REPORT=%s\n' "$expected_report"
  printf 'NEXT_COMMAND=tools/submit_current_representative_playtest_report.sh\n'
}

main "$@"
