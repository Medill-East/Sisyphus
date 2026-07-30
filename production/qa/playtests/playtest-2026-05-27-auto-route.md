# Playtest Report

## Session Info
- **Date**: 2026-05-27
- **Build**: local-godot-auto-route
- **Duration**: 51.5s
- **Tester**: auto-route-current
- **Platform**: macOS
- **Input Method**: Automated route driver
- **Session Type**: Automated baseline
- **Pacing Profile**: smoke
- **Estimated Pacing Loop**: 95.7s

## Test Focus
Sisyphus Downhill Vertical Slice: front-base push route, ridge release, back-slope descent, return to the stone, first-loop ending, and telemetry gate.

## First Impressions (First 5 minutes)
- **Understood the goal?** [Yes/No/Partially]
- **Understood the controls?** [Yes/No/Partially]
- **Emotional response**: [Engaged/Confused/Bored/Frustrated/Excited]
- **Notes**: [Observations]

## Quantitative Data
Push Gate: PROCEED | Burden Gate: PROCEED | Slice Gate: PIVOT | Contact: 100% | Loss: 1 | Dist: 2.57 | Spin: 2.0
- **Push Gate**: PROCEED
- **Push Gate Reason**: stable contact and coupled rolling
- **Burden Gate**: PROCEED
- **Burden Gate Reason**: measurable labor and controlled uphill work
- **Slice Gate**: PIVOT
- **Slice Gate Reason**: too short for representative 5-10 minute loop
- **Contact**: 100%
- **Contact Losses**: 1
- **Max Player-Stone Distance**: 2.57
- **Max Spin Ratio**: 2.0
- **Phase At End**: complete
- **Uphill Push Distance**: 37.15m
- **Average Push Uphill Speed**: 0.80m/s
- **Minimum Push Uphill Speed**: 0.01m/s
- **Slow Push Duration**: 17.2s
- **Environment Response Layers**: Scar 84 | Water 1 | Flower 41 | Grass 42
- **Descent World Change Signal**: pushed trail changed the world through layered scar/water/flower/grass response.
- **Push Lab Bias Gate**: PROCEED
- **Push Lab Bias Gate Reason**: left/right bias recovery passed
- **Push Lab Left Bias**: pass | Air 0.10 | Recovery 0.60 | Spin 7.9
- **Push Lab Right Bias**: pass | Air 0.08 | Recovery 4.81 | Spin 1.8
- **Approach Duration**: 0.2s
- **Ascent Duration**: 46.3s
- **Release Duration**: 0.2s
- **Descent Duration**: 4.8s
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
- Do not treat this as a full vertical slice yet; build or validate a representative 5-10 minute loop: too short for representative 5-10 minute loop.

### Balance adjustments
- Keep push baseline for now; next tune route length, descent pacing, and emotional contrast: too short for representative 5-10 minute loop.

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
1. Build or validate a representative 5-10 minute loop before calling this vertical slice ready.
2. Preserve current push-contact baseline while extending route/descent pacing: too short for representative 5-10 minute loop.
3. Validate whether the generated hum improves the descent contrast or needs audio direction.

## Automated Evidence
- **Final Phase**: complete
- **Pacing Profile**: smoke
- **Route Checkpoint**: front
- **Estimated Pacing Loop**: 95.7s
- **Route Complete**: Yes
- **Checkpoint Complete**: Yes
- **Checkpoint Target**: complete
- **Route Status Reason**: complete
- **Route Frames Run**: 3093 / 9000
- **Telemetry HUD**: Telemetry: complete 51.5s | Contact 100% | Loss 1 | Dist 2.57 | Spin 2.0 | Effort 37.15m 17.2s | Push PROCEED | Burden PROCEED | Slice PIVOT
- **Trail Points**: 84
- **Response Points**: 168
- **Response Layer Counts**: { "scar": 84, "water": 1, "grass": 42, "flower": 41 }
- **Hum Clarity**: 0.80
- **Generated Hum Stream**: Yes
- **Route Smoke Teleports After Start**: 0
- **Route Smoke Max Lateral Offset**: 2.44
- **Route Smoke Bias Recovered**: Yes
- **Push Lab Bias Gate**: PROCEED
- **Push Lab Bias Gate Reason**: left/right bias recovery passed

## Scope Note
This is an automated baseline for the first loop ending at `complete`, not a substitute for a human 5-10 minute feel test. The next chapter transition is intentionally unresolved and should not be simulated by looping another same-scene push.