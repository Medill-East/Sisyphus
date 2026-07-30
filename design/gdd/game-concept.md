# Game Concept: 西西弗斯下山

*Created: 2026-05-24*
*Status: Draft*
*Source*: `/Users/haodong/Documents/GitHub/PKM/PlayWithExperiences/Normal Markdown - Shared/Game/Idea/game of sisyphus/2025-1019-1236  西西弗斯下山 game of sisyphus.md`

---

## 1. Overview

`西西弗斯下山` is a single-player premium PC game about pushing a heavy stone up the same mountain, releasing it, and walking back down through the consequences of that labor. It combines a first-person, physics-heavy ascent with an autonomous, player-controlled descent. The emotional goal is not simple comfort: the game begins as divine punishment and gradually becomes a practiced act of defiant joy. The target Steam product is a compact 7-level narrative experience built around one mountain, escalating weather, evolving stone physics, and a purely hummed `Ode to Joy` motif.

Core pitch: what if Sisyphus does not defeat the gods, but learns to love the climb anyway?

---

## 2. Player Fantasy

The player inhabits Sisyphus as a body under pressure. During ascent, the field of view is narrow, the stone fills the screen, hands press against it, and every push requires deliberate input. During descent, the player regains space, sees the world and the path from another angle, and recognizes that suffering has left traces: on the ground, in the weather, in the stone, and in Sisyphus' own voice.

The fantasy is not "conquer the mountain." The fantasy is "become someone who can return to the stone without being spiritually defeated."

Primary emotional arc:
- Level 1: awkward labor, little meaning, the gods treat the act as a joke.
- Levels 2-5: growing mastery, growing hostility, fragments of humming emerge.
- Level 6: near-collapse, severe divine escalation, joy becomes difficult to maintain.
- Level 7: final defiance, storm remains violent, but the player descends with a complete hummed melody and a thin break of sunlight at the foot of the mountain.

---

## 3. Detailed Rules

### Product Structure

- The release target is a finite premium game for Steam, not an endless live-service loop.
- The main campaign has 7 levels on the same mountain.
- Each level represents a stronger emotional state of the gods, expressed through weather, light, terrain conditions, obstacles, and stone material changes.
- A normal complete loop should take roughly 15-30 minutes in the final game, but vertical-slice demos may compress this to prove the arc faster.
- The main game ends after Level 7 with an interactive descent and integrated credits.

### Ascent

- The ascent is first-person or near-first-person with visible hands.
- The player must continuously press/push to move the stone uphill.
- Releasing input stops the active push; the stone then obeys gravity, friction, inertia, and terrain.
- The camera aim determines hand contact placement and lateral force bias.
- Failure means loss of position, not an instant reload, unless a level-specific divine reset explicitly triggers.
- The player must never feel glued to the stone. They can approach, disengage, recover, and re-engage.

### Summit and Release

- Reaching the ridge triggers a release beat.
- The stone must roll away through physics or a constrained physics-authored sequence, not by an obvious teleport.
- This beat is the transition from punishment to reflection.

### Descent

- The player controls Sisyphus down the mountain.
- Descent is not a cutscene, though late-game credits may be integrated into the world.
- The faster and steadier the ascent, the more daylight or clarity remains for descent.
- Descent can reveal path growth, weather contrast, old traces, and new access to small observations.

### World Change

- The pushed path records contact, pressure, slip, and stability.
- The world may respond through grass, flowers, water channels, softened light, or subjective color changes.
- Gods may reset parts of the environment, but the stone itself persists as an objective record of labor.
- Environmental change must never become a base-building game; it is meaning and reward, not a management layer.

### Stone Evolution

- The stone starts rough and angular.
- Across levels it becomes smoother, rounder, more polished, and more dangerous to lose.
- This evolution is both emotional and mechanical: lower surface roughness reduces "catch" and raises mastery demands.
- By Level 7 the stone should feel like an old companion, not only a punishment object.

### Audio and Humming

- Sisyphus hums, without lyrics.
- The final recognizable reference is `Ode to Joy`.
- Early levels expose fragments and uncertain pitches.
- Better ascent performance makes the humming clearer during descent.
- The final descent presents the complete hummed line as a release, while storm audio remains present.
- The melody plan must be checked for recording and arrangement rights even when the underlying composition is public domain.

### Divine Escalation

- The gods do not become kind or admiring.
- Strong player performance can provoke harder weather or level modifiers.
- Escalation should feel like narrative hostility, not unfair rubber-banding.
- The player's interpretation should be: "the gods are angry because I found joy."

---

## 4. Formulas

These formulas are design targets, not final tuning.

### Loop Timing

`loop_time = ascent_time + release_time + descent_time`

