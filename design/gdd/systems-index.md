# Systems Index: 西西弗斯下山

> **Status**: Draft
> **Created**: 2026-05-24
> **Last Updated**: 2026-05-24
> **Source Concept**: `design/gdd/game-concept.md`

---

## Overview

`西西弗斯下山` needs a small number of deeply integrated systems rather than many broad features. The foundation is a believable push-stone interaction, a camera that expresses physical pressure, and one reusable mountain route. Around that, the production game layers level modifiers, stone evolution, weather, time economy, descent response, and humming progression until it can support a 7-level Steam release.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Input and Control Contract | Core | MVP | Prototype Exists | — | — |
| 2 | Player Body and Push Controller | Core | MVP | Prototype Exists | — | Input |
| 3 | Stone Contact Physics | Core | MVP | Prototype Exists | — | Input, Player Controller |
| 4 | Push Camera and First-Person Hands | Core | MVP | Prototype Exists | — | Player Controller, Stone Physics |
| 5 | Mountain Route and Collision | Core | MVP | Prototype Exists | — | Stone Physics |
| 6 | Gameplay State Machine | Core | MVP | Prototype Exists | — | Player Controller, Mountain |
| 7 | Push-Lab Test Harness | Core | MVP | Implemented | `prototypes/push-lab-concept/REPORT.md` | Systems 1-6 |
| 8 | Obstacle and Route Pressure | Gameplay | Vertical Slice | Prototype Exists | — | Mountain, Stone Physics |
| 9 | Ascent/Release/Descent Loop | Gameplay | Vertical Slice | Partial Prototype | — | State Machine, Camera, Mountain |
| 10 | Descent Exploration and Observation | Gameplay | Vertical Slice | Not Started | — | Ascent/Descent Loop |
| 11 | Daylight Time Economy | Progression | Vertical Slice | Not Started | — | State Machine, Level Progression |
| 12 | Trail Recording and Environment Response | Gameplay | Vertical Slice | Early Prototype Concept | — | Stone Physics, Mountain |
| 13 | Divine Escalation and Weather | Gameplay | Vertical Slice | Not Started | — | Level Progression, Weather Rendering |
| 14 | Stone Evolution | Gameplay | Vertical Slice | Not Started | — | Stone Physics, Level Progression |
| 15 | Humming and `Ode to Joy` Progression | Audio | Vertical Slice | Early Prototype Concept | — | Run Metrics, Level Progression |
| 16 | Run Metrics and Rating | Progression | Vertical Slice | Partial Prototype | — | State Machine, Stone Physics |
| 17 | Level Progression: 7 Divine States | Progression | Alpha | Not Started | — | Systems 8-16 |
| 18 | Save, Settings, and Profile | Persistence | Alpha | Not Started | — | Level Progression, Audio Settings |
| 19 | HUD, Menus, and Debug Views | UI | Alpha | Debug Prototype Exists | — | Metrics, Settings |
| 20 | Accessibility Options | UI | Alpha | Not Started | — | Camera, Input, Audio, UI |
| 21 | Art Direction and Asset Pipeline | Presentation | Alpha | Not Started | — | Mountain, Weather, Stone Evolution |
| 22 | Audio Production Pipeline | Audio | Alpha | Not Started | — | Humming System, Legal Review |
| 23 | Performance and Build Pipeline | Meta | Alpha | Not Started | — | Godot Project |
| 24 | Localization Readiness | Meta | Beta | Not Started | — | UI, Credits, Store Text |
| 25 | Steam Release Integration | Meta | Beta | Not Started | — | Build Pipeline, Save/Profile |
| 26 | QA, Playtest, and Telemetry-Lite Logs | Meta | Beta | Not Started | — | All Gameplay Systems |
| 27 | Store Assets and Trailer Capture | Meta | Release | Not Started | — | Vertical Slice, Art/Audio |

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| Core | Required for physical control and scene operation | 1-7 |
| Gameplay | Moment-to-moment and loop-defining mechanics | 8-14 |
| Progression | Level unlocks, ratings, and campaign structure | 11, 16, 17 |
| Persistence | Save state and player preferences | 18 |
| UI | Player-facing menus, HUD, accessibility, debug views | 19, 20 |
| Audio | Humming, storm mix, music progression | 15, 22 |
| Presentation | Visual identity, art, weather, lighting | 21 |
| Meta | Build, QA, Steam, store, release operations | 23-27 |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| MVP | Proves the stone can be pushed without fake movement | Push-lab / first playable | Design first |
| Vertical Slice | Proves one complete ascent-release-descent emotional loop | Steam pitch demo | Design second |
| Alpha | All 7 levels playable with placeholder assets | Content complete rough build | Design third |
| Beta | Release systems, QA, accessibility, localization readiness | Steam-ready candidate | Design fourth |
| Release | Store, trailer, final polish, legal/audio clearance | Steam launch | Design last |

---

## Dependency Map

### Foundation Layer

1. Input and Control Contract — defines keyboard, controller, mouse, and accessibility mappings.
2. Mountain Route and Collision — provides the physical space all other systems use.
3. Gameplay State Machine — tracks approach, ascent, release, descent, complete, and level transitions.

