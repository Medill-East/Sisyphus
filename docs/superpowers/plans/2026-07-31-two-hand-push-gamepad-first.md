# Two-Hand Push, Gamepad-First Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the camera-steered single push with independent analog left/right hand forces applied at off-center stone contacts.

**Architecture:** `PlayerController` owns input sampling and a body-facing direction that is independent of camera look. `PushController` calculates and applies two physical forces, preserving aggregate compatibility fields for diagnostics while exposing per-hand contacts, forces, loads, torque, scrape, and haptic levels. `PushLab` and headless tests exercise the new topology directly.

**Tech Stack:** Godot 4.6.2, GDScript, RigidBody3D force application, headless SceneTree tests.

---

### Task 1: Lock the topology with failing numerical tests

**Files:**
- Create: `godot/tests/test_two_hand_push.gd`

- [ ] Add one deterministic simulation harness around `PushController.calculate_two_hand_push_frame`.
- [ ] Assert left-only/right-only lateral polarity and non-zero off-center torque.
- [ ] Assert asymmetric analog input and full symmetric input produce different endpoints.
- [ ] Assert two widely separated camera directions produce identical per-hand force vectors.
- [ ] Assert zero trigger strength yields zero contact force and no post-release scripted acceleration.
- [ ] Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_two_hand_push.gd
```

Expected before implementation: FAIL because `calculate_two_hand_push_frame` is absent.

### Task 2: Add gamepad-first input mapping

**Files:**
- Modify: `godot/project.godot`

- [ ] Remove the legacy `push` action.
- [ ] Add `push_left` with left trigger axis and mouse left button.
- [ ] Add `push_right` with right trigger axis and mouse right button.
- [ ] Keep `move_left` and `move_right` unchanged as footwork.

### Task 3: Implement independent off-center hand forces

**Files:**
- Modify: `godot/scripts/PushController.gd`

- [ ] Extend `PushFrame` with per-hand contact, force, strength, torque, load, scrape, and haptic fields.
- [ ] Add `calculate_two_hand_push_frame` using body facing plus fixed per-hand contact geometry; camera direction may be retained only as visual metadata.
- [ ] Make left contact produce rightward force and right contact produce leftward force while both offsets create real torque.
- [ ] Add `apply_two_hand_push`, calling `RigidBody3D.apply_force` once per active hand with that hand's offset.
- [ ] Preserve the old aggregate frame fields as sums/weighted representatives so debug and gate code can migrate without a wholesale rewrite.
- [ ] Keep release behavior limited to existing rolling resistance; do not add climb assistance.

### Task 4: Wire input, body direction, hands, haptics, and audio

**Files:**
- Modify: `godot/scripts/PlayerController.gd`
- Modify: `godot/scripts/FirstPersonHandsController.gd`

- [ ] Sample both actions with `Input.get_action_strength`.
- [ ] Engage when either strength is non-zero; derive force direction from player-to-stone body geometry.
- [ ] Remove camera aim and A/D from force steering; retain A/D only in body movement.
- [ ] Pass each strength to `PushController.apply_two_hand_push`.
- [ ] Animate each hand's compression from its own load.
- [ ] Map left/right load to the two gamepad vibration motor channels.
- [ ] Run two panned looping scrape sources and drive each volume from its own hand load/slip value.

### Task 5: Update diagnostics and compatibility assertions

**Files:**
- Modify: `godot/scripts/PushLab.gd`
- Modify: `godot/scenes/PushLab.tscn`
- Modify: `godot/scripts/Main.gd`
- Modify: `godot/tests/test_game_logic.gd`
- Modify: `godot/tests/test_push_physics.gd`
- Modify: `godot/tests/test_player_behavior.gd`
- Modify: `godot/tests/test_contact_push_physics.gd`
- Modify relevant `godot/tests/test_push_lab*.gd` only where old camera-steering assertions conflict with the superseding spec.

- [ ] Add a two-hand topology diagnostic to PushLab and update controls copy.
- [ ] Replace old reticle-steers-force assertions with body-force/camera-decoupling assertions.
- [ ] Keep objective gate calculations on aggregate force and physical trajectory.
- [ ] Run the focused two-hand test until GREEN, then the existing push/contact/player suites.

### Task 6: Verify, adversarially review, and journal

**Files:**
- Create: `docs/journal/2026-07-31-two-hand-push-summary.md`
- Create: `docs/journal/2026-07-31-two-hand-push-transcript.md`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md` if present.

- [ ] Run all four required project tests.
- [ ] Run the new two-hand test and relevant PushLab/gate tests.
- [ ] Inspect the diff for forbidden camera/FOV/stone/descent/weather/humming/content changes.
- [ ] Record exact results, autonomous choices, and any remaining human feel acceptance.
- [ ] Secret-scan journal artifacts without printing values.

