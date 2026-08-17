# Kimi Version MVP — Design Spec

> 决策：無涘 ｜ 记录：Kimi
> Created: 2026-08-18 00:28 · Status: Approved (design review 2026-08-18)

Source concept: `design/gdd/game-concept.md`, `design/gdd/game-pillars.md`.

---

## 1. Overview

A clean-room reimplementation of `西西弗斯下山`, built in a new top-level
directory `kimi-version/`. It replaces the three unsatisfying prior attempts
(UE skeleton, React web prototype, process-heavy Godot project) with one
focused MVP: a physically honest, visually readable first-person
push-the-stone loop in the browser.

The two design commitments confirmed with the author on 2026-08-18:

- **Contact geometry stays honest.** Pushing on the stone's left side sends
  it right; the prior versions' sin was poor simulation quality (weight,
  inertia, contact fidelity), not the direction mapping.
- **Look and force stay decoupled.** Head look (mouse / right stick, limited
  by neck range) is independent from per-hand push force (mouse buttons /
  LT-RT triggers), matching the input contract settled on 2026-07-31.

Aesthetic bar: the author explicitly granted freedom to push visual quality
beyond "prototype crude" — readability first, then crafted.

---

## 2. Goals and Acceptance Criteria

A first-time viewer/player must be able to verify four bars:

1. **Readability (表意)** — it is unambiguous that a person is pressing both
   hands against a heavy stone and straining. Hands read as hands, not rods;
   contact with the stone surface is visibly exact.
2. **Weight (重量)** — the stone resists, gathers inertia slowly, stalls when
   force stops, and rolls back downhill honestly. Recovery is possible.
3. **Contact truth (接触)** — left-side pressure drifts the stone right and
   vice versa, and the visual contact points match the physics contact
   points exactly.
4. **Loop (循环)** — approach → hands rise and conform to the stone → push up
   the path → ridge release → stone rolls away through physics → walk down →
   arrive back at the stone. Closed loop, no teleports.

---

## 3. Tech Stack and Rationale

- **TypeScript + three.js + Rapier (`@dimforge/rapier3d-compat`) + Vite.**
  No React, no game engine editor.
- Why Web: the failed areas (hand IK readability, camera coupling, push
  feel) are all code-level concerns where iteration speed decides quality.
  Rapier runs the same WASM in Node and the browser, so physics behavior is
  unit-testable headlessly; Playwright screenshots give visual verification
  without opening a window manually.
- Why not Godot: the documented mainline, but the author confirmed the stack
  choice is ours, and headless visual iteration is slower there.
- Input: Keyboard+mouse and gamepad are both first-class from day one
  (browser Gamepad API gives analog LT/RT).

---

## 4. Architecture and Module Layout

```
kimi-version/
  index.html
  src/
    main.ts          boot, loop, wiring
    core/            fixed-timestep loop, game state machine, input intent layer
    physics/         Rapier world, stone body, terrain collider, kinematic player,
                     push solver (contact points + per-hand forces)
    body/            first-person body rig, analytic 2-bone arm IK, hand state machine
    camera/          head look (neck-limited), body facing, engage ease-in/out
    world/           procedural heightfield mountain, path, ridge, lighting, sky
    game/            loop beats: approach / engage / push / release / descent / result
  tests/             vitest suites (physics numerics + pure logic)
```

Design rules:

- One purpose per module; physics never imports rendering; rendering reads
  state, never mutates physics.
- Input devices map to a single `InputIntent` (move, look, leftHand 0..1,
  rightHand 0..1) so gamepad and mouse share every downstream path.
- Fixed timestep physics (60 Hz) with render interpolation; all tuning lives
  in one `Tuning` object.

---

## 5. Push Physics Model

- **Stone**: dynamic rigid sphere, radius ≈ 1.0 m, high mass, real rolling
  friction and restitution ≈ 0. Slope gravity does all rollback; no scripted
  translation ever.
- **Player**: kinematic capsule; cannot pass through the stone.
- **Contact points**: when the player is within reach of the stone, each
  hand's contact is the point on the sphere surface facing the player's
  chest, offset laterally per hand; points move continuously as the player
  shifts stance. The same points drive both the arm IK targets and the
  force application — visual and physics contact cannot diverge.
- **Force**: pressing a hand applies force at that hand's contact point,
  directed along the palm push direction (contact → sphere center, i.e. the
  compression normal), magnitude = analog input × force ceiling. Applied
  off-center, so translation, torque, and spin emerge from the same call.
  Left-side pressure drifts the stone rightward — honest geometry, visually
  explained by the hands.
- **Breakaway statics**: a stalled stone needs visibly more force to start
  than to keep rolling (static → rolling transition), producing the
  "straining start" beat.
