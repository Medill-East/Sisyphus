# Playtest Report

## Session Info
- **Date**: 2026-05-26
- **Build**: local-godot-auto-route
- **Duration**: 381.2s
- **Tester**: auto-route-representative-full
- **Platform**: macOS
- **Input Method**: Automated route driver
- **Session Type**: Automated baseline
- **Pacing Profile**: representative
- **Estimated Pacing Loop**: 534.0s

## Test Focus
Sisyphus Downhill Vertical Slice: front-base push route, ridge release, back-slope descent, return to the stone, first-loop ending, and telemetry gate.

## First Impressions (First 5 minutes)
- **Understood the goal?** [Yes/No/Partially]
- **Understood the controls?** [Yes/No/Partially]
- **Emotional response**: [Engaged/Confused/Bored/Frustrated/Excited]
- **Notes**: [Observations]

## Quantitative Data
Push Gate: PROCEED | Burden Gate: PROCEED | Slice Gate: PROCEED | Contact: 100% | Loss: 1 | Dist: 2.57 | Spin: 1.0
- **Push Gate**: PROCEED
- **Push Gate Reason**: stable contact and coupled rolling
- **Burden Gate**: PROCEED
- **Burden Gate Reason**: measurable labor and controlled uphill work
- **Slice Gate**: PROCEED
- **Slice Gate Reason**: representative 5-10 minute complete loop
- **Contact**: 100%
- **Contact Losses**: 1
- **Max Player-Stone Distance**: 2.57
- **Max Spin Ratio**: 1.0
- **Phase At End**: complete
- **Uphill Push Distance**: 246.06m
- **Average Push Uphill Speed**: 0.86m/s
- **Minimum Push Uphill Speed**: 0.01m/s
- **Slow Push Duration**: 140.4s
- **Push Lab Bias Gate**: SKIPPED
- **Push Lab Bias Gate Reason**: bounded representative diagnostic
- **Approach Duration**: 0.2s
- **Ascent Duration**: 286.2s
- **Release Duration**: 0.4s
- **Descent Duration**: 94.4s
- **Complete Duration**: 0.0s

## Gameplay Flow
### What worked well
- [Observation 1]

### Pain points
- [Issue 1 -- Severity: High/Medium/Low]

### Confusion points
- [Where the player was confused and why]

### Moments of delight
- [What surprised or pleased the player]

## Bugs Encountered
| # | Description | Severity | Reproducible |
|---|-------------|----------|--------------|

## Action Routing
### Design changes needed
- No blocking design change from push telemetry; validate emotional intent with human notes.

### Balance adjustments
- Keep current baseline; tune only after human fatigue/confusion notes.

### Bug reports
- Log reproducible collision, camera, or phase-transition failures observed during the run.

### Polish items
- Record readability, animation, HUD, audio, and environment-response friction after core route gate is stable.

## Overall Assessment
- **Would play again?** [Yes/No/Maybe]
- **Difficulty**: [Too Easy / Just Right / Too Hard]
- **Pacing**: [Too Slow / Good / Too Fast]
- **Session length preference**: [Shorter / Good / Longer]

## Top 3 Priorities
1. Run a human 5-10 minute playtest using this report.
2. Compare subjective burden, camera comfort, and route clarity against telemetry.
3. Validate whether the generated hum improves the descent contrast or needs audio direction.

## Automated Evidence
- **Final Phase**: complete
- **Pacing Profile**: representative
- **Route Checkpoint**: front
- **Estimated Pacing Loop**: 534.0s
- **Route Complete**: Yes
- **Checkpoint Complete**: Yes
- **Checkpoint Target**: complete
- **Route Status Reason**: complete
- **Route Frames Run**: 22874 / 42000
- **Telemetry HUD**: Telemetry: complete 381.2s | Contact 100% | Loss 1 | Dist 2.57 | Spin 1.0 | Effort 246.06m 140.4s | Push PROCEED | Burden PROCEED | Slice PROCEED
- **Trail Points**: 539
- **Response Points**: 539
- **Hum Clarity**: 0.80
- **Generated Hum Stream**: Yes
- **Route Smoke Teleports After Start**: 0
- **Route Smoke Max Lateral Offset**: 1.36
- **Route Smoke Bias Recovered**: Yes
- **Push Lab Bias Gate**: SKIPPED
- **Push Lab Bias Gate Reason**: bounded representative diagnostic

## Scope Note
This is an automated baseline for the first loop ending at `complete`, not a substitute for a human 5-10 minute feel test. The next chapter transition is intentionally unresolved and should not be simulated by looping another same-scene push.