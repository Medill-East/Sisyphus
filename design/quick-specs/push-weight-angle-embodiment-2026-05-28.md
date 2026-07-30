# Quick Design Spec: Push Weight, Angle Mastery, And Embodied Contact

**Type**: Tweak
**System**: Push Camera / First-Person Hands / Contact Physics / Visual Feedback
**GDD Reference**: `design/gdd/game-concept.md`
**Date**: 2026-05-28

## Change Summary

The push loop must validate the actual game premise: a human body slowly leans into a massive stone, finds a usable pressure angle, and pays for mistakes through stall or rollback. The player should not feel that they are teleported into floating hands or that holding `W` drives a hidden motor uphill.

## Motivation

Latest play feedback says the first-person transition still feels abrupt, hands read as detached, visual markers are hard to understand, and the stone does not yet feel like a truly heavy object that punishes wrong pressure angles. The reference games are `Getting Over It with Bennett Foddy` and `Baby Steps`: difficult physical mastery, not convenience transport.

## Design Delta

Current implementation already tests reticle/contact/aim coherence. This spec adds a stricter human-facing requirement:

The player must be able to learn that different pressure points have different physical outcomes. A centered/sweet angle should produce slow progress. Bad high/side pressure should weaken contact, drift, stall, or roll back. Releasing `W` must let the stone behave like a weighted object on a slope.

## New Rules

1. Approach must read as embodied contact: body closes distance, hands reach/settle, then the camera narrows. First-person hands should never be the first readable body cue.
2. First-person view must include enough shoulder/chest/forearm context to avoid floating-hand read.
3. Push input is sustained effort, not a motor. If `W` is released or contact is bad, the stone must not continue climbing under script-like assistance.
4. Correct pressure angle and bad pressure angle must be distinguishable by outcome and by feedback.
5. Left/right aim must be judged from player screen-space perception, not only world-space force sign.
6. Non-HUD pressure, route, and trail cues must be visually self-explanatory or muted enough not to read as debug clutter.

## Affected Systems

| System | Impact | Action Required |
|--------|--------|-----------------|
| Player Controller | Approach and push-camera transition need stronger embodied timing | Tune/update `PlayerController.gd` only after gate failure is reproduced |
| First-Person Hands | Hands need body/forearm context and no floating-hand takeover | Tune/update `FirstPersonHandsController.gd` |
| Push Controller | Wrong pressure angles must fail or roll back without breaking valid sweet spot | Preserve contact-force tests and angle-mastery diagnostics |
| PushLab | Diagnostic must include sweet spot vs bad pressure evidence | Keep `evaluate_angle_mastery_drill()` as a preflight gate |
| QA Reports | Human gate must explicitly cover embodiment, angle mastery, rollback, and visual cue clarity | Update report builder, validator, worksheet, and packet |

## Acceptance Criteria

- [ ] `Embodied approach` is `Yes` in a filled human representative report.
- [ ] `Pressure angle mastery` is `Yes`: players can tell that correct pressure progresses while bad high/side pressure fails.
- [ ] `Rollback honesty` is `Yes`: release or bad contact lets the stone stall or roll downhill naturally.
- [ ] `Visual cue clarity` is `Yes`: pressure marks, route markers, and descent response no longer read as unexplained debug artifacts.
- [ ] Objective Push/Burden/Slice gates remain `PROCEED` for a representative run.
- [ ] A human `PROCEED` remains impossible unless every push-feel retest row is filled `Yes`.

## GDD Update Required?

Not yet. This is a gate refinement for the existing `Weight Must Be Honest` pillar. If the next human playtest confirms the direction, fold it into the GDD push-view/control section.
