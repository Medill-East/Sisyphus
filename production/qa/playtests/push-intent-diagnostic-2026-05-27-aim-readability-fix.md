# Push Intent Diagnostic

- **Purpose**: Short core-feel check for whether the player can intentionally choose hand contact and push direction.
- **Verdict**: PROCEED
- **Contact Delta**: 0.80
- **Force Delta**: 88.03
- **Real Drift Gap**: 1.27
- **Left Route Visible**: Yes
- **Right Route Visible**: Yes
- **Look Down Readable**: Yes
- **Disengaged Cleanly**: Yes
- **Hand Surface Clear**: Yes

## Snapshots
- **approach**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-2026-05-27-aim-readability-fix-approach.png`
- **center_push**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-2026-05-27-aim-readability-fix-center_push.png`
- **left_high**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-2026-05-27-aim-readability-fix-left_high.png`
- **right_high**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-2026-05-27-aim-readability-fix-right_high.png`
- **look_down**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-2026-05-27-aim-readability-fix-look_down.png`
- **disengage**: `/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/push-intent-diagnostic-2026-05-27-aim-readability-fix-disengage.png`

## Aim Drill
- **Success**: Yes
- **Status**: ok
- **Drift Gap**: 1.27

## Decision Use
- `PROCEED`: use this as short evidence that the next representative human run is worth doing.
- `PIVOT`: tune hand/contact/camera before spending time on a 5-10 minute representative playtest.
- This diagnostic does not replace a filled `Human Feel Gate` report.
