# Sisyphus Steam Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first Steam-directed vertical slice: one complete storm-loop level on the same mountain, proving ascent weight, physical release, descent contrast, trail/environment response, divine weather pressure, stone evolution, and humming reward.

**Architecture:** Keep the existing Godot project and push-lab as the physics regression tool. Add a thin level-loop layer above current player/stone/mountain systems instead of rewriting the push controller. The vertical slice should be one representative mid-game level, not the full 7-level campaign.

**Tech Stack:** Godot 4.6.2, GDScript, existing `CharacterBody3D` player, `RigidBody3D` stone, procedural mountain, headless script tests, Computer Use/Godot visual checks.

---

## Execution Status

- Completed: Tasks 1-7 logic foundation, Task 8 `VerticalSlice.tscn` scene assembly, Task 9 loop smoke contract, Task 10 automated visual verification modes plus short-loop driver, push-exit pose reset, near-ridge route physics coverage, front-base bot route smoke, front-base player-input route check, HUD route telemetry, telemetry-backed `PROCEED / PIVOT / KILL` gate, and CCGS-style playtest report/protocol support.
- Evidence report: `prototypes/vertical-slice-loop/REPORT.md`.
- Current boundary: the vertical-slice scene has repeatable visual states, a connected short-loop driver, near-ridge physical release/descent coverage, a bot-driven full-slope route smoke, an automated player-input route check, hand-play telemetry, an automated `PROCEED` gate, and a manual playtest protocol, but it is not yet proven as a human-played 5-10 minute storm loop.

---

## File Structure

Create:
- `godot/scripts/LevelDefinition.gd` — immutable per-level config: weather, stone state, par time, hum phrase, divine pressure.
- `godot/scripts/LevelManager.gd` — owns active level, attempt start/end, phase transitions, and no-teleport release/descent flow.
- `godot/scripts/RunMetrics.gd` — records ascent time, rollback count, contact stability, lateral drift, daylight reward, hum clarity.
- `godot/scripts/TrailRecorder.gd` — records stone path points during ascent/release.
- `godot/scripts/EnvironmentResponse.gd` — turns trail data into visible growth/water/flower markers for descent.
- `godot/scripts/WeatherController.gd` — applies storm, wind, rain, visibility, and lighting state.
- `godot/scripts/HummingController.gd` — maps metrics to lyric-free hum phrase clarity.
- `godot/scenes/VerticalSlice.tscn` — playable Level 4/5 storm-loop scene using existing mountain/player/stone.
- `godot/tests/test_vertical_slice_logic.gd` — pure and scene-level checks for level config, metrics, transitions.
- `godot/tests/test_trail_environment_response.gd` — trail recording and visible response checks.
- `godot/tests/test_humming_progression.gd` — phrase unlock/clarity logic checks.

Modify:
- `godot/scripts/Main.gd` — extract reusable setup if needed; do not break `Main.tscn`.
- `godot/scripts/MountainBuilder.gd` — expose route/trail placement helpers needed by the environment response.
- `godot/scripts/Tuning.gd` — add vertical-slice tuning values without removing push-lab presets.
- `godot/project.godot` — add input actions only if a new action is unavoidable.
- `godot/README.md` — add vertical-slice run and test commands.

Do not modify:
- `prototype/` unless explicitly asked.
- Push-lab behavior except to preserve regression coverage.

---

### Task 1: Level Definition Contract

**Files:**
- Create: `godot/scripts/LevelDefinition.gd`
- Create: `godot/tests/test_vertical_slice_logic.gd`

- [ ] **Step 1: Write the failing test**

Add `test_level_4_storm_definition()`:

```gdscript
var level = LevelDefinition.create_storm_vertical_slice()
_expect_true(level.level_id == 4, "vertical slice should target mid-game Level 4")
_expect_true(level.divine_state == "anger", "Level 4 should express divine anger")
_expect_true(level.weather_intensity >= 0.65, "storm level should have strong weather")
_expect_true(level.stone_smoothness > 0.35 and level.stone_smoothness < 0.75, "stone should be worn but not final-polished")
_expect_true(level.par_ascent_seconds > 0.0, "level should define a par ascent time")
_expect_true(level.hum_phrase_id == "ode_motif_4", "level should bind to a hum phrase")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_vertical_slice_logic.gd
```

