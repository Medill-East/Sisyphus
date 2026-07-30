# Sisyphus Vertical Slice Playtest Protocol

## Purpose

Validate whether the current Godot vertical slice supports the core fantasy: a close, oppressive, physical push up the front slope, natural release over the ridge, descent through the changed path, and a readable emotional contrast.

This is not a content-complete QA pass. It is a feel gate for the Steam vertical slice.

## Build Under Test

Use the current Milestone 2 readiness report and per-tester packet as the
authoritative handoff. They name the active tester/date, expected F9 report, and
post-run submit command:

```text
production/qa/milestone2-readiness.md
production/qa/playtests/playtest-YYYY-MM-DD-tester-id.packet.md
```

For the current handoff, use:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/run_current_representative_playtest.sh
```

To preview the resolved tester/date without launching Godot:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/run_current_representative_playtest.sh --show
```

To check whether the current handoff is ready for a human run, already waiting
for report submission, or missing preflight evidence:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/check_current_representative_handoff.sh
```

After the run is complete, `F9` has saved the report, and the required human
fields are filled, submit the current packet's expected report with:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/submit_current_representative_playtest_report.sh
```

To preview the resolved report path without submitting:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/submit_current_representative_playtest_report.sh --show
```

This launches `VerticalSlice.tscn` with `--slice-pacing=representative` and sets the in-game `F9` snapshot path to `production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md`. After Godot exits, the helper validates the saved report and runs the strict Milestone 2 gate.

Before launching the GUI run, use the preflight to confirm the F9 capture contract, human report validator, short push-intent diagnostic, and current readiness report. If starting a new tester/date, replace the placeholders and use the generated packet as the next authoritative handoff:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/prepare_representative_playtest_packet.sh tester-id YYYY-MM-DD
```

The preflight does not replace the human playtest. It only verifies that the evidence path and current hand/contact/camera intent check are ready before the tester spends a 5-10 minute run.

Use the short observer worksheet during the session:

```text
production/qa/playtests/representative-human-playtest-worksheet.md
```

The worksheet is the live checklist; this README is the longer protocol reference.

Before spending time on a full representative human run, use the short push-intent diagnostic when the current question is specifically whether hands, reticle, camera, and stone direction are readable:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/run_push_intent_diagnostic.sh "$(date +%F)-manual-check"
```

This writes `production/qa/playtests/push-intent-diagnostic-*.md` plus six PNG snapshots for approach, center push, left-high aim, right-high aim, look-down, and disengage. A `PROCEED` diagnostic means the short hand/contact/aim evidence is strong enough to justify a representative run. It does not replace the filled `Human Feel Gate`.

Run the playable vertical slice:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn
```

Optionally choose where the in-scene `F9` snapshot writes:

```bash
REPORT_DATE="$(date +%F)"
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --playtest-tester-id=tester-id --playtest-report-path="/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-${REPORT_DATE}-tester-id.md"
```

Use the automated comparison route when checking the baseline:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --vs-auto=route
```

Use the representative pacing profile for a human long-route vertical-slice check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn -- --slice-pacing=representative
```

Generate the current automated baseline report:

```bash
REPORT_DATE="$(date +%F)"
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/generate_auto_route_playtest_report.gd -- --report-date="$REPORT_DATE" --tester-id=auto-route-current --report-path="/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-${REPORT_DATE}-auto-route.md"
```

The automated report defaults to `--slice-pacing=smoke` so routine regressions stay fast. A representative run can be generated with `-- --slice-pacing=representative`, but expect a much longer physics run and prefer this for scheduled playtest evidence rather than every code change.

Generate the current full representative automated baseline:

```bash
REPORT_DATE="$(date +%F)"
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/generate_auto_route_playtest_report.gd -- --slice-pacing=representative --route-checkpoint=front --max-auto-route-frames=42000 --skip-push-lab-gate --report-date="$REPORT_DATE" --tester-id=auto-route-representative-full-current --report-path="/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-${REPORT_DATE}-auto-route-representative-full.md"
```

This long run is milestone evidence, not a routine regression. The current 2026-05-27 baseline reaches `complete` in 381.4s with `Push Gate PROCEED`, `Burden Gate PROCEED`, and `Slice Gate PROCEED`; PushLab is intentionally skipped in this command to keep the full-route run focused and bounded.

