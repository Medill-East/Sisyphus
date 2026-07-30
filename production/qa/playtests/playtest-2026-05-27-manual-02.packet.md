# Representative Human Playtest Packet

- **Tester ID**: `manual-02`
- **Date**: `2026-05-27`
- **Expected F9 Report**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-2026-05-27-manual-02.md`
- **Expected F9 Screenshot**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-2026-05-27-manual-02.png`
- **Readiness Report**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/milestone2-readiness.md`
- **Push Intent Diagnostic**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02.md`

## Preflight Evidence

- Push-intent diagnostic report: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02.md`
- Push-intent snapshots:
  - `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02-approach.png`
  - `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02-center_push.png`
  - `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02-left_high.png`
  - `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02-right_high.png`
  - `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02-look_down.png`
  - `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-preflight-2026-05-27-manual-02-disengage.png`
- The short diagnostic checks hand/contact/camera intent; it does not replace Human Feel Gate evidence.

## Human Run Command

Use the current-handoff wrapper so the tester/date come from this packet:

```bash
tools/run_current_representative_playtest.sh
```

Resolved fallback command:

```bash
tools/run_representative_playtest.sh manual-02 2026-05-27
```

At `complete / Chapter I End`, press `F9`, then fill the saved report fields.

## Fill These Sections

- `Push-Feel Retest Focus`: every row must be `Yes` for a human `PROCEED`.
  - Transition sanity: approaching and entering push view does not show long or detached arms.
  - Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands.
  - Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point.
  - Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder.
  - Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view.
  - Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view.
  - Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it.
  - Aim bias retest: looking left/right changes hand contact and the stone rolling direction in a way the player can intentionally use.
  - Pressure angle mastery: centered/sweet pressure makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill.
  - Rollback honesty: releasing W or losing contact lets the stone stall or roll downhill under weight.
  - Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than debug clutter.
  - Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again.
- `Human Feel Gate`: burden, camera pressure, aim/contact control, pressure-angle mastery, rollback honesty, visual cue clarity, release/descent contrast, Chapter I End, Human Verdict, and Verdict Reason.

## Post-Run Commands

After pressing `F9` and filling the required fields, submit the current packet report:

```bash
tools/submit_current_representative_playtest_report.sh
tools/check_milestone2_ready.sh
```

Resolved fallback command:

```bash
tools/submit_representative_playtest_report.sh production/qa/playtests/playtest-2026-05-27-manual-02.md
tools/check_milestone2_ready.sh
```

The submit command wraps validation, focused triage, strict gate check, Milestone 2 readiness refresh, and Milestone 3 handoff refresh.

## Decision Rule

- `PROCEED`: objective gates and filled human gates agree.
- `PIVOT`: one narrow core-loop issue remains tunable.
- `KILL`: the push loop premise or implementation still feels fundamentally wrong.
