# Quick Design Spec: Two-Hand Push, Gamepad-First, Look/Force Decoupling

**Type**: Core Mechanic Rework
**System**: Push Controller / Player Controller / First-Person Hands / Input Map / Audio / Haptics
**GDD Reference**: `design/gdd/game-pillars.md` (Pillar 1: Weight Must Be Honest)
**Supersedes (input scheme only)**: `design/quick-specs/push-weight-angle-embodiment-2026-05-28.md`
**Date**: 2026-07-31

## Change Summary

Replace the single `push` action with **two independent, analog per-hand push inputs**, and **decouple look direction from force direction**. The ascent becomes a continuous two-handed balancing act instead of a "hold W while aiming" motor.

## Motivation

Push feel has resisted two months of parameter tuning. Objective diagnostics (`push_intent_diagnostic`: contact_delta / force_delta / drift_gap) pass while the stone still reads as light and the player still reads as disembodied. Parameter tuning cannot fix this because the defect is in the **control topology**, not the values:

**The mouse currently does two mutually exclusive jobs at once** — it決定 what the player *sees* and where the force *goes*. Pressed against a view-filling boulder, the player must choose between aiming force and retaining visual information, and can never do both. The player therefore never has a body they directly command; they command an abstraction ("push toward where I look") and the physics result is unattributable.

All three stated reference games separate these channels:

| Game | Directly controlled body | Camera |
|---|---|---|
| Getting Over It | mouse = hammer position (1:1) | automatic |
| Baby Steps | each trigger = one leg | right stick, independent |
| Death Stranding | L2/R2 = balance correction | right stick, independent |
| 西西弗斯 (current) | mouse = force **and** camera | same input — coupled |

## Design Delta

Each hand becomes a separately commanded limb. Force is applied at an **off-center contact point**, so a single-hand push produces torque and the stone **veers away from the pushing hand** (left hand → stone drifts right; cf. paddling a canoe on one side, or pushing a shopping cart one-handed). Straight-line ascent therefore requires **unceasing left/right negotiation**.

This is the mechanical translation of the myth: the punishment is not that it is hard, it is that **you may never let go**. It also sets up the descent contrast correctly — the release is not "hard → easy", it is **you can finally put your hands down**.

Because both hands are occupied, the **mouth is free** — the humming system (`HummingController.gd`) now occupies a channel that labor cannot take away.

## Platform Decision

**Gamepad is the primary input device.** Analog triggers are load-bearing: the player must be able to express "30% left hand / 70% right hand". Mouse is an explicitly degraded fallback where each button = full force (1.0), binary.

This decision propagates to onboarding, input prompts, and store-page input labelling. It is a product decision, already accepted by 無涘 (2026-07-31).

## New Rules

1. `push_left` and `push_right` replace the single `push` action.
   - Gamepad: LT / RT, **analog** — read via `Input.get_action_strength()`, not `is_action_pressed()`.
   - Mouse: left / right button, binary → strength 1.0.
2. Each hand applies force at its own contact point, laterally offset from the stone's center of mass. Off-center force must produce real torque — **do not** fake it by steering the stone.
3. Single-hand push must visibly veer the stone **away from that hand**. This is the primary source of difficulty and must not be dampened away.
4. Force direction is derived from **body facing + contact geometry**, NOT from look direction. Moving the camera must not change where the force goes.
5. Look (right stick / mouse move) is free at all times, including mid-push.
6. Releasing both triggers must let the stone stall or roll back honestly (preserves rule 3 of the 2026-05-28 spec).
7. Vision remains blocked by the stone during ascent. **This is intended (Pillar 1) and must not be "fixed".** Instead, state must be legible through non-visual channels:
   - per-hand load and slip surfaced through controller rumble (left/right independent)
   - per-side scraping audio tracking each hand's load
   - breath/strain tracking combined load
8. `move_left` / `move_right` retain footwork only; they must not become a force-steering input (that would re-introduce the coupling this spec removes).

## Affected Systems

| System | Action Required |
|---|---|
| Input Map (`project.godot`) | Add `push_left` / `push_right` with gamepad trigger + mouse button events; retire single `push` |
| `PushController.gd` | Per-hand contact points, per-hand analog force, real torque from offset |
| `PlayerController.gd` | Stop deriving force direction from look; keep footwork on `move_left/right` |
| `FirstPersonHandsController.gd` | Each hand animates against its own trigger strength; hands must read as loaded, not floating |
| `HummingController.gd` | Confirm humming remains available while both hands are engaged |
| Haptics (new or existing) | Independent left/right rumble tracking per-hand load and slip |
| Audio | Per-side scraping tied to per-hand load |
| `PushLab.tscn` / `PushLab.gd` | Diagnostic must measure two-hand behaviour (see criteria) |
| Tests | `test_push_physics.gd`, `test_contact_push_physics.gd`, `test_push_lab*.gd` updated for two inputs |

## Acceptance Criteria

- [ ] Holding **only** `push_left` makes the stone visibly veer right; only `push_right` veers left. Verified in `PushLab` and asserted in an automated test.
- [ ] Alternating / balancing both triggers can hold the stone on a straight uphill line.
- [ ] Analog is real: `0.3 left + 0.7 right` produces a measurably different trajectory from `1.0 + 1.0`. Asserted in a test.
- [ ] Camera can be swept fully left/right mid-push **without** changing force direction. Asserted in a test.
- [ ] Releasing both triggers → stone stalls or rolls back; no scripted assistance.
- [ ] Rumble and per-side audio differ measurably between "left hand loaded" and "right hand loaded".
- [ ] Existing Push / Burden / Slice objective gates remain `PROCEED` for a representative run.
- [ ] Ascent view remains blocked by the stone — no FOV/camera "fix" was introduced to compensate.

## Explicit Non-Goals

- ❌ Do not tune for "good feel" — that is 無涘's judgement call after this lands. Ship the topology, not the polish.
- ❌ Do not add HUD indicators for hand load. Feedback goes to rumble/audio/hand animation.
- ❌ Do not widen FOV, shrink the stone, or add a peek camera to compensate for blocked vision.
- ❌ Do not touch descent, weather, humming progression, or level content.
- ❌ Do not rebuild the old web prototype.

## Note for the implementing agent

If you conclude the range must be widened to complete this, **stop and report the reason** rather than expanding scope. The single most important outcome is criterion 1 + 4: one hand veers the stone away from itself, and looking around never moves the force.