For a bounded representative diagnostic that writes partial evidence quickly instead of waiting for the full route:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/generate_auto_route_playtest_report.gd -- --slice-pacing=representative --max-auto-route-frames=1800 --skip-push-lab-gate --report-date=2026-05-26 --tester-id=auto-route-representative-diagnostic --report-path=/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-2026-05-26-auto-route-representative-diagnostic.md
```

Treat bounded diagnostics as `PIVOT` evidence unless they reach `Route Complete: Yes`; they are useful for locating pacing and burden problems, not for proving the 5-10 minute loop.

Use route checkpoints to isolate representative-route failures without pretending they prove a continuous run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/generate_auto_route_playtest_report.gd -- --slice-pacing=representative --route-checkpoint=ridge --max-auto-route-frames=1800 --skip-push-lab-gate --report-date=2026-05-26 --tester-id=auto-route-representative-ridge --report-path=/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-2026-05-26-auto-route-representative-ridge.md
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/generate_auto_route_playtest_report.gd -- --slice-pacing=representative --route-checkpoint=descent --max-auto-route-frames=1200 --skip-push-lab-gate --report-date=2026-05-26 --tester-id=auto-route-representative-descent --report-path=/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-2026-05-26-auto-route-representative-descent.md
```

Checkpoint reports are diagnostic only. `front` is the real continuous start. `ridge` checks late-ascent release/descent continuity. `descent` checks the final walk-back-to-stone completion shell. Only a `front` run that reaches `complete` inside the representative timing window can satisfy the vertical-slice pacing gate.

For a stronger late-route diagnostic that includes the long back-slope descent:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/generate_auto_route_playtest_report.gd -- --slice-pacing=representative --route-checkpoint=ridge --max-auto-route-frames=9000 --skip-push-lab-gate --report-date=2026-05-26 --tester-id=auto-route-representative-ridge-long --report-path=/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-2026-05-26-auto-route-representative-ridge-long.md
```

This proves the late route can continue through release, descent, and first-loop completion when `Route Complete: Yes`; it still does not replace a continuous `front` representative run.

## Tester Instructions

1. Start from the front base.
2. Use `WASD` and mouse/trackpad look.
3. Hold `W` to push the stone; release or back away only when you intend to disengage.
4. Push the stone over the ridge.
5. Walk down the back slope and approach the fallen stone.
6. Treat this `complete / Chapter I End` state as the end of the first loop; do not continue into another same-scene push as a placeholder for Chapter II.
7. Press `F9` to save a manual playtest snapshot report plus a same-name `.png` screenshot.
8. Record what the HUD telemetry shows at the end.
9. Fill the `Push-Feel Retest Focus` and `Human Feel Gate` fields in the saved report. The retest must include embodied approach, center-reticle surface targeting, hand-surface clearance, short wrist/forearm silhouette, downward look, peripheral read, aim bias, pressure-angle mastery, rollback honesty, visual cue clarity, and disengage/re-engage.
10. If you used `run_representative_playtest.sh`, close Godot after saving and let the helper validate the report automatically. To submit or re-submit a filled report:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/submit_representative_playtest_report.sh production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md
```

This wraps report validation, focused triage, strict gate check, Milestone 2 readiness refresh, and Milestone 3 handoff refresh.

To re-run only validation manually:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/validate_human_playtest_report.sh production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md
```

Then check the milestone gate across all playtest reports:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/check_vertical_slice_gate.sh production/qa/playtests
```

Use strict mode when a milestone or CI gate must fail unless the human report is `PROCEED`:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/check_vertical_slice_gate.sh --require-proceed production/qa/playtests
```

For the full Milestone 2 exit check, run:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/check_milestone2_ready.sh
```

This runs the fast report/gate/tooling regressions, a headless startup check, and the strict human vertical-slice gate. It is expected to fail until a filled representative human report reaches `PROCEED`.

To write a persistent readiness summary after checks:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/write_milestone2_readiness_report.sh
```

This writes `production/qa/milestone2-readiness.md`.

After a human report is filled, create a focused triage note before tuning:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/triage_human_playtest_report.sh production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md
```

This writes `playtest-YYYY-MM-DD-tester-id.triage.md` next to the source report. Use it to choose exactly one next core-loop focus: push contact/aim, sustained burden, camera pressure, release/descent contrast, or Chapter I ending readability. Do not use triage as a substitute for the strict Milestone 2 gate.

