# Representative Human Playtest Worksheet

Use this sheet during the Milestone 2 representative run. It is intentionally short enough to keep open while testing.

## Setup

- Tester ID: `________________`
- Date: `________________`
- Input method: `Keyboard/mouse` / `Trackpad` / `Controller`
- Planned report path: `production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md`

Run preflight before the GUI session:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/run_representative_playtest.sh --preflight tester-id YYYY-MM-DD
```

The preflight also runs the short push-intent diagnostic and prints the `push-intent-diagnostic-*.md` / PNG evidence paths. This catches hand/contact/camera regressions before the full run; it does not replace the Human Feel Gate.

Start the representative run:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/run_representative_playtest.sh tester-id YYYY-MM-DD
```

## Observer Notes

Do not coach the player beyond the opening controls unless they are fully stuck. Record confusion rather than correcting it immediately.

## Push-Feel Retest Focus

Use this short pass before judging the full representative loop. It targets the latest reticle-aligned hand/camera/contact fixes plus the 2026-05-28 pressure-angle and rollback feedback.

| Check | Pass? | Notes |
|-------|-------|-------|
| Transition sanity: approaching and entering push view does not show long or detached arms. | `Yes/No` | |
| Embodied approach: approaching the boulder feels like a body leaning in and placing hands before the camera closes, not an instant cut to floating hands. | `Yes/No` | |
| Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point. | `Yes/No` | |
| Wrist/forearm silhouette: first-person wrist/forearm shapes stay short and do not read as rods crossing through the boulder. | `Yes/No` | |
| Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view. | `Yes/No` | |
| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | `Yes/No` | |
| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | `Yes/No` | |
| Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use. | `Yes/No` | |
| Pressure angle mastery: a centered/sweet pressure angle makes slow progress, while bad high/side pressure stalls, slips, or rolls back instead of motoring uphill. | `Yes/No` | |
| Rollback honesty: releasing `W` or losing contact lets the stone stall or roll downhill under weight instead of sticking or continuing uphill. | `Yes/No` | |
| Visual cue clarity: pressure marks, route markers, and descent growth read as in-world feedback rather than unexplained yellow/blue debug clutter. | `Yes/No` | |
| Disengage/re-engage: releasing `W` or backing away returns camera/arms cleanly, and the player can approach the stone again. | `Yes/No` | |

| Moment | What To Watch | Notes |
|--------|---------------|-------|
| First minute | Does the player understand stone, mountain, and controls? | |
| First contact | Do hands/contact/aim read clearly? | |
| Mid-ascent | Does sustained push feel like labor instead of smooth transport? | |
| Aim bias | Can the player intentionally steer left/right and recover? | |
| Mistake/release | Does rollback or loss of control feel physical, not scripted? | |
| Ridge release | Does the stone naturally cross and roll down the back side? | |
| Descent | Does the changed route contrast with ascent? | |
| Chapter I End | Does stopping beside the fallen stone feel intentional? | |

## Required End Capture

At `complete / Chapter I End`, press `F9`. Confirm both files exist:

- Report: `production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md`
- Screenshot: `production/qa/playtests/playtest-YYYY-MM-DD-tester-id.png`

Fill the `Human Feel Gate` in the report:

- `Burden reads as physical labor?`: `Yes` / `No` / `Partially`
- `Camera pressure is intense but playable?`: `Yes` / `No` / `Partially`
- `Aim changes hand contact and push direction?`: `Yes` / `No` / `Partially`
- `Pressure angle mastery feels learnable?`: `Yes` / `No` / `Partially`
- `Stone releases or rolls back when force is wrong?`: `Yes` / `No` / `Partially`
- `Release/descent contrast is clear?`: `Yes` / `No` / `Partially`
- `Visual cues read as world/pressure, not debug clutter?`: `Yes` / `No` / `Partially`
- `Chapter I End reads as intentional, not unfinished?`: `Yes` / `No` / `Partially`
- `Human Verdict`: `PROCEED` / `PIVOT` / `KILL`
- `Verdict Reason`: one concrete sentence naming the decisive cause.

## Post-Run Commands

Submit the filled report:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/submit_representative_playtest_report.sh production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md
```

This validates the filled human report, writes focused triage, runs the strict vertical-slice gate, refreshes `production/qa/milestone2-readiness.md`, and refreshes `production/milestones/milestone3-alpha-handoff.md`.

Recheck Milestone 2 after any follow-up edits:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/check_milestone2_ready.sh
```

The underlying commands remain available for debugging:

```bash
/Users/haodong/Documents/GitHub/Sisyphus/tools/validate_human_playtest_report.sh production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md
/Users/haodong/Documents/GitHub/Sisyphus/tools/triage_human_playtest_report.sh production/qa/playtests/playtest-YYYY-MM-DD-tester-id.md
/Users/haodong/Documents/GitHub/Sisyphus/tools/write_milestone3_handoff_report.sh
```

## Decision Rule

- `PROCEED`: only if objective gates and Human Feel Gate agree.
- `PIVOT`: one narrow core-loop issue remains tunable.
- `KILL`: the push loop premise or implementation still feels fundamentally wrong; do not expand content.