### Core Layer

1. Player Body and Push Controller — depends on input, mountain, and state.
2. Stone Contact Physics — depends on mountain and player contact.
3. Push Camera and First-Person Hands — depends on player and stone state.
4. Push-Lab Test Harness — depends on the core control/physics/camera stack.

### Feature Layer

1. Obstacle and Route Pressure — depends on mountain and stone physics.
2. Ascent/Release/Descent Loop — depends on state, camera, stone, mountain.
3. Run Metrics and Rating — depends on loop events and physics metrics.
4. Daylight Time Economy — depends on run metrics and level definitions.
5. Trail Recording and Environment Response — depends on stone path and descent.
6. Divine Escalation and Weather — depends on level progression and metrics.
7. Stone Evolution — depends on level progression and stone physics.
8. Humming Progression — depends on run metrics, level, and audio pipeline.

### Presentation Layer

1. Descent Exploration and Observation — depends on loop and environment response.
2. HUD, Menus, and Debug Views — depends on metrics, settings, level state.
3. Art Direction and Asset Pipeline — depends on level/weather/stone targets.
4. Audio Production Pipeline — depends on humming design and legal review.

### Polish and Release Layer

1. Save, Settings, and Profile — depends on level progression and user settings.
2. Accessibility Options — depends on input, camera, UI, audio.
3. Performance and Build Pipeline — depends on final target platforms.
4. Localization Readiness — depends on text surfaces and store text.
5. Steam Release Integration — depends on build pipeline and save/profile.
6. QA, Playtest, and Telemetry-Lite Logs — depends on all gameplay systems.
7. Store Assets and Trailer Capture — depends on a representative vertical slice.

---

## Recommended Design Order

| Order | System | Priority | Layer | Suggested Workflow | Est. Effort |
|-------|--------|----------|-------|--------------------|-------------|
| 1 | Stone Contact Physics | MVP | Core | `$ccgs-quick-design` then Godot tests | M |
| 2 | Player Body and Push Controller | MVP | Core | `$ccgs-design-system` | M |
| 3 | Push Camera and First-Person Hands | MVP | Core | `$ccgs-design-system` | M |
| 4 | Ascent/Release/Descent Loop | Vertical Slice | Feature | `$ccgs-design-system` | L |
| 5 | Daylight Time Economy | Vertical Slice | Feature | `$ccgs-design-system` | M |
| 6 | Humming Progression | Vertical Slice | Audio | `$ccgs-team-audio` or solo quick design | L |
| 7 | Divine Escalation and Weather | Vertical Slice | Feature | `$ccgs-design-system` | L |
| 8 | Stone Evolution | Vertical Slice | Feature | `$ccgs-design-system` | M |
| 9 | Trail Recording and Environment Response | Vertical Slice | Feature | `$ccgs-design-system` | L |
| 10 | Save, Settings, and Accessibility | Alpha | Polish | `$ccgs-ux-design` + implementation stories | L |
| 11 | Steam Build and Release Pipeline | Beta | Release | `$ccgs-release-checklist` | L |

---

## Circular Dependencies

- Humming Progression <-> Run Metrics: humming needs run metrics, but run metrics must know which humming phrase was eligible. Resolution: Run Metrics owns raw performance; Humming reads it and writes only presentation state.
- Divine Escalation <-> Player Mastery: escalation responds to mastery but also changes future mastery. Resolution: use previous-run mastery for baseline escalation and current-run events only for temporary effects.
- Stone Evolution <-> Stone Physics: evolution changes physics, but physics creates evolution data. Resolution: store evolution as level/profile state; runtime physics reads a frozen value per level attempt.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|------------------|------------|
| Stone Contact Physics | Technical / Feel | A bad push model can feel fake, glued, or uncontrollable | Keep push-lab as daily regression scene; require visual and physics tests |
| Humming Progression | Audio / Legal | `Ode to Joy` arrangement and recordings still need rights clarity | Use original recordings or synthetic/contracted hum stems; track license docs |
| Divine Escalation | Design | Playing well can feel punished instead of honored | Communicate gods' hostility clearly and keep escalation fair/tested |
| Environment Response | Scope | Reactive world growth can explode into tech-art scope | Vertical slice only needs one strong path-growth transformation |
| Stone Evolution | Technical / Balance | Smooth stone can become impossible or too easy | Per-level fixed presets plus tests for recoverable control |
| Steam Release Pipeline | Production | Builds, settings, controller support, store assets, and QA can be underestimated | Add release checklist before Alpha, not after content completion |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 27 |
| Design docs started | 3 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems with prototype evidence | 7 |
| Vertical Slice systems with prototype evidence | 3 |
| Steam release systems started | 0 |

---

## Next Steps

- [ ] Review and approve `game-concept.md`, `game-pillars.md`, and this systems index.
- [ ] Write the first implementation plan for the vertical-slice loop.
- [ ] Turn the push-lab into a reusable regression gate for all future physics changes.
- [ ] Design the audio humming system before adding final music assets.
- [ ] Build one complete 5-10 minute vertical-slice loop before expanding to all 7 levels.
- [ ] Use the vertical slice to decide whether the final scope remains 7 levels or needs reduction.
