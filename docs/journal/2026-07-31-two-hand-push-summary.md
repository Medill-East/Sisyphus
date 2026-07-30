# 2026-07-31 Two-Hand Push Implementation Summary

Transcript evidence: [2026-07-31-two-hand-push-transcript.md](2026-07-31-two-hand-push-transcript.md)

## Current state

- `push_left` and `push_right` are the only push InputMap actions.
- LT/RT are analog primary inputs; mouse left/right are binary full-force fallbacks.
- `PushController.calculate_two_hand_push_frame()` computes two off-center contacts and independent forces.
- `PushController.apply_two_hand_push()` calls `RigidBody3D.apply_force()` once per active hand.
- Camera direction is visual metadata only; body-to-stone facing and hand contact geometry determine force.
- Per-hand load drives first-person palm compression, two spatial scrape sources, and the two vibration motor channels.
- The four required project tests and focused two-hand/feedback/contact/PushLab tests pass with exit code 0.
- The legacy representative full-route/Slice gate is not green: route physics cannot complete the existing obstacle route with its old camera-steering automation, and the human evidence gate remains `PIVOT` because no filled Human Feel report exists.

## Decisions and reasons

1. **Per-hand force shares are normalized by total trigger strength.**
   - Formula: `1 / max(1, left + right)`.
   - This gives a full-strength single hand enough authority to veer while keeping two full triggers inside the existing total force ceiling.
2. **Lateral inward force is derived from hand contact geometry.**
   - The ratio uses hand surface spread divided by rear surface component, instead of an unrelated steering constant.
   - This keeps force attributable to the physical contact and produces real `offset × force` torque.
3. **Camera-reticle compatibility wrappers remain, but no longer steer force.**
   - Existing diagnostics can migrate incrementally without preserving the superseded coupling.
4. **Old aim-angle PushLab gates were removed from the active test list.**
   - They asserted behavior explicitly superseded by the 2026-07-31 quick spec.
   - New `evaluate_two_hand_topology()` covers hand polarity, balance, torque, and camera decoupling.
5. **No FOV, stone size, peek camera, descent, weather, humming progression, level content, or web prototype changes were made.**

## Changes and verification

- Input mapping: `godot/project.godot`.
- Physics and topology: `godot/scripts/PushController.gd`.
- Runtime input/body direction/feedback: `godot/scripts/PlayerController.gd`.
- Per-hand visuals: `godot/scripts/FirstPersonHandsController.gd`.
- Scrape players: `godot/scenes/Player.tscn`.
- PushLab diagnostic/copy: `godot/scripts/PushLab.gd`, `godot/scenes/PushLab.tscn`.
- Onboarding/telemetry input query: `godot/scripts/Main.gd`, `godot/scripts/VerticalSlice.gd`.
- Tests: two new focused suites plus migration of superseded camera-steering assertions.

Focused numerical evidence:

- Left-only end x `+5.128`; right-only end x `-5.115`.
- Left/right single-hand torque magnitudes `14.560` / `13.967`.
- `0.3/0.7` versus `1.0/1.0` endpoint gap `2.048`.
- Camera sweep force delta `0.000000`.
- Released contact force `0.000000`; post-release uphill gain `-3.129` (rollback).
- Feedback left-loaded dB `(-19.2, -52.8)` and right-loaded dB `(-55.2, -16.8)`.

All test runs print a pre-existing Godot AI addon error from `addons/godot_ai/runtime/game_logger.gd` about missing `McpLogBacktrace`. The requested project tests still exit 0. The specified `/Applications/Godot.app` identifies itself as Godot `4.7.1`, not the requested 4.6; implementation uses 4.6-compatible APIs.

## Incident lessons

- The old route smoke used camera bias as steering. Once look and force were correctly decoupled, that automation could no longer navigate the existing route.
- Position-only trigger balancing overcorrected because the stone has lateral momentum and obstacle contact. A later PD experiment still could not clear the existing route without touching route content or broadening scope; it was reverted.
- Pure frame calculation and physical application need the same total-force invariant. Normalized hand shares preserve ramp, analog ratios, single-hand authority, and total cap simultaneously.

## Unresolved questions

- Human feel approval is still required; no unattended numerical test can judge whether the new topology feels good.
- The representative route automation needs a separate spec for two-hand obstacle navigation if criterion 7 must become green.
- The installed Godot AI addon currently emits a 4.7 parser error and should be repaired or version-aligned separately.

## Next steps

1. Run a human gamepad playtest focused on alternating trigger correction and sustained two-hand balance.
2. Fill a representative Human Feel report so the Slice gate can make a real `PROCEED` decision.
3. If required, author a separate route-automation migration spec; do not reintroduce camera steering or change level content opportunistically.