Expected: FAIL because `LevelDefinition.gd` does not exist.

- [ ] **Step 3: Implement the minimal data object**

Create `LevelDefinition.gd`:

```gdscript
class_name LevelDefinition
extends Resource

var level_id: int
var divine_state: String
var weather_intensity: float
var wind_strength: float
var rain_slip: float
var stone_smoothness: float
var par_ascent_seconds: float
var daylight_grace_seconds: float
var hum_phrase_id: String

static func create_storm_vertical_slice() -> LevelDefinition:
	var level := LevelDefinition.new()
	level.level_id = 4
	level.divine_state = "anger"
	level.weather_intensity = 0.72
	level.wind_strength = 0.38
	level.rain_slip = 0.30
	level.stone_smoothness = 0.52
	level.par_ascent_seconds = 420.0
	level.daylight_grace_seconds = 240.0
	level.hum_phrase_id = "ode_motif_4"
	return level
```

- [ ] **Step 4: Run test to verify it passes**

Run the same command. Expected: PASS.

---

### Task 2: Run Metrics and Daylight Reward

**Files:**
- Create: `godot/scripts/RunMetrics.gd`
- Modify: `godot/tests/test_vertical_slice_logic.gd`

- [ ] **Step 1: Write failing tests**

Add:

```gdscript
func test_metrics_compute_daylight_and_hum_clarity() -> void:
	var level = LevelDefinition.create_storm_vertical_slice()
	var metrics = RunMetrics.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 0.9
	metrics.contact_stability = 0.82
	metrics.rollback_count = 1
	metrics.recovery_count = 2
	metrics.finalize(level)
	_expect_true(metrics.daylight_reward > 0.75, "fast ascent should preserve daylight")
	_expect_true(metrics.hum_clarity > 0.65, "stable fast ascent should make hum clearer")

func test_slow_run_still_completes_with_lower_reward() -> void:
	var level = LevelDefinition.create_storm_vertical_slice()
	var metrics = RunMetrics.new()
	metrics.ascent_seconds = level.par_ascent_seconds + level.daylight_grace_seconds * 1.4
	metrics.contact_stability = 0.45
	metrics.rollback_count = 4
	metrics.finalize(level)
	_expect_true(metrics.daylight_reward <= 0.05, "very slow ascent should lose daylight reward")
	_expect_true(metrics.hum_clarity < 0.45, "messy slow ascent should keep hum fragmented")
```

- [ ] **Step 2: Run and confirm failure**

Expected: FAIL because `RunMetrics` is missing.

- [ ] **Step 3: Implement metrics**

Create `RunMetrics.gd` with:

```gdscript
class_name RunMetrics
extends Resource

var ascent_seconds: float = 0.0
var contact_stability: float = 0.0
var rollback_count: int = 0
var recovery_count: int = 0
var daylight_reward: float = 0.0
var hum_clarity: float = 0.0

func finalize(level: LevelDefinition) -> void:
	var late_seconds: float = maxf(0.0, ascent_seconds - level.par_ascent_seconds)
	daylight_reward = clampf(1.0 - late_seconds / maxf(1.0, level.daylight_grace_seconds), 0.0, 1.0)
	var time_score: float = clampf(level.par_ascent_seconds / maxf(1.0, ascent_seconds), 0.0, 1.0)
	var recovery_score: float = clampf(float(recovery_count) / 3.0, 0.0, 1.0)
	var rollback_penalty: float = clampf(float(rollback_count) * 0.08, 0.0, 0.35)
	hum_clarity = clampf(time_score * 0.45 + contact_stability * 0.35 + recovery_score * 0.20 - rollback_penalty, 0.0, 1.0)
```

- [ ] **Step 4: Run test**

Expected: PASS.

---

### Task 3: Level Manager Phase Flow

**Files:**
- Create: `godot/scripts/LevelManager.gd`
- Modify: `godot/tests/test_vertical_slice_logic.gd`

- [ ] **Step 1: Write failing transition tests**

Add:

