# Game Pillars: 西西弗斯下山

*Created: 2026-05-24*
*Status: Draft*
*Source*: `design/gdd/game-concept.md`

---

## 1. Overview

These pillars constrain every design, art, audio, engineering, and production decision for `西西弗斯下山`. The game is not a generic physics challenge and not a purely cozy walking simulator. It is a finite premium experience about difficult repetition becoming meaningful through mastery, perception, and defiant joy.

---

## 2. Player Fantasy

The player fantasy is to become Sisyphus at the exact point where punishment turns into practice. The player feels the stone's weight, loses control, recovers, learns the mountain, hears fragments of joy emerge from breath, and eventually returns to the same stone with a changed mind.

---

## 3. Detailed Rules

### Pillar 1: Weight Must Be Honest

The stone must feel heavy, physical, and resistant. Every successful ascent should feel earned through sustained contact, not through scripted movement.

Design test: if a shortcut makes the stone more reliable but visibly less physical, reject it unless it is hidden inside plausible contact behavior.

Department implications:
- Game Design: failure, rollback, friction, and recovery are core gameplay, not bugs to erase.
- Art: hand contact, stone surface, trail marks, and body posture must communicate effort.
- Audio: scraping, breath, and strained humming must track physical load.
- Engineering: physics tests and visual debug tools are production-critical.

### Pillar 2: The Descent Is Still Play

Downhill is not a passive reward cutscene. The player must control Sisyphus, notice what changed, and choose how to spend the remaining day.

Design test: if a descent beat would work equally well as a non-interactive cinematic, redesign it so player movement, looking, or timing matters.

Department implications:
- Game Design: descent needs routes, observations, and meaningful pacing without becoming a checklist.
- Art: the same path must read differently after labor.
- Audio: the mix opens up, but the storm and breath do not disappear completely.
- Engineering: ascent state must feed descent lighting, growth, and humming systems.

### Pillar 3: Joy Is Defiance, Not Comfort

The game should never become purely warm, safe, or sentimental. The gods remain hostile; joy appears because Sisyphus develops a stance they cannot control.

Design test: if a feature makes the gods supportive or turns the punishment into simple cozy fantasy, cut it or reframe it.

Department implications:
- Game Design: divine escalation is antagonistic, but readable and fair.
- Art: beauty should often appear inside harsh weather, not after all conflict disappears.
- Audio: humming should compete with wind, rain, thunder, and exhaustion.
- Narrative: avoid NPC praise from gods; use environment, stone, and song as emotional carriers.

### Pillar 4: One Mountain, Seven Transformations

The campaign should reuse one mountain as a meaningful stage. Progression comes from weather, route variants, stone evolution, physics modifiers, time pressure, and player mastery.

Design test: if a proposed level requires a wholly new biome to feel different, first ask whether the same mountain can express that difference through atmosphere and mechanics.

Department implications:
- Game Design: each level needs a distinct pressure profile.
- Art: invest in lighting, weather, and surface states before broad asset sprawl.
- Audio: each level unlocks or distorts a different humming phrase.
- Engineering: build modular level modifiers, not seven separate one-off scenes.

---

## 4. Formulas

Pillar priority when tradeoffs conflict:

1. `Weight Must Be Honest`
2. `Joy Is Defiance, Not Comfort`
3. `The Descent Is Still Play`
4. `One Mountain, Seven Transformations`

Examples:
- If close first-person camera improves weight but hides too much descent readability, ascent keeps the close camera and descent receives a separate wider mode.
- If beautiful weather weakens divine hostility, keep the storm and make beauty appear as a small break in light, color, or song.
- If a new map would be visually exciting but delays the first full loop, reuse the mountain and deepen weather/physics variation.

---

## 5. Edge Cases

- Accessibility features must not be rejected as "less punishing" if they preserve the pillar of honest weight.
- Divine escalation cannot secretly invalidate player mastery; players must understand why conditions changed.
- Humming cannot become triumphant too early; the Aha moment needs buildup.
- Stone smoothing cannot remove all recoverability before the player has learned recovery tools.
- Descent exploration cannot grow into a collectible-heavy checklist that breaks the contemplative loop.

---

## 6. Dependencies

- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `prototypes/push-lab-concept/REPORT.md`
- Current Godot push-lab physics and camera prototype.

---

## 7. Tuning Knobs

- Pillar 1: acceptable spin-to-translation ratio, rollback speed, contact loss threshold, force vector readability.
- Pillar 2: descent route length, observation density, time-of-day reward strength, post-ascent camera distance.
- Pillar 3: storm mix volume, divine intervention frequency, warmth/harshness color balance, hum-to-storm mix ratio.
- Pillar 4: number of unique route modifiers per level, weather intensity curve, stone smoothness progression, asset reuse ratio.

---

## 8. Acceptance Criteria

- Every new feature explicitly serves at least one pillar.
- Any feature that violates Pillar 1 or Pillar 3 requires explicit written approval before implementation.
- A reviewer can distinguish the 7 levels without requiring 7 different mountains.
- The final descent remains harsh in weather but emotionally resolved through control, song, and the small break of light.
- The pillars can be used to reject at least three tempting scope expansions: open world exploration, cozy farming/base-building, and god approval dialogue.

---

## Anti-Pillars

- **Not an open-world traversal game**: the mountain is a focused ritual space, not a map to exhaust.
- **Not a cozy nature restoration sim**: growth is emotional feedback, not resource management.
- **Not a god-redemption story**: the gods do not learn to respect Sisyphus.
- **Not a pure rage game**: difficulty exists to create mastery and contrast, not humiliation for its own sake.
- **Not a systems-heavy roguelite**: the campaign is finite, level-based, and tuned around 7 emotional stages.
