# Quick Design Spec: Push View Reticle-Camera Coherence

**Type**: Tweak
**System**: Push Camera / Hand Contact / Stone Physics
**GDD Reference**: `design/gdd/game-concept.md`
**Date**: 2026-05-27

## Change Summary

Push view must make the center reference, visible hands, pressure cue, and actual force come from the same selected boulder surface point. The camera should orbit around that selected contact target, not only around the player body, so the player can judge where they are pushing and how the stone will drift.

## Motivation

Recent play feedback says the player still cannot reliably choose a specific push point: the third-person/first-person transition can read as strange arms, the hands/force cue can look detached, the player cannot judge left/right/down aim well enough, and the resulting push does not feel intentional.

## Design Delta

Current GDD says (`design/gdd/game-concept.md`, Core Loop):

> The camera aim determines hand contact placement and lateral force bias.

This spec changes that to:

The reticle-selected boulder surface point is the shared source for the push camera target, first-person hand targets, pressure cue, and contact force. During push view, the camera origin moves relative to that selected contact point so the player sees a stable center reference, peripheral route anchors, and enough downward/side view to judge the environment.

## New Rules / Values

1. `push_camera_origin_for()` must use the selected `contact_target`; changing contact target left/right/up/down must move the camera origin enough to preserve a stable reticle-contact relationship.
2. Live push solving must use a two-pass reticle solve: approximate camera origin, calculate contact point, then refine the camera origin from that contact point before applying force.
3. The normal pressure cue should read as a short contact/force hint, not a long debug vector or detached arm. Long vectors remain a debug overlay concern.
4. First-person hands must remain outside the boulder surface and close enough to the selected pressure point that the player can read them as pressing, not floating.
5. Push view must preserve peripheral route-edge markers while allowing look-down contact inspection.

## Affected Systems

| System | Impact | Action Required |
|--------|--------|-----------------|
| Player Camera | Push origin uses selected contact point | Update `PlayerController.gd` |
| PushLab | Lab evidence must use same two-pass solve | Update `PushLab.gd` |
| Vertical Slice Visual Modes | Real scene status must match lab solve | Update `VerticalSlice.gd` |
| Contact Cue | Normal cue shortened | Update `ContactCue.gd` |
| Tests | Stronger regression gates | Update push/camera tests |

## Acceptance Criteria

- [ ] Left/right contact targets produce different push camera origins.
- [ ] Camera-to-contact distance stays near the tuning value in full push blend.
- [ ] Live push frame reticle ray aligns with the selected contact point after the refined solve.
- [ ] First-person hands remain visible, outside the stone, and close to the contact point.
- [ ] Normal contact cue force length stays short enough not to read as an arm/debug vector.
- [ ] No regression: route-edge peripheral visibility remains present in push view.

## GDD Update Required?

No. This is a clarification of the already documented rule that camera aim determines contact placement and lateral force bias.