```gdscript
func test_release_to_descent_preserves_player_position() -> void:
	var manager = LevelManager.new()
	manager.active_level = LevelDefinition.create_storm_vertical_slice()
	manager.phase = "ascent"
	var before := Vector3(0.5, 4.0, -24.0)
	manager.player_position_at_release = before
	manager.mark_released(before)
	_expect_true(manager.phase == "release", "release should be its own transition phase")
	manager.mark_stone_entered_back_slope()
	_expect_true(manager.phase == "descent", "stone on back slope should enter descent")
	_expect_true(manager.player_position_at_release.distance_to(before) < 0.001, "release/descent must not teleport player")
```

- [ ] **Step 2: Run and confirm failure**

Expected: FAIL because `LevelManager` is missing.

- [ ] **Step 3: Implement manager**

Create:

```gdscript
class_name LevelManager
extends Node

var active_level: LevelDefinition
var phase: String = "approach"
var metrics: RunMetrics = RunMetrics.new()
var player_position_at_release: Vector3 = Vector3.ZERO

func start_level(level: LevelDefinition) -> void:
	active_level = level
	phase = "approach"
	metrics = RunMetrics.new()

func mark_ascent_started() -> void:
	phase = "ascent"

func mark_released(player_position: Vector3) -> void:
	player_position_at_release = player_position
	phase = "release"

func mark_stone_entered_back_slope() -> void:
	if phase == "release":
		phase = "descent"

func mark_complete() -> void:
	if active_level != null:
		metrics.finalize(active_level)
	phase = "complete"
```

- [ ] **Step 4: Run test**

Expected: PASS.

---

### Task 4: Trail Recording

**Files:**
- Create: `godot/scripts/TrailRecorder.gd`
- Create: `godot/tests/test_trail_environment_response.gd`

- [ ] **Step 1: Write failing trail tests**

```gdscript
func test_trail_records_spaced_points_only() -> void:
	var recorder = TrailRecorder.new()
	recorder.min_spacing = 0.5
	recorder.record(Vector3(0, 0, 0), 1.0, 0.8)
	recorder.record(Vector3(0.1, 0, 0.1), 1.0, 0.8)
	recorder.record(Vector3(0.0, 0, -0.7), 1.0, 0.8)
	_expect_true(recorder.points.size() == 2, "trail should avoid dense duplicate points")
	_expect_true(recorder.points[0].pressure > 0.9, "trail should retain pressure")
```

- [ ] **Step 2: Implement trail point data**

Create `TrailRecorder.gd`:

```gdscript
class_name TrailRecorder
extends Node

class TrailPoint:
	var position: Vector3
	var pressure: float
	var stability: float
	func _init(next_position: Vector3, next_pressure: float, next_stability: float) -> void:
		position = next_position
		pressure = next_pressure
		stability = next_stability

var min_spacing: float = 0.45
var points: Array[TrailPoint] = []

func clear() -> void:
	points.clear()

func record(position: Vector3, pressure: float, stability: float) -> void:
	if not points.is_empty() and points[-1].position.distance_to(position) < min_spacing:
		return
	points.append(TrailPoint.new(position, pressure, stability))
```

- [ ] **Step 3: Run test**

Expected: PASS.

---

### Task 5: Environment Response Markers

**Files:**
- Create: `godot/scripts/EnvironmentResponse.gd`
- Modify: `godot/tests/test_trail_environment_response.gd`

- [ ] **Step 1: Write failing response tests**

```gdscript
func test_environment_response_spawns_growth_from_trail() -> void:
	var recorder = TrailRecorder.new()
	for index in 6:
		recorder.record(Vector3(0, 0, -float(index)), 1.0, 0.8)
	var response = EnvironmentResponse.new()
	response.build_from_trail(recorder.points, 0.9)
	_expect_true(response.response_points.size() >= 4, "descent should have visible response markers")
	_expect_true(response.response_points[0].kind in ["grass", "flower", "water"], "response kind should be concrete")
```

- [ ] **Step 2: Implement simple response data**

Create:

