#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYTESTS_DIR="$ROOT_DIR/production/qa/playtests"

usage() {
  cat <<'EOF'
Usage:
  tools/submit_current_representative_playtest_report.sh [--show] [--packet <packet.md>]

Examples:
  tools/submit_current_representative_playtest_report.sh --show
  tools/submit_current_representative_playtest_report.sh

Finds the latest representative human playtest packet, reads its Expected F9
Report field, then delegates to tools/submit_representative_playtest_report.sh.
The packet is data only; this script never executes command text from it.
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

main() {
  local mode="submit"
  local packet_path=""

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        return 0
        ;;
      --show)
        mode="show"
        shift
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
    printf 'No representative playtest packet found.\n' >&2
    printf 'Create one with: tools/prepare_representative_playtest_packet.sh tester-id YYYY-MM-DD\n' >&2
    return 1
  fi

  local report_path
  report_path="$(packet_field "$packet_path" "Expected F9 Report")"

  if [[ -z "$report_path" ]]; then
    printf 'Could not read Expected F9 Report from packet: %s\n' "$packet_path" >&2
    return 1
  fi

  printf 'Current representative playtest packet:\n  %s\n' "$packet_path"
  printf 'Expected F9 report:\n  %s\n' "$report_path"

  if [[ "$mode" == "show" ]]; then
    printf '\nSubmit command:\n  %s/tools/submit_representative_playtest_report.sh %s\n' "$ROOT_DIR" "$report_path"
    return 0
  fi

  if [[ ! -f "$report_path" ]]; then
    printf '\nExpected F9 report does not exist yet.\n' >&2
    printf 'Run: %s/tools/run_current_representative_playtest.sh\n' "$ROOT_DIR" >&2
    printf 'At `complete / Chapter I End`, press F9 and fill the saved report fields before submitting.\n' >&2
    return 1
  fi

  "$ROOT_DIR/tools/submit_representative_playtest_report.sh" "$report_path"
}

main "$@"
