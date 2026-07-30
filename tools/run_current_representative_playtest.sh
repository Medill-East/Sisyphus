#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYTESTS_DIR="$ROOT_DIR/production/qa/playtests"

usage() {
  cat <<'EOF'
Usage:
  tools/run_current_representative_playtest.sh [--show] [--preflight] [--packet <packet.md>]

Examples:
  tools/run_current_representative_playtest.sh --show
  tools/run_current_representative_playtest.sh
  tools/run_current_representative_playtest.sh --preflight

Finds the latest representative human playtest packet, reads its Tester ID and
Date fields, then delegates to the existing representative playtest scripts.
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
  local mode="run"
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
      --preflight)
        mode="preflight"
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

  local tester_id
  local report_date
  tester_id="$(packet_field "$packet_path" "Tester ID")"
  report_date="$(packet_field "$packet_path" "Date")"

  if [[ -z "$tester_id" || -z "$report_date" ]]; then
    printf 'Could not read Tester ID and Date from packet: %s\n' "$packet_path" >&2
    return 1
  fi

  printf 'Current representative playtest packet:\n  %s\n' "$packet_path"
  printf 'Tester: %s\n' "$tester_id"
  printf 'Date: %s\n' "$report_date"

  case "$mode" in
    show)
      printf '\nRun command:\n  %s/tools/run_representative_playtest.sh %s %s\n' "$ROOT_DIR" "$tester_id" "$report_date"
      ;;
    preflight)
      "$ROOT_DIR/tools/prepare_representative_playtest_packet.sh" "$tester_id" "$report_date"
      ;;
    run)
      "$ROOT_DIR/tools/run_representative_playtest.sh" "$tester_id" "$report_date"
      ;;
  esac
}

main "$@"