```gdscript
class_name EnvironmentResponse
extends Node3D

class ResponsePoint:
	var position: Vector3
	var kind: String
	func _init(next_position: Vector3, next_kind: String) -> void:
		position = next_position
		kind = next_kind

var response_points: Array[ResponsePoint] = []

func build_from_trail(points: Array, daylight_reward: float) -> void:
	response_points.clear()
	for index in points.size():
		var trail_point = points[index]
		var kind := "grass"
		if daylight_reward > 0.7 and index % 3 == 0:
			kind = "flower"
		elif trail_point.stability < 0.45:
			kind = "water"
		response_points.append(ResponsePoint.new(trail_point.position, kind))
```

- [ ] **Step 3: Add visible placeholder meshes**

Extend `build_from_trail()` to add small `MeshInstance3D` markers:

```gdscript
var mesh := SphereMesh.new()
mesh.radius = 0.08
mesh.height = 0.16
var marker := MeshInstance3D.new()
marker.mesh = mesh
marker.position = trail_point.position + Vector3.UP * 0.05
add_child(marker)
```

- [ ] **Step 4: Run test**

Expected: PASS.

---

### Task 6: Weather Controller

**Files:**
- Create: `godot/scripts/WeatherController.gd`
- Modify: `godot/tests/test_vertical_slice_logic.gd`

- [ ] **Step 1: Write failing weather test**

```gdscript
func test_weather_uses_divine_pressure_without_changing_level_identity() -> void:
	var level = LevelDefinition.create_storm_vertical_slice()
	var weather = WeatherController.new()
	weather.apply_level(level, 0.25)
	_expect_true(weather.active_intensity > level.weather_intensity, "mastery should provoke stronger storm pressure")
	_expect_true(weather.active_intensity <= 1.0, "weather intensity should stay bounded")
```

- [ ] **Step 2: Implement bounded weather state**

```gdscript
class_name WeatherController
extends Node3D

var active_intensity: float = 0.0
var active_wind: float = 0.0
var active_rain_slip: float = 0.0

func apply_level(level: LevelDefinition, mastery_pressure: float) -> void:
	active_intensity = clampf(level.weather_intensity + mastery_pressure, 0.0, 1.0)
	active_wind = clampf(level.wind_strength + mastery_pressure * 0.4, 0.0, 1.0)
	active_rain_slip = clampf(level.rain_slip + mastery_pressure * 0.2, 0.0, 0.65)
```

- [ ] **Step 3: Add placeholder visuals**

For vertical slice, add simple fog/light/rain placeholders in `VerticalSlice.tscn`; final particles can wait.

- [ ] **Step 4: Run test**

Expected: PASS.

---

### Task 7: Humming Progression

**Files:**
- Create: `godot/scripts/HummingController.gd`
- Create: `godot/tests/test_humming_progression.gd`

- [ ] **Step 1: Write failing hum clarity tests**

```gdscript
func test_humming_phrase_clarity_tracks_metrics() -> void:
	var level = LevelDefinition.create_storm_vertical_slice()
	var metrics = RunMetrics.new()
	metrics.ascent_seconds = level.par_ascent_seconds * 0.95
	metrics.contact_stability = 0.9
	metrics.recovery_count = 1
	metrics.finalize(level)
	var hum = HummingController.new()
	hum.apply_result(level, metrics)
	_expect_true(hum.active_phrase_id == "ode_motif_4", "hum should use level phrase")
	_expect_true(hum.clarity > 0.65, "strong run should produce clearer hum")
```

- [ ] **Step 2: Implement presentation-only hum state**

```gdscript
class_name HummingController
extends Node

var active_phrase_id: String = ""
var clarity: float = 0.0
var storm_ducking: float = 0.0

func apply_result(level: LevelDefinition, metrics: RunMetrics) -> void:
	active_phrase_id = level.hum_phrase_id
	clarity = metrics.hum_clarity
	storm_ducking = clampf(clarity * 0.35, 0.0, 0.35)
```

- [ ] **Step 3: Add non-final audio placeholder**

Use generated hum tones or existing procedural audio only. Do not import copyrighted recordings.

- [ ] **Step 4: Run test**

Expected: PASS.

---

### Task 8: VerticalSlice Scene Assembly

**Files:**
- Create: `godot/scenes/VerticalSlice.tscn`
- Modify: `godot/README.md`
- Modify: `godot/tests/test_main_start.gd` or create a new startup check

