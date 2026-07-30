# User Feedback: Push Weight, Angle Mastery, And Embodiment

- Date: 2026-05-28
- Source: direct user playtest feedback in Codex thread
- Scope: Godot PushLab / representative vertical-slice push feel
- Milestone gate status: qualitative PIVOT input only; this is not a filled `playtest-*.md` Human Feel Gate report.

## Observed Issues

- Approaching the boulder still reads like a sudden camera/view-mode switch instead of a person leaning in and placing hands on the stone.
- First-person hands can read as detached/floating hands. The intended read is an embodied human: body approaches, hands settle on the boulder, then the camera closes in.
- Some non-HUD visual objects read as unexplained colored debug clutter instead of pressure, route, or world-change feedback.
- The current push still does not communicate enough weight. Holding `W` can feel like a motorized forward drive instead of repeated high-effort pressure.
- The core play should be finding a usable pressure angle. A correct angle should make slow progress; a wrong high/side angle should slip, stall, or roll the stone back.
- Releasing `W` or losing contact should let the stone stall or roll downhill under gravity; it should not stick in place or continue uphill.
- Left/right control still risks feeling inverted or illegible from the player's screen-space point of view.
- Route progress can read as endless if the mountain/path destination and remaining distance are not visible enough.
- Descent trail/environment response can read as unexplained clutter if its meaning is not legible in the scene.

## Design Interpretation

This feedback reinforces Pillar 1: `Weight Must Be Honest`. The push loop should be closer to `Getting Over It` / `Baby Steps` difficulty: not punitive for its own sake, but hard because the player must learn physical leverage, contact, recovery, and terrain reading.

The next valid `PROCEED` requires both objective telemetry and human confirmation that:

- hand placement is embodied rather than floating;
- pressure-point selection feels intentional;
- correct/incorrect force angles produce different outcomes;
- rollback on release/mistake feels physical;
- visual cues explain pressure, route, and descent transformation without looking like debug artifacts.

## Follow-Up Required

- Update the representative human playtest gate so `Pressure angle mastery`, `Rollback honesty`, `Embodied approach`, and `Visual cue clarity` are explicit pass/fail rows.
- Keep automated push-lab diagnostics, but do not treat them as sufficient until human notes confirm the hand/weight/angle read.
- Prefer core push/camera/hand iteration over content expansion, export work, or additional chapters until this gate passes.