Target release loop:
- `ascent_time`: 10-20 minutes for an average successful run.
- `release_time`: 30-90 seconds.
- `descent_time`: 5-10 minutes.
- `loop_time`: 15-30 minutes.

Vertical-slice loop:
- `ascent_time`: 5-8 minutes.
- `release_time`: 30-60 seconds.
- `descent_time`: 3-5 minutes.

### Daylight Reward

`descent_light = clamp(1.0 - ((ascent_time - par_time) / grace_window), 0.0, 1.0)`

- `descent_light = 1.0`: golden hour, strong visual reward.
- `descent_light = 0.0`: night or storm-heavy descent.
- This affects lighting, visibility, and audio clarity, not campaign completion.

### Humming Clarity

`hum_clarity = clamp(0.45 * time_score + 0.35 * stability_score + 0.20 * recovery_score, 0.0, 1.0)`

- `time_score`: how close the run is to par or better.
- `stability_score`: low slip, low rollback, consistent contact.
- `recovery_score`: successful recovery after drift or near-loss.
- `hum_clarity` controls pitch confidence, volume, phrase length, and accompaniment filtering.

### Divine Escalation

`divine_pressure = level_pressure + max(0.0, mastery_score - comfort_threshold) * jealousy_gain`

- `level_pressure`: baseline hostility for the current level.
- `mastery_score`: recent performance across the last runs.
- `jealousy_gain`: how aggressively gods respond.
- Escalation may affect wind, rain, visibility, obstacle timing, and surface wetness.

### Stone Smoothness

`stone_smoothness = clamp(level_index / 7.0 + total_contact_distance * wear_gain, 0.0, 1.0)`

- Higher smoothness lowers grip and raises rollback risk.
- Visual polish and shape roundness follow this value.

---

## 5. Edge Cases

- If the stone falls too far, the player must be able to recover without restarting the whole application.
- If the player disengages, the camera must return smoothly and control must remain usable.
- If the gods trigger a reset, the game must communicate that the reset is hostile intervention, not a bug.
- If the player completes a level slowly, the game should still allow completion but with reduced descent reward.
- If the player is motion-sensitive, camera shake, first-person bob, and storm effects need accessibility options.
- If humming becomes annoying after retries, the mix should degrade gracefully into breath fragments or allow volume control.
- If the stone evolves into a smoother form, it must not become physically impossible to push with available controls.
- If path growth is reset by gods, persistent player-facing progress must still exist through stone evolution, unlocked melody fragments, or campaign level completion.

---

## 6. Dependencies

- `design/gdd/systems-index.md` for full system decomposition.
- `design/gdd/game-pillars.md` for decision rules.
- Godot 4.6.2 / GDScript implementation under `/Users/haodong/Documents/GitHub/Sisyphus/godot`.
- Current push-lab prototype: `godot/scenes/PushLab.tscn`.
- Prototype report: `prototypes/push-lab-concept/REPORT.md`.
- Future system GDDs required before production: player push controller, stone physics, camera, level progression, weather/divine escalation, environment response, audio humming, save/progression, accessibility, release pipeline.

---

## 7. Tuning Knobs

- Stone: mass, radius, friction, angular damping, linear damping, smoothness, roughness catch, polish visual level.
- Push: contact spring, damping, max force, aim lateral strength, disengage distance, hand reach threshold.
- Camera: first-person blend speed, push FOV, shoulder fallback distance, motion shake, storm visibility filtering.
- Route: slope grade, path width, obstacle density, obstacle size, side escape space, rollback catch zones.
- Time: par time, daylight grace window, descent reward thresholds, final-level credit pacing.
- Divine escalation: weather intensity, wind gust strength, rain slipperiness, visibility loss, obstacle intervention frequency.
- Audio: humming clarity, breath/noise mix, phrase unlock thresholds, storm-vs-hum mix priority.
- Environment response: trail width, growth delay, growth density, water/flower probability, subjective color shift strength.

---

## 8. Acceptance Criteria

- A first-time player can explain the core loop as "push the stone up, release it, walk down through what changed."
- The ascent requires continuous physical control and cannot be mistaken for a scripted escort.
- Releasing input stops active push and produces plausible stall, rollback, or recovery behavior.
- Camera aim visibly changes hand contact and stone drift.
- The same mountain can support 7 escalating levels through route, weather, physics, and audio changes.
- The stone evolves across levels and that evolution changes both appearance and handling.
- Descent remains player-controlled and clearly contrasts with ascent.
- Humming rewards mastery and culminates in a recognizable, lyric-free `Ode to Joy` moment.
- The gods remain antagonistic; any beauty or joy comes from Sisyphus' practice and perception, not divine approval.
- The project has a Steam release plan covering builds, save/settings, controller support, accessibility, localization readiness, store assets, QA, and legal/audio review.