- [ ] **Step 1: Write scene startup test**

Add:

```gdscript
func test_vertical_slice_scene_loads() -> void:
	_expect_true(ResourceLoader.exists("res://scenes/VerticalSlice.tscn"), "VerticalSlice scene should exist")
	var scene: PackedScene = load("res://scenes/VerticalSlice.tscn")
	var node = scene.instantiate()
	root.add_child(node)
	await physics_frame
	_expect_true(node.get_node_or_null("Player") != null, "vertical slice needs player")
	_expect_true(node.get_node_or_null("Stone") != null, "vertical slice needs stone")
	_expect_true(node.get_node_or_null("Mountain") != null, "vertical slice needs mountain")
	node.queue_free()
```

- [ ] **Step 2: Create scene**

Duplicate the working composition pattern from `Main.tscn` or `PushLab.tscn`; attach `LevelManager`, `TrailRecorder`, `EnvironmentResponse`, `WeatherController`, and `HummingController`.

- [ ] **Step 3: Add command**

Add to README:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn
```

- [ ] **Step 4: Run startup test**

Expected: PASS.

---

### Task 9: End-to-End Loop Smoke Test

**Files:**
- Create: `godot/tests/test_vertical_slice_smoke.gd`

- [ ] **Step 1: Write smoke test**

The test should simulate phase calls rather than rely on a full 10-minute playthrough:

```gdscript
func test_vertical_slice_loop_contract() -> void:
	var manager = LevelManager.new()
	var level = LevelDefinition.create_storm_vertical_slice()
	manager.start_level(level)
	manager.mark_ascent_started()
	_expect_true(manager.phase == "ascent", "level should enter ascent")
	manager.mark_released(Vector3.ZERO)
	manager.mark_stone_entered_back_slope()
	_expect_true(manager.phase == "descent", "release should lead to descent")
	manager.metrics.ascent_seconds = level.par_ascent_seconds
	manager.metrics.contact_stability = 0.75
	manager.mark_complete()
	_expect_true(manager.phase == "complete", "level should complete")
	_expect_true(manager.metrics.hum_clarity > 0.0, "completion should finalize metrics")
```

- [ ] **Step 2: Run smoke test**

Expected: PASS.

---

### Task 10: Visual Verification

**Files:**
- Modify: `godot/README.md`
- Update: `production/milestones/steam-roadmap.md` if scope changes.

- [ ] **Step 1: Launch vertical slice**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/haodong/Documents/GitHub/Sisyphus/godot --scene res://scenes/VerticalSlice.tscn
```

- [ ] **Step 2: Capture required states**

Use Godot AI MCP if exposed; otherwise use Computer Use screenshots.

Required visual evidence:
- approach to stone
- active push with storm state
- left/right biased contact
- ridge release
- descent with trail response
- hum reward / HUD clarity state

- [ ] **Step 3: Record assessment**

Create or update:

```text
prototypes/vertical-slice-loop/REPORT.md
```

Verdict options:
- `PROCEED`: build the remaining 6 levels.
- `PIVOT`: keep concept but change core implementation or scope.
- `KILL`: stop Steam production because core loop does not support the premise.

---

## Verification Commands

Run after implementing each relevant task:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_vertical_slice_logic.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_trail_environment_response.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_humming_progression.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_contact_push_physics.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --script tests/test_player_behavior.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/haodong/Documents/GitHub/Sisyphus/godot --quit-after 120
```

---

## Spec Coverage Check

- Steam objective: covered by roadmap and vertical-slice gate.
- 7-level same-mountain structure: covered by `game-concept.md` and roadmap alpha skeleton.
- Push physics: preserved through existing push-lab and contact tests.
- Descent as play: explicit in LevelManager and vertical slice requirements.
- Environment response: TrailRecorder and EnvironmentResponse tasks.
- Humming / `Ode to Joy`: HummingController task, with legal warning.
- Divine escalation/weather: WeatherController task.
- Stone evolution: included in LevelDefinition now; later requires its own system GDD.
- Release readiness: deferred to milestones 4-5 with explicit gates.

No implementation step should claim Steam readiness until Milestone 5 exit criteria pass.
