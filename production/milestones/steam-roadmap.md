# Steam Roadmap: 西西弗斯下山

*Created: 2026-05-24*
*Status: Draft*

This roadmap treats Steam release as the real objective. The current Godot push-lab is useful evidence, but it is not the game. The production path must pass through a playable vertical slice, alpha content completion, beta release readiness, and store launch work.

---

## Release Target

- **Platform**: Steam desktop first, Windows required, macOS/Linux desirable if export stability allows.
- **Engine**: Godot 4.6.2 / GDScript.
- **Business model**: Premium, compact indie game.
- **Estimated final playtime**: 2-4 hours depending on player skill.
- **Campaign structure**: 7 levels on one mountain.
- **Core loop**: push up, release, descend, reflect, prepare for the next punishment.
- **Primary proof standard**: players feel the stone's weight and the emotional shift from suffering to defiant joy.

---

## Current State

| Area | Status | Evidence |
|------|--------|----------|
| Godot project | Exists | `godot/project.godot` |
| Push-lab | Implemented | `godot/scenes/PushLab.tscn` |
| Contact push tests | Passing in previous goal | `godot/tests/test_contact_push_physics.gd` |
| Full game concept | Drafted this pass | `design/gdd/game-concept.md` |
| Systems map | Drafted this pass | `design/gdd/systems-index.md` |
| Steam release pipeline | Started | Desktop export presets, readiness tests, and repeatable export script exist; export templates/signing/SteamPipe still pending |

---

## Milestone 0: Concept Lock

**Goal**: Freeze the product direction enough that engineering work does not chase contradictory visions.

Deliverables:
- `design/gdd/game-concept.md`
- `design/gdd/game-pillars.md`
- `design/gdd/systems-index.md`
- This roadmap.

Exit gate:
- The user approves the concept, pillars, systems list, and initial vertical-slice target.
- The project keeps Godot 4.6.2 / GDScript as the main implementation route.
- The game remains one mountain, 7 escalating levels, lyric-free humming, hostile gods, evolving stone.

---

## Milestone 1: Push-Lab Becomes a Regression Tool

**Goal**: Preserve the hand feel while future systems are added.

Deliverables:
- Push-lab presets remain available: heavy, standard, light.
- F3 debug remains available for contact point, force vector, velocity, angular velocity, uphill component, spin ratio.
- Automated tests cover push, release, lateral aim, spin, lift, player disengage.
- A short manual playtest checklist exists for push-lab tuning.

Exit gate:
- A fresh Godot test run passes.
- Computer Use or Godot AI visual check records push, bias, release, and recovery.
- Any push controller change must run push-lab tests before merging into the main loop.

---

## Milestone 2: Vertical Slice Loop

**Goal**: Build one representative 5-10 minute playable loop that proves the game's emotional structure.

Recommended target:
- Use a mid-game storm level, equivalent to Level 4 or Level 5.
- The stone is partly smoothed, not final-polished.
- The gods are visibly angry but not at maximum intensity.

Required features:
- One ascent route with obstacles and rollback risk.
- One physical release at the ridge.
- One controlled descent route.
- One explicit Chapter I ending after the player descends and returns to the fallen stone.
- Trail/environment response visible after release.
- Daylight/time reward changes descent tone.
- One hummed phrase whose clarity depends on run performance.
- One divine escalation event that is readable and fair.

Exit gate:
- A player can complete the loop without developer explanation.
- The player can intentionally bias the stone left/right and recover.
- Release and descent are legible without teleporting the player.
- The humming reward is audible and tied to performance.
- Visual pass proves the same mountain feels different before and after pushing.
- The loop stops at `complete / Chapter I End`; Chapter II transition remains a separate unresolved design problem, not a same-scene re-push placeholder.

---

## Milestone 3: Alpha Campaign Skeleton

**Goal**: Make all 7 levels playable with placeholder assets and rough audio.

Level arc:

| Level | Divine State | Primary Modifier | Stone State | Humming Reward |
|-------|--------------|------------------|-------------|----------------|
| 1 | Mockery | Baseline route | Rough | First motif fragments |
| 2 | Irritation | Light wind and sand | Rough-chipped | Short phrase |
| 3 | Annoyance | Stronger wind and side drift | Chipped | More stable phrase |
| 4 | Anger | Rain and lower friction | Worn | Recognizable motif |
| 5 | Rage | Mud, visibility loss, harder recovery | Smoother | Longer connected phrase |
| 6 | Fury | Severe storm, unstable route pressure | Nearly round | Strained phrase |
| 7 | Final Defiance | Storm at maximum, final climb | Polished sphere | Full lyric-free descent hum |

Exit gate:
- Every level has a complete ascent-release-descent loop.
- Save/profile tracks unlocked levels, ratings, stone evolution, and hum fragments.
- Controller and keyboard/mouse both work.
- Accessibility basics exist: camera intensity, audio levels, subtitles/captions for non-dialogue cues where applicable.

---

## Milestone 4: Beta / Steam Readiness

**Goal**: Turn the alpha into a shippable desktop game candidate.

Required work:
- Main menu, settings, pause, remap controls, save/load.
- Steam build pipeline with Windows export as the minimum. Current baseline: Godot desktop presets exist for macOS, Windows, and Linux, with `test_export_readiness.gd` guarding target paths and `tools/export_desktop.sh` handling template preflight/export commands.
- Crash-free 30-minute soak runs on target machine.
- Performance budget for storm/rain/weather scenes.
- Audio legal checklist for `Ode to Joy` arrangement and all recordings.
- Store capsule art, screenshots, trailer capture plan, Steam description.
- Localization-ready text tables even if first release ships only in Chinese/English.
- QA pass for all levels, all endings/credits states, all settings, save migration.

Exit gate:
- Steam build launches outside the editor.
- Fresh install can start, save, quit, resume, finish at least Level 1.
- At least 3 external playtesters complete Level 1; at least 1 reaches the vertical-slice level.
- No known blocker bugs in push physics, save/load, or release flow.

---

## Milestone 5: Release Candidate

**Goal**: Prepare a build that can plausibly be submitted and sold on Steam.

Exit gate:
- Complete campaign can be finished from a fresh profile.
- Store page assets are ready.
- Trailer demonstrates ascent weight, release, descent, weather escalation, stone evolution, and humming.
- All third-party assets and audio sources have license notes.
- Accessibility and control settings are documented in-game.
- Release checklist is complete.

---

## Immediate Next Execution Plan

1. Review these draft design docs.
2. Approve or revise the vertical-slice target: Level 4/5 storm loop on the same mountain.
3. Write a detailed implementation plan for Milestone 2.
4. Execute the plan task-by-task in Godot.
5. Run Godot tests plus Computer Use visual checks after every physics/camera/audio milestone.

The current goal remains active until a Steam-ready game exists or the scope is explicitly changed.