- **Release honesty**: zero input → zero push force; the stone obeys
  gravity, friction, and inertia — stall or rollback per slope. Releasing
  both hands or stepping out of reach lifts the hands off smoothly.
  The player is never glued.

---

## 6. Body, Hands, Camera

- **Visible body**: shoulders, upper arms, forearms, and hands with palms
  and fingers (low-poly but articulated); subtle torso lean under load.
- **Hand state machine**: `lowered (walking) → raising (near stone) →
  conforming (palms land on surface, aligned to surface normal) → pressing
  (compression under force)`. All transitions are smooth blends driven by
  distance-to-stone and input; reverse path on disengage.
- **Arms**: analytic two-bone IK per arm (shoulder–elbow–wrist), wrist
  orientation aligned to the surface normal at the contact point.
- **Head**: mouse / right stick yaw+pitch, yaw clamped to roughly ±120° from
  body facing (neck limit), pitch clamped sanely. Head look never steers
  force.
- **Body facing**: follows movement direction while walking; while engaged
  it squares to the stone (stance coupling). Engaging also eases the head
  position into the push stance (closer, slightly lowered); disengaging
  restores it smoothly. This is the "camera naturally closes in" beat.

---

## 7. Input Contract

| Action       | Keyboard/Mouse        | Gamepad                |
|--------------|-----------------------|------------------------|
| Move         | WASD                  | Left stick             |
| Look (head)  | Mouse                 | Right stick            |
| Left hand    | Left mouse button     | LT (analog 0..1)       |
| Right hand   | Right mouse button    | RT (analog 0..1)       |
| Reset loop   | R                     | Start                  |

Force per hand is analog where the device allows it (triggers); mouse
buttons act as full-strength binary. Per-hand gamepad rumble mirrors load.

---

## 8. MVP Loop and Mountain

- Procedural heightfield mountain: one readable uphill path, grade varying
  in rhythm (ramps, steeper pitches, one nearly-flat recovery shelf),
  ≈ 60–80 m of climb; raised banks keep the stone recoverable; a ridge line
  at the top with a far-side downslope.
- Beats: spawn at the foot → approach → engage → push the full path → cross
  the ridge → **release**: the stone rolls away down the far side through
  pure physics → descent on foot with opened framing and warmer light →
  arrive at the stone's rest position near the foot → minimal result readout
  (time, rollback count) → loop can restart.
- The stone persists as the record of labor: where it stops is where the
  next loop starts.

---

## 9. Visual Direction

- Clean stylized look pushed beyond prototype-crude: soft directional light
  with shadows, distance fog, a calm sky gradient, distinct materials for
  stone / path / banks / grass; the uphill path must read at a glance from
  the foot.
- Contact feedback: palm compression on the surface, scrape audio volume
  tied to stone angular velocity (WebAudio, no assets), a dust/grit flicker
  at the contact patch on breakaway, optional per-hand rumble.
- HUD: almost none — a contextual control hint at first engage, a faint
  ridge marker, and the result readout after descent. Meaning lives in the
  world, not in UI.

---

## 10. Explicit Non-Goals (MVP)

Seven levels, weather/divine escalation, humming and audio progression,
obstacles, stone evolution, menus/settings, saves, telemetry, CCGS process
artifacts, Steam packaging. None of these are built, stubbed, or
scaffolded.

---

## 11. Verification Plan

- **Physics numerics (vitest + Rapier in Node)**: sphere on a slope stalls
  vs rolls per grade; sustained push makes uphill progress; left-contact
  force displaces the stone rightward (and mirror); releasing input leads
  to stall/rollback on a steep grade; static breakaway force > rolling
  sustain force.
- **Visual beats (Playwright screenshots)**: approach, hands conforming,
  pressing under load, ridge release, descent — reviewed as images for
  readability.
- **Human playtest**: local dev-server URL; both keyboard/mouse and gamepad.

---

## 12. Risks and Mitigations

- **Feel quality is the whole risk.** Mitigation: numeric harness +
  screenshot beats + one tuning object; iterate in small loops.
- **Hand IK quality** (palms truly conforming) — timebox a first version,
  verify via close-up screenshots, refine once.
- **Rapier rolling-sphere realism** on custom heightfield — validate early
  with the slope stall/rollback tests before building the loop around it.

---

## 13. Tuning Knobs

Stone: mass, radius, friction, rolling resistance, restitution.
Push: per-hand force ceiling, engage/reach distance, contact lateral offset,
static breakaway gain.
Body/camera: arm segment lengths, IK blend times, neck yaw/pitch limits,
engage camera ease.
Mountain: path length, grade profile, bank height, ridge position.
Loop: descent light warmth, result thresholds.