Write the gated Milestone 3 handoff after the strict gate status is known:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/write_milestone3_handoff_report.sh
```

This writes `production/milestones/milestone3-alpha-handoff.md`. It remains `LOCKED` unless Milestone 2 has a valid representative human `PROCEED` report.

## Required Evidence

- Screenshot during approach.
- Screenshot during ascent push with `Telemetry` visible.
- Screenshot at release or descent.
- Screenshot at completion or after failure.
- The `F9` snapshot report and same-name `.png` screenshot if available.
- Final `Telemetry` line.
- Pacing profile used: `smoke` for short regression, `representative` for 5-10 minute slice evidence.
- Subjective notes on burden, camera comfort, route clarity, and emotional contrast.
- Filled `Human Feel Gate` section in the F9 report, including `Human Verdict: PROCEED/PIVOT/KILL`.
- Filled `Push-Feel Retest Focus` section in the F9 report, including `Reticle surface targeting`.
- A human `PROCEED` must confirm that correct pressure angle matters, wrong pressure can stall or roll the stone back, and non-HUD visual cues read as in-world pressure/route/descent feedback rather than unexplained debug objects.
- If `Human Verdict` is `PROCEED`, the same report must also show `Pacing Profile: representative`, `Phase At End: complete`, and `Push Gate` / `Burden Gate` / `Slice Gate` all `PROCEED`.
- Compare the final telemetry against the current automated baselines:
  - `production/qa/playtests/playtest-2026-05-27-auto-route.md` for fast smoke stability plus PushLab bias evidence.
  - `production/qa/playtests/playtest-2026-05-27-auto-route-representative-full.md` for representative pacing and full-loop telemetry.
  Differences from the automated baselines are useful evidence, not failures by themselves.

## Telemetry Gates

Use `RouteTelemetry` as separate gates:

- `Push Gate`: contact ratio, distance, loss count, and spin ratio. This answers whether the hand-contact rolling model is mechanically stable enough to continue.
- `Burden Gate`: uphill push distance, average/minimum uphill speed, and slow-push duration. This answers whether the run contains measurable labor instead of only smooth transport.
- `Slice Gate`: loop duration and completion. This answers whether the current run is a representative vertical slice, not only a compressed smoke test.
- `Push Lab Bias Gate`: left/right aim bias, near-channel obstacle contact, recovery, launch guard, and spin guard from `PushLab.evaluate_bias_recovery_route`. This answers whether the core hand-contact push remains controllable before trusting the full-route smoke.

For both gates:

- `PROCEED`: the measured layer is acceptable for further human feel testing.
- `PIVOT`: the premise still works, but the measured layer needs tuning or more representative content.
- `KILL`: the measured layer is broken enough that content expansion should stop.

The current representative slice target is controlled by `Tuning.representative_slice_min_seconds` and `Tuning.representative_slice_max_seconds` (default 5-10 minutes). Automated `Push Gate PROCEED` and `Push Lab Bias Gate PROCEED` are not enough for Steam readiness; if `Burden Gate` is `PIVOT`, tune sustained push labor before expanding content. A compressed route should remain `Slice Gate PIVOT` until a complete 5-10 minute loop is validated. Human notes must still confirm the experience feels heavy, legible, and compelling rather than merely passable.

Do not run representative pacing as a routine headless regression after every code change. It is deliberately long and should be reserved for scheduled human/visual validation or targeted overnight automation. Routine iteration should use the smoke automated report plus focused push-lab/physics tests.

## Report Format

Create reports under:

```text
production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md
```

Use the generated structure from `PlaytestReportBuilder.gd`:

- Session info.
- First impressions.
- Quantitative telemetry data.
- Gameplay flow notes.
- Bugs encountered.
- Action routing.
- Overall assessment.
- Top 3 priorities.

## Pass Criteria For Next Milestone

- At least one human run reaches descent or completion without assistance.
- Final push gate is `PROCEED` or the reason for `PIVOT` is narrow and tunable.
- Slice gate is either `PROCEED` for a representative 5-10 minute run, or explicitly documented as `PIVOT` because the run was intentionally compressed.
- Tester can explain the goal and controls within the first minute.
- Camera feels oppressive without causing immediate discomfort.
- Stone movement reads as heavy contact rolling, not script dragging.
- Descent creates a perceptible contrast from ascent.
- `Human Verdict` is `PROCEED`, or `PIVOT` with one narrow tunable reason. A `KILL` verdict blocks content expansion.
- A `Human Verdict: PROCEED` is valid only when the objective telemetry in the same report also reaches representative completion: `Pacing Profile: representative`, `Phase At End: complete`, `Push Gate: PROCEED`, `Burden Gate: PROCEED`, and `Slice Gate: PROCEED`.
- `check_vertical_slice_gate.sh --require-proceed` exits successfully and reports `VERTICAL_SLICE_GATE=PROCEED`. Non-strict mode may be used for status reporting, but not for milestone advancement.
- `check_milestone2_ready.sh` exits successfully. Until then, Milestone 2 remains open even if automated route reports are `PROCEED`.
