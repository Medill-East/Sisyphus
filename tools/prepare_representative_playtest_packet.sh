#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  tools/prepare_representative_playtest_packet.sh [tester-id] [report-date]

Examples:
  tools/prepare_representative_playtest_packet.sh manual-01 "$(date +%F)"

Runs representative playtest preflight, then writes a single per-tester packet
with the human run command, expected F9 report path, latest readiness report,
push-intent diagnostic evidence, and post-run validation commands.
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    return 0
  fi

  local tester_id="${1:-manual-01}"
  local report_date="${2:-$(date +%F)}"
  local playtests_dir="$ROOT_DIR/production/qa/playtests"
  local packet_path="$playtests_dir/playtest-${report_date}-${tester_id}.packet.md"
  local report_path="$playtests_dir/playtest-${report_date}-${tester_id}.md"
  local screenshot_path="$playtests_dir/playtest-${report_date}-${tester_id}.png"
  local diagnostic_base="$playtests_dir/push-intent-diagnostic-preflight-${report_date}-${tester_id}"
  local diagnostic_report="$diagnostic_base.md"
  local readiness_report="$ROOT_DIR/production/qa/milestone2-readiness.md"

  mkdir -p "$playtests_dir"

  "$ROOT_DIR/tools/run_representative_playtest.sh" --preflight "$tester_id" "$report_date"

  {
    printf '# Representative Human Playtest Packet\n\n'
    printf -- '- **Tester ID**: `%s`\n' "$tester_id"
    printf -- '- **Date**: `%s`\n' "$report_date"
    printf -- '- **Expected F9 Report**: `%s`\n' "$report_path"
    printf -- '- **Expected F9 Screenshot**: `%s`\n' "$screenshot_path"
    printf -- '- **Readiness Report**: `%s`\n' "$readiness_report"
    printf -- '- **Push Intent Diagnostic**: `%s`\n\n' "$diagnostic_report"
    printf '## Preflight Evidence\n\n'
    printf -- '- Push-intent diagnostic report: `%s`\n' "$diagnostic_report"
    printf -- '- Push-intent snapshots:\n'
    printf '  - `%s-approach.png`\n' "$diagnostic_base"
    printf '  - `%s-center_push.png`\n' "$diagnostic_base"
    printf '  - `%s-left_high.png`\n' "$diagnostic_base"
    printf '  - `%s-right_high.png`\n' "$diagnostic_base"
    printf '  - `%s-look_down.png`\n' "$diagnostic_base"
    printf '  - `%s-disengage.png`\n' "$diagnostic_base"
    printf -- '- The short diagnostic checks hand/contact/camera intent; it does not replace Human Feel Gate evidence.\n\n'
    printf '## Human Run Command\n\n'
    printf 'Use the current-handoff wrapper so the tester/date come from this packet:\n\n'
    printf '```bash\n'
    printf 'tools/run_current_representative_playtest.sh\n'
    printf '```\n\n'
    printf 'Resolved fallback command:\n\n'
    printf '```bash\n'
    printf 'tools/run_representative_playtest.sh %s %s\n' "$tester_id" "$report_date"
    printf '```\n\n'
    printf 'At `complete / Chapter I End`, press `F9`, then fill the saved report fields.\n\n'
    printf '## Fill These Sections\n\n'
    printf -- '- `Push-Feel Retest Focus`: every row must be `Yes` for a human `PROCEED`.\n'
    printf -- '  - Transition sanity: approaching and entering push view does not show long or detached arms.\n'
    printf -- '  - Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands.\n'
    printf -- '  - Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point.\n'
    printf -- '  - Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder.\n'
    printf -- '  - Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view.\n'
    printf -- '  - Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view.\n'
    printf -- '  - Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it.\n'
    printf -- '  - Aim bias retest: looking left/right changes hand contact and the stone rolling direction in a way the player can intentionally use.\n'
    printf -- '  - Pressure angle mastery: centered/sweet pressure makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill.\n'
    printf -- '  - Rollback honesty: releasing W or losing contact lets the stone stall or roll downhill under weight.\n'
    printf -- '  - Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than debug clutter.\n'
    printf -- '  - Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again.\n'
    printf -- '- `Human Feel Gate`: burden, camera pressure, aim/contact control, pressure-angle mastery, rollback honesty, visual cue clarity, release/descent contrast, Chapter I End, Human Verdict, and Verdict Reason.\n\n'
    printf '## Post-Run Commands\n\n'
    printf 'After pressing `F9` and filling the required fields, submit the current packet report:\n\n'
    printf '```bash\n'
    printf 'tools/submit_current_representative_playtest_report.sh\n'
    printf 'tools/check_milestone2_ready.sh\n'
    printf '```\n\n'
    printf 'Resolved fallback command:\n\n'
    printf '```bash\n'
    printf 'tools/submit_representative_playtest_report.sh production/qa/playtests/playtest-%s-%s.md\n' "$report_date" "$tester_id"
    printf 'tools/check_milestone2_ready.sh\n'
    printf '```\n\n'
    printf 'The submit command wraps validation, focused triage, strict gate check, Milestone 2 readiness refresh, and Milestone 3 handoff refresh.\n\n'
    printf '## Decision Rule\n\n'
    printf -- '- `PROCEED`: objective gates and filled human gates agree.\n'
    printf -- '- `PIVOT`: one narrow core-loop issue remains tunable.\n'
    printf -- '- `KILL`: the push loop premise or implementation still feels fundamentally wrong.\n'
  } > "$packet_path"

  printf '\nRepresentative playtest packet written:\n  %s\n' "$packet_path"
  printf 'Start the human run with:\n  %s/tools/run_representative_playtest.sh %s %s\n' "$ROOT_DIR" "$tester_id" "$report_date"
  printf 'Or use the current-handoff wrapper:\n  %s/tools/run_current_representative_playtest.sh\n' "$ROOT_DIR"
}

main "$@"
