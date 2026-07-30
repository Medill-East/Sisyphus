# Playtest Report

## Session Info
- **Date**: 2026-05-27
- **Build**: local-godot-auto-route
- **Duration**: 381.4s
- **Tester**: auto-route-representative-full-current
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
Push Gate: PROCEED | Burden Gate: PROCEED | Slice Gate: PROCEED | Contact: 100% | Loss: 1 | Dist: 2.57 | Spin: 1.7
- **Push Gate**: PROCEED
- **Push Gate Reason**: stable contact and coupled rolling
- **Burden Gate**: PROCEED
- **Burden Gate Reason**: measurable labor and controlled uphill work
- **Slice Gate**: PROCEED
- **Slice Gate Reason**: representative 5-10 minute complete loop
- **Contact**: 100%
- **Contact Losses**: 1
- **Max Player-Stone Distance**: 2.57
- **Max Spin Ratio**: 1.7
- **Phase At End**: complete
- **Uphill Push Distance**: 246.06m
- **Average Push Uphill Speed**: 0.86m/s
- **Minimum Push Uphill Speed**: 0.01m/s
- **Slow Push Duration**: 140.4s
- **Environment Response Layers**: Scar 539 | Water 1 | Flower 269 | Grass 269
- **Descent World Change Signal**: pushed trail changed the world through layered scar/water/flower/grass response.
- **Push Lab Bias Gate**: SKIPPED
- **Push Lab Bias Gate Reason**: bounded representative diagnostic
- **Approach Duration**: 0.2s
- **Ascent Duration**: 286.3s
- **Release Duration**: 0.4s
- **Descent Duration**: 94.5s
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

## Push-Feel Retest Focus
| Check | Pass? | Notes |
|-------|-------|-------|
| Transition sanity: approaching and entering push view does not show long or detached arms. | [Yes/No] | [Notes] |
| Hand surface: palms stay visually outside the boulder while the contact cue sits on the pressure point. | [Yes/No] | [Notes] |
| Look-down check: while pushing, the player can look down enough to inspect hands/contact and then recover forward view. | [Yes/No] | [Notes] |
| Peripheral read: while biased left/right, the player can still judge route edges and nearby obstacles from the push view. | [Yes/No] | [Notes] |
| Reticle surface targeting: the center reticle/pressure cue lets the player choose a specific boulder surface point without the hands sinking into it. | [Yes/No] | [Notes] |
| Aim bias retest: looking left/right changes hand contact and the stone's rolling direction in a way the player can intentionally use. | [Yes/No] | [Notes] |
| Disengage/re-engage: releasing W or backing away returns camera/arms cleanly, and the player can approach the stone again. | [Yes/No] | [Notes] |

## Human Feel Gate
- **Burden reads as physical labor?**: [Yes/No/Partially]
- **Camera pressure is intense but playable?**: [Yes/No/Partially]
- **Aim changes hand contact and push direction?**: [Yes/No/Partially]
- **Release/descent contrast is clear?**: [Yes/No/Partially]
- **Chapter I End reads as intentional, not unfinished?**: [Yes/No/Partially]
- **Human Verdict**: [PROCEED/PIVOT/KILL]
- **Verdict Reason**: [One sentence]

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
- **Route Frames Run**: 22884 / 42000
- **Telemetry HUD**: Telemetry: complete 381.4s | Contact 100% | Loss 1 | Dist 2.57 | Spin 1.7 | Effort 246.06m 140.4s | Push PROCEED | Burden PROCEED | Slice PROCEED
- **Trail Points**: 539
- **Response Points**: 1078
- **Response Layer Counts**: { "scar": 539, "water": 1, "grass": 269, "flower": 269 }
- **Hum Clarity**: 0.80
- **Generated Hum Stream**: Yes
- **Route Smoke Teleports After Start**: 0
- **Route Smoke Max Lateral Offset**: 1.26
- **Route Smoke Bias Recovered**: Yes
- **Push Lab Bias Gate**: SKIPPED
- **Push Lab Bias Gate Reason**: bounded representative diagnostic

## Scope Note
This is an automated baseline for the first loop ending at `complete`, not a substitute for a human 5-10 minute feel test. The next chapter transition is intentionally unresolved and should not be simulated by looping another same-scene push.