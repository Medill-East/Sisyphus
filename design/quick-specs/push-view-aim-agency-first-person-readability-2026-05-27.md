# Quick Design Spec: Push View Aim Agency and First-Person Readability

**Type**: Tweak
**System**: Push Camera / First-Person Hands / Contact Physics
**GDD Reference**: `design/gdd/game-concept.md`
**Date**: 2026-05-27

## Change Summary

Push view must feel like the player can deliberately choose a boulder pressure point with the center of the screen. The first-person hands should read as short foreground hands/forearms pressing the stone, not tiny distant rods or stretched transition arms.

## Motivation

Play feedback says the player still cannot judge where they are pushing: hand scale is strange during the third-person to first-person blend, the hand can look like it enters the stone, the look range feels hard to interpret, and the resulting push direction does not feel intentional.

## Design Delta

Current GDD says (`design/gdd/game-concept.md`, Core Loop):

> The camera aim determines hand contact placement and lateral force bias.

This spec changes the implementation rule to:

The rendered push camera ray, hand contact targets, contact cue, and applied contact force must resolve from the same selected stone surface point. The player should keep a readable center reticle, visible foreground hands, enough left/right peripheral route cues, and enough downward pitch to inspect the hands and pressure point.

## New Rules / Values

1. Live push solving uses a refined reticle ray from the actual push-camera origin, not only a body-locked approximation.
2. Push FOV must stay wide enough for peripheral route cues but below fisheye levels that make direction judgment unreliable.
3. First-person palms must be visually broader than the forearms and large enough to read as hands in the foreground.
4. Hand and forearm centers must remain outside the boulder shell during high/side/down contact.
5. Mouse/trackpad look in push view must allow deliberate left/right bias and downward contact inspection while still clamping full free-look.

## Affected Systems

| System | Impact | Action Required |
|--------|--------|-----------------|
| Player Controller | Live reticle contact solves from refined push camera origin | Update `PlayerController.gd` |
| Push Lab | Automated lab camera and physics use the same refined solve | Update `PushLab.gd` |
| First-Person Hands | Increase readable hand scale and keep short forearm cuffs | Update `FirstPersonHands.tscn` / `FirstPersonHandsController.gd` |
| Tuning | Reduce fisheye FOV and move push camera closer to contact | Update `Tuning.gd` |
| Tests | Cover refined reticle solve, readable hand scale, and push look range | Update Godot tests |

## Acceptance Criteria

- [ ] The refined push-camera ray and the applied contact point stay within a small tolerance after left/high or right/down aim.
- [ ] Push camera FOV is wide but not fisheye.
- [ ] First-person palms are large enough to read in foreground and remain broader than forearms.
- [ ] High/side/down aim keeps palms and forearms outside the stone.
- [ ] Push look can bias left/right and look down far enough to inspect the contact while preserving peripheral route cues.

## GDD Update Required?

No. This is an implementation clarification of the existing camera-aim/contact rule.
