# Quick Design Spec: Chapter I End Boundary

**Type**: Tweak
**System**: Ascent/Release/Descent Loop
**GDD Reference**: `design/gdd/game-concept.md`; `design/gdd/systems-index.md`
**Date**: 2026-05-26

## Change Summary

The first vertical-slice loop ends when the player has pushed the stone over the ridge, descended the back side, and returned to the fallen stone. The prototype must hold on a `complete / Chapter I End` state instead of starting another same-scene push loop as a placeholder for Chapter II.

## Motivation

The end of the first loop is a chapter boundary, not a repeatable sandbox reset. Letting the player immediately continue pushing in the same scene would make the unresolved transition look like missing implementation and would weaken the emotional contrast between punishment, descent, and the next divine intervention.

## Design Delta

Current GDD says in `design/gdd/game-concept.md`, Edge Cases:

> If the player completes a level slowly, the game should still allow completion but with reduced descent reward.

Current systems index says in `design/gdd/systems-index.md`, Foundation Layer:

> Gameplay State Machine — tracks approach, ascent, release, descent, complete, and level transitions.

This spec clarifies the vertical-slice rule:

The `complete` phase is the end of Chapter I for the current slice. It is not a short pause before another local push attempt. Any next push belongs to Chapter II or another transition beat, which remains intentionally unresolved until the transition design is written.

## New Rules / Values

1. Chapter I begins at the front-base approach and covers exactly one push cycle: approach, ascent, ridge release, back-slope descent, return to the stone.
2. Completion requires the player to return near the rolled stone on the back side, not merely reach the back foot of the mountain.
3. On completion, player movement and push engagement are disabled until a future transition system takes over.
4. The camera should leave the first-person push state and hold a reflective composition around the player, stone, path, storm pressure, and light crack.
5. The HUD/report language must identify this as `Chapter I End` or equivalent chapter-end evidence.
6. The prototype must not simulate Chapter II by allowing a same-scene back-side re-push, auto-reset, or loop restart.
7. A valid playtest can end at this hold state. The tester should record whether the ending feels like a deliberate unresolved transition.

## Affected Systems

| System | Impact | Action Required |
|--------|--------|-----------------|
| Gameplay State Machine | `complete` becomes a chapter-end hold state for the slice | Already implemented; keep regression tests |
| Player Body and Push Controller | No input-driven re-push after `complete` | Already implemented; keep regression tests |
| Push Camera and First-Person Hands | Blend out of push view at `complete` | Already implemented; keep visual tests |
| Playtest Reporting | Reports must distinguish Chapter I ending from missing Chapter II | Already implemented; keep F9 capture tests |
| Level Progression | Chapter II transition remains TODO | Defer to future transition design |

## Acceptance Criteria

- [ ] `GameState` reaches `complete` only after back-side return to the rolled stone.
- [ ] `complete` clears push engagement and prevents same-scene movement/push continuation.
- [ ] The prompt at `complete` does not instruct the player to push again.
- [ ] F9/manual reports include Chapter End Evidence and state that the next punishment is pending.
- [ ] Automated route reports describe `complete` as the first-loop ending and explicitly do not treat another same-scene push as transition evidence.
- [ ] Manual representative playtests stop at `complete / Chapter I End` and record whether the unresolved transition reads as intentional.
- [ ] No regression: the stone still physically crosses the ridge, rolls down the back slope, and can be reached by the player before `complete`.

## GDD Update Required?

No immediate GDD edit. This is a vertical-slice boundary clarification that already fits the existing `complete` and level-transition concepts. A future Chapter II transition design should update the level progression GDD once the transition form is chosen.
