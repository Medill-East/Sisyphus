extends Node3D

const TuningScript = preload("res://scripts/Tuning.gd")
const GameStateScript = preload("res://scripts/GameState.gd")
const LevelDefinitionScript = preload("res://scripts/LevelDefinition.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")
const RouteTelemetryScript = preload("res://scripts/RouteTelemetry.gd")
const PlaytestReportBuilderScript = preload("res://scripts/PlaytestReportBuilder.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"
const CHAPTER_END_HOLD_SECONDS := 6.0

var tuning = TuningScript.new()
var game_state = GameStateScript.new()
var route_telemetry = RouteTelemetryScript.new()

@onready var mountain = $Mountain
@onready var player = $Player
@onready var stone: RigidBody3D = $Stone
@onready var camera: Camera3D = $Camera3D
@onready var level_manager = $LevelManager
@onready var trail_recorder = $TrailRecorder
@onready var environment_response = $EnvironmentResponse
@onready var weather_controller = $WeatherController
@onready var humming_controller = $HummingController
@onready var hum_player: AudioStreamPlayer = $HumPlayer
@onready var chapter_end_markers: Node3D = $ChapterEndMarkers
@onready var chapter_end_storm_shards: Node3D = $ChapterEndMarkers/StormShards
@onready var chapter_end_light_crack_marker: MeshInstance3D = $ChapterEndMarkers/LightCrack
@onready var status_label: Label = $HUD/Status
@onready var prompt_label: Label = $HUD/Prompt
@onready var telemetry_label: Label = $HUD/Telemetry
@onready var pause_menu: Control = $HUD/PauseMenu
@onready var resume_button: Button = $HUD/PauseMenu/Panel/Content/ResumeButton
@onready var main_menu_button: Button = $HUD/PauseMenu/Panel/Content/MainMenuButton
@onready var quit_button: Button = $HUD/PauseMenu/Panel/Content/QuitButton

var visual_mode: String = ""
var visual_loop_time: float = 0.0
var visual_loop_stage: String = ""
var route_smoke_time: float = 0.0
var route_smoke_teleport_count: int = 0
var route_smoke_max_lateral_offset: float = 0.0
var route_smoke_bias_recovered: bool = false
var route_checkpoint: String = "front"
var _route_smoke_bias_peak_seen: bool = false
var chapter_end_active: bool = false
var chapter_end_elapsed_seconds: float = 0.0
var chapter_end_storm_pressure: float = 0.0
var chapter_end_light_crack_strength: float = 0.0
var playtest_report_path: String = "/Users/haodong/Documents/GitHub/Sisyphus/production/qa/playtests/playtest-manual-snapshot.md"
var playtest_tester_id: String = "manual"
var pacing_profile: String = "smoke"
var last_playtest_report_path: String = ""
var last_playtest_screenshot_path: String = ""
var last_playtest_report_saved: bool = false
var last_playtest_report_error: int = OK
var last_playtest_screenshot_error: int = OK


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_setup_pause_menu()
	_parse_args()
	_apply_pacing_profile_to_tuning()
	game_state.tuning = tuning
	game_state.phase = GameStateScript.Phase.APPROACH
	route_telemetry.reset()
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	level_manager.start_level(level)
	weather_controller.apply_level(level, 0.0)
	mountain.tuning = tuning
	mountain.build()
	_place_starting_actors()
	player.setup(tuning, mountain, game_state, stone, camera)
	_apply_stone_physics(level)
	if visual_mode != "":
		player.set_physics_process(false)
		apply_visual_mode(visual_mode)
	_update_hud()


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if visual_mode != "":
		if visual_mode == "loop":
			advance_visual_loop(delta)
		elif visual_mode == "route":
			advance_route_smoke(delta)
		elif game_state.phase == GameStateScript.Phase.COMPLETE:
			advance_chapter_end_hold(delta)
		_update_hud()
		return
	_advance_gameplay_state(delta)
	_update_hud()


func _exit_tree() -> void:
	_release_hum_audio()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("save_playtest_report"):
		save_playtest_report(playtest_report_path, playtest_tester_id)


func _setup_pause_menu() -> void:
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.visible = false
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(resume_game)
	main_menu_button.pressed.connect(return_to_main_menu)
	quit_button.pressed.connect(quit_game)


func main_menu_scene_path() -> String:
	return MAIN_MENU_SCENE_PATH


func pause_game() -> void:
	pause_menu.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	resume_button.grab_focus()


func resume_game() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func return_to_main_menu() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func quit_game() -> void:
	get_tree().quit()


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--vs-auto="):
			visual_mode = arg.trim_prefix("--vs-auto=")
		elif arg.begins_with("--playtest-report-path="):
			playtest_report_path = arg.trim_prefix("--playtest-report-path=")
		elif arg.begins_with("--playtest-tester-id="):
			playtest_tester_id = arg.trim_prefix("--playtest-tester-id=")
		elif arg.begins_with("--slice-pacing="):
			pacing_profile = arg.trim_prefix("--slice-pacing=")


func apply_pacing_profile(profile_name: String) -> void:
	pacing_profile = profile_name
	_apply_pacing_profile_to_tuning()
	if game_state != null:
		game_state.tuning = tuning
	if mountain != null:
		mountain.tuning = tuning
		mountain.build()
	if player != null:
		player.tuning = tuning
	if level_manager != null and level_manager.active_level != null:
		level_manager.active_level.par_ascent_seconds = maxf(level_manager.active_level.par_ascent_seconds, tuning.estimated_loop_seconds_for_current_pacing() * 0.72)
	if mountain != null and stone != null and player != null:
		_place_starting_actors()


func _apply_pacing_profile_to_tuning() -> void:
	if tuning.has_method("apply_vertical_slice_pacing_profile"):
		tuning.apply_vertical_slice_pacing_profile(pacing_profile)
		pacing_profile = tuning.pacing_profile_name


func apply_visual_mode(mode: String) -> void:
	visual_mode = mode
	if player != null:
		player.set_physics_process(mode.is_empty())
	match mode:
		"approach":
			_apply_approach_visual()
		"push":
			_apply_push_visual(Vector3.ZERO)
		"left":
			_apply_push_visual(Vector3.LEFT * 0.95)
		"right":
			_apply_push_visual(Vector3.RIGHT * 0.95)
		"release":
			_apply_release_visual()
		"descent":
			_apply_descent_visual(false)
		"hum":
			_apply_descent_visual(true)
		"complete":
			_apply_complete_visual()
		"loop":
			_apply_loop_visual()
		"route":
			_apply_route_smoke_visual()
		_:
			_apply_approach_visual()
	_update_hud()


func advance_visual_loop(delta: float) -> void:
	if visual_mode != "loop":
		visual_mode = "loop"
	visual_loop_time += delta
	if visual_loop_time < 1.0:
		if visual_loop_stage != "approach":
			visual_loop_stage = "approach"
			_apply_approach_visual()
	elif visual_loop_time < 2.2:
		if visual_loop_stage != "ascent":
			visual_loop_stage = "ascent"
			_apply_push_visual(Vector3.ZERO)
		_record_loop_trail_sample(visual_loop_time - 1.0)
	elif visual_loop_time < 3.2:
		if visual_loop_stage != "release":
			visual_loop_stage = "release"
			_apply_release_visual()
	elif visual_loop_time < 4.1:
		if visual_loop_stage != "descent":
			visual_loop_stage = "descent"
			_apply_descent_visual(false)
	elif visual_loop_time < 5.0:
		if visual_loop_stage != "hum":
			visual_loop_stage = "hum"
			_apply_descent_visual(true)
	else:
		if visual_loop_stage != "complete":
			visual_loop_stage = "complete"
			_apply_complete_visual()
	_update_hud()


func _apply_loop_visual() -> void:
	visual_loop_time = 0.0
	visual_loop_stage = "approach"
	_apply_approach_visual()


func _apply_route_smoke_visual() -> void:
	visual_mode = "route"
	route_checkpoint = "front"
	route_smoke_time = 0.0
	route_smoke_teleport_count = 0
	route_smoke_max_lateral_offset = 0.0
	route_smoke_bias_recovered = false
	_route_smoke_bias_peak_seen = false
	_reset_chapter_end_hold()
	game_state.reset()
	game_state.tuning = tuning
	route_telemetry.reset()
	level_manager.start_level(level_manager.active_level)
	trail_recorder.clear()
	environment_response.clear_response()
	humming_controller.clarity = 0.0
	_stop_hum_reward()
	stone.freeze = true
	_place_starting_actors()
	player.set_physics_process(false)
	player.reset_to_third_person_idle_pose()
	player.push_contact_seconds = 0.0
	camera.global_position = player.global_position + Vector3(1.35, 1.65, 3.25)
	camera.look_at(stone.global_position + Vector3.UP * 0.55, Vector3.UP)


func apply_route_checkpoint(checkpoint_name: String) -> void:
	route_checkpoint = checkpoint_name
	match checkpoint_name:
		"mid":
			_seed_route_ascent_checkpoint(0.52, checkpoint_name)
		"ridge":
			_seed_route_ascent_checkpoint(0.97, checkpoint_name)
		"descent":
			_seed_route_descent_checkpoint()
		_:
			route_checkpoint = "front"


func _seed_route_ascent_checkpoint(progress: float, checkpoint_name: String) -> void:
	route_checkpoint = checkpoint_name
	route_smoke_time = 0.0
	route_smoke_max_lateral_offset = 0.0
	route_smoke_bias_recovered = false
	_route_smoke_bias_peak_seen = false
	game_state.reset()
	game_state.tuning = tuning
	game_state.phase = GameStateScript.Phase.ASCENT
	route_telemetry.reset()
	level_manager.start_level(level_manager.active_level)
	level_manager.mark_ascent_started()
	trail_recorder.clear()
	environment_response.clear_response()
	humming_controller.clarity = 0.0
	_stop_hum_reward()
	var start_z: float = tuning.front_base_z + 1.1
	var target_z: float = tuning.ridge_z - tuning.stone_radius * 0.35
	var stone_z: float = lerpf(start_z, target_z, clampf(progress, 0.0, 1.0))
	stone.freeze = false
	stone.global_position = Vector3(0.0, mountain.height_at(stone_z) + tuning.stone_radius + 0.12, stone_z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	player.global_position = _route_contact_position()
	player.push_contact_seconds = tuning.push_force_ramp_seconds
	player.push_engaged = true
	player.camera_push_blend = 1.0
	player.push_frame = null
	player.update_push_visual_mode()
	camera.global_position = player.global_position + Vector3(1.35, 1.65, 3.25)
	camera.look_at(stone.global_position + Vector3.UP * 0.55, Vector3.UP)


func _seed_route_descent_checkpoint() -> void:
	route_checkpoint = "descent"
	route_smoke_time = 0.0
	route_smoke_max_lateral_offset = 0.0
	route_smoke_bias_recovered = true
	_route_smoke_bias_peak_seen = true
	game_state.reset()
	game_state.tuning = tuning
	game_state.phase = GameStateScript.Phase.DESCENT
	route_telemetry.reset()
	level_manager.start_level(level_manager.active_level)
	level_manager.mark_ascent_started()
	level_manager.mark_released(Vector3.ZERO)
	level_manager.mark_stone_entered_back_slope()
	trail_recorder.clear()
	environment_response.clear_response()
	var stone_z: float = tuning.back_base_z + 4.0
	stone.freeze = false
	stone.global_position = Vector3(0.0, mountain.height_at(stone_z) + tuning.stone_radius + 0.12, stone_z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	var player_z: float = minf(tuning.ridge_z - 12.0, stone_z + 16.0)
	player.global_position = Vector3(0.0, mountain.height_at(player_z) + 0.05, player_z)
	player.push_contact_seconds = 0.0
	player.push_engaged = false
	player.push_frame = null
	player.reset_to_third_person_idle_pose()
	camera.global_position = player.global_position + Vector3(1.35, 1.65, 3.25)
	camera.look_at(stone.global_position + Vector3.UP * 0.55, Vector3.UP)


func advance_route_smoke(delta: float) -> void:
	route_smoke_time += delta
	if game_state.phase == GameStateScript.Phase.APPROACH:
		_move_route_player_toward(_route_contact_position(), tuning.walk_speed * 1.8, delta)
	elif game_state.phase == GameStateScript.Phase.ASCENT:
		_move_route_player_toward(_route_contact_position(), tuning.walk_speed * 1.8, delta)
		var uphill: Vector3 = mountain.uphill_tangent_at(stone.global_position.z)
		var aim_bias: Vector3 = _route_smoke_aim_bias()
		var camera_direction: Vector3 = (uphill + aim_bias).normalized()
		player.push_engaged = true
		player.camera_push_blend = 1.0
		player.push_contact_seconds += delta
		player.push_frame = player.apply_reticle_aligned_push(camera_direction, true, aim_bias.x, player.push_contact_seconds)
		_update_route_smoke_bias_metrics()
		player.update_push_visual_mode()
	elif game_state.phase == GameStateScript.Phase.RELEASE:
		player.push_contact_seconds = 0.0
		player.reset_to_third_person_idle_pose()
	elif game_state.phase == GameStateScript.Phase.DESCENT:
		player.push_contact_seconds = 0.0
		player.reset_to_third_person_idle_pose()
		_move_route_player_toward(_route_descent_target(), tuning.walk_speed * 1.2, delta)
	elif game_state.phase == GameStateScript.Phase.COMPLETE:
		player.push_contact_seconds = 0.0
		player.reset_to_third_person_idle_pose()
	if game_state.phase == GameStateScript.Phase.COMPLETE:
		advance_chapter_end_hold(delta)
	else:
		_update_route_camera(delta)
	_advance_gameplay_state(delta)


func _route_smoke_aim_bias() -> Vector3:
	var ascent_distance: float = _route_ascent_distance_from_start()
	if ascent_distance >= 6.5 and ascent_distance <= 15.0:
		return Vector3.RIGHT * 0.30
	if ascent_distance > 15.0 and ascent_distance <= 34.0:
		return Vector3.RIGHT * clampf(-stone.global_position.x * 1.05, -0.62, 0.62)
	if _route_smoke_bias_peak_seen:
		return Vector3.RIGHT * clampf(-stone.global_position.x * 0.55, -0.40, 0.40)
	return Vector3.ZERO


func _update_route_smoke_bias_metrics() -> void:
	var lateral_offset: float = absf(stone.global_position.x)
	route_smoke_max_lateral_offset = maxf(route_smoke_max_lateral_offset, lateral_offset)
	if route_smoke_max_lateral_offset > 0.24:
		_route_smoke_bias_peak_seen = true
	if _route_smoke_bias_peak_seen and lateral_offset < 0.20:
		if _route_ascent_distance_from_start() > 18.0:
			route_smoke_bias_recovered = true


func _route_ascent_distance_from_start() -> float:
	var route_start_z: float = tuning.front_base_z + 1.1
	return maxf(0.0, route_start_z - stone.global_position.z)


func _apply_approach_visual() -> void:
	_reset_chapter_end_hold()
	game_state.phase = GameStateScript.Phase.APPROACH
	level_manager.phase = "approach"
	_stop_hum_reward()
	stone.freeze = true
	_place_starting_actors()
	player.reset_to_third_person_idle_pose()
	camera.global_position = player.global_position + Vector3(1.2, 1.45, 3.0)
	camera.look_at(stone.global_position + Vector3.UP * 0.55, Vector3.UP)


func _apply_push_visual(aim_bias: Vector3) -> void:
	_reset_chapter_end_hold()
	game_state.phase = GameStateScript.Phase.ASCENT
	level_manager.mark_ascent_started()
	_stop_hum_reward()
	stone.freeze = false
	var z: float = tuning.front_base_z - 6.0
	stone.global_position = Vector3(0.0, mountain.height_at(z) + tuning.stone_radius + 0.08, z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	player.global_position = stone.global_position + downhill * tuning.stone_radius * 1.55
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05
	var camera_direction: Vector3 = (mountain.uphill_tangent_at(stone.global_position.z) + aim_bias).normalized()
	var frame = player.calculate_reticle_aligned_push_frame(camera_direction, true, aim_bias.x, 999.0)
	player.push_frame = frame
	player.push_engaged = true
	player.push_contact_seconds = tuning.first_person_hands_min_contact_seconds + 0.05
	player.camera_push_blend = 1.0
	player.update_push_visual_mode()
	player._near_stone = true
	player._is_walking = true
	player._update_arm_visual(1.0 / 60.0, frame.aim_direction)
	_position_push_visual_camera(frame.aim_direction, frame.camera_contact_point)
	player._update_first_person_hands(frame.aim_direction)


func _position_push_visual_camera(camera_direction: Vector3, contact_point: Vector3) -> void:
	if camera == null or player == null:
		return
	camera.global_position = player.push_camera_origin_for(
		camera_direction,
		contact_point,
		stone.global_position,
		player.camera_push_blend
	)
	camera.fov = tuning.push_camera_fov
	var aim_direction: Vector3 = camera_direction.normalized()
	if aim_direction.length_squared() < 0.001:
		aim_direction = mountain.uphill_tangent_at(stone.global_position.z)
	camera.look_at(contact_point, Vector3.UP)


func _apply_release_visual() -> void:
	_reset_chapter_end_hold()
	game_state.phase = GameStateScript.Phase.RELEASE
	_stop_hum_reward()
	var z: float = tuning.ridge_z + 0.6
	stone.global_position = Vector3(0.0, mountain.height_at(z) + tuning.stone_radius + 0.08, z)
	stone.linear_velocity = mountain.downhill_tangent_at(z) * 0.85
	stone.angular_velocity = Vector3.ZERO
	stone.freeze = false
	player.global_position = Vector3(-0.9, mountain.height_at(z + 1.3) + 0.05, z + 1.3)
	player.reset_to_third_person_idle_pose()
	level_manager.mark_released(player.global_position)
	camera.global_position = player.global_position + Vector3(1.3, 1.7, 2.2)
	camera.look_at(stone.global_position + Vector3.UP * 0.6, Vector3.UP)


func _apply_descent_visual(force_clear_hum: bool) -> void:
	_reset_chapter_end_hold()
	game_state.phase = GameStateScript.Phase.DESCENT
	level_manager.mark_released(player.global_position)
	level_manager.mark_stone_entered_back_slope()
	seed_descent_response(force_clear_hum)
	var z: float = tuning.ridge_z - 9.0
	player.global_position = Vector3(0.0, mountain.height_at(z) + 0.05, z)
	stone.global_position = Vector3(0.6, mountain.height_at(z - 5.0) + tuning.stone_radius + 0.08, z - 5.0)
	stone.freeze = false
	player.reset_to_third_person_idle_pose()
	_focus_descent_camera_on_response()


func _apply_complete_visual() -> void:
	_apply_descent_visual(true)
	var stone_z: float = tuning.back_base_z + 1.4
	stone.global_position = Vector3(0.65, mountain.height_at(stone_z) + tuning.stone_radius + 0.08, stone_z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	stone.freeze = true
	var player_z: float = stone_z + 1.15
	player.global_position = Vector3(0.0, mountain.height_at(player_z) + 0.05, player_z)
	player.reset_to_third_person_idle_pose()
	game_state.phase = GameStateScript.Phase.COMPLETE
	level_manager.mark_complete()
	route_telemetry.current_phase = game_state.label()
	_begin_chapter_end_hold()
	camera.global_position = player.global_position + Vector3(1.35, 1.45, 2.45)
	camera.look_at(stone.global_position + Vector3.UP * 0.48, Vector3.UP)


func _advance_gameplay_state(delta: float) -> void:
	var previous_phase: int = game_state.phase
	game_state.advance(delta, player.global_position, stone.global_position, stone.linear_velocity)
	if previous_phase != game_state.phase:
		_on_game_phase_changed(game_state.phase)
	if game_state.phase == GameStateScript.Phase.ASCENT:
		trail_recorder.record(stone.global_position, stone.mass, _contact_stability())
		level_manager.metrics.ascent_seconds += delta
		level_manager.metrics.contact_stability = maxf(level_manager.metrics.contact_stability, _contact_stability())
	var wants_push: bool = game_state.phase == GameStateScript.Phase.ASCENT and (
		maxf(Input.get_action_strength("push_left"), Input.get_action_strength("push_right")) > 0.001
		or visual_mode == "route"
	)
	route_telemetry.sample(
		delta,
		game_state.label(),
		wants_push,
		player.push_frame,
		player.global_position,
		stone.global_position,
		tuning
	)
	if game_state.phase == GameStateScript.Phase.COMPLETE:
		advance_chapter_end_hold(delta)


func _reset_chapter_end_hold() -> void:
	chapter_end_active = false
	chapter_end_elapsed_seconds = 0.0
	chapter_end_storm_pressure = 0.0
	chapter_end_light_crack_strength = 0.0
	_set_chapter_end_markers_visible(false)


func _begin_chapter_end_hold() -> void:
	chapter_end_active = true
	chapter_end_elapsed_seconds = 0.0
	chapter_end_storm_pressure = 0.62
	chapter_end_light_crack_strength = 0.18
	_set_chapter_end_markers_visible(true)
	player.reset_to_third_person_idle_pose()
	stone.freeze = true
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO


func advance_chapter_end_hold(delta: float) -> void:
	if not chapter_end_active:
		return
	chapter_end_elapsed_seconds += maxf(0.0, delta)
	chapter_end_storm_pressure = clampf(0.62 + chapter_end_elapsed_seconds / CHAPTER_END_HOLD_SECONDS * 0.26, 0.0, 1.0)
	chapter_end_light_crack_strength = clampf(0.18 + sin(chapter_end_elapsed_seconds * 0.8) * 0.04, 0.08, 0.24)
	_update_chapter_end_markers()
	_update_chapter_end_camera(delta)


func chapter_end_status() -> Dictionary:
	var audio_mix: Dictionary = humming_controller.chapter_end_mix_state(chapter_end_storm_pressure)
	return {
		"active": chapter_end_active,
		"elapsed_seconds": chapter_end_elapsed_seconds,
		"target_seconds": CHAPTER_END_HOLD_SECONDS,
		"title": "Chapter I End",
		"next_transition": "Next punishment pending",
		"visual_beat": "returning storm with small light crack",
		"storm_pressure": chapter_end_storm_pressure,
		"light_crack": chapter_end_light_crack_strength,
		"audio_beat": audio_mix.get("audio_beat", "storm remains; hum resists"),
		"storm_audio_presence": audio_mix.get("storm_audio_presence", 0.0),
		"hum_presence": audio_mix.get("hum_presence", 0.0),
		"hum_not_overpowering_storm": audio_mix.get("hum_not_overpowering_storm", false),
		"uses_external_audio": audio_mix.get("uses_external_audio", false),
		"phase": game_state.label(),
		"loop_seconds": route_telemetry.elapsed_seconds,
		"hum_clarity": humming_controller.clarity,
		"trail_points": trail_recorder.points.size(),
		"response_points": environment_response.response_points.size(),
	}


func descent_response_view_status() -> Dictionary:
	var visible_count: int = 0
	var nearest_depth: float = INF
	if camera == null:
		return {
			"visible_response_points": 0,
			"camera_fov": 0.0,
			"nearest_response_depth": 99.0,
		}
	for response_point in environment_response.response_points:
		var local: Vector3 = camera.to_local(response_point.position)
		var depth: float = -local.z
		if depth <= 0.05:
			continue
		var x_ratio: float = absf(local.x) / maxf(0.001, depth)
		var y_ratio: float = absf(local.y) / maxf(0.001, depth)
		if x_ratio <= 0.95 and y_ratio <= 0.72:
			visible_count += 1
			nearest_depth = minf(nearest_depth, depth)
	return {
		"visible_response_points": visible_count,
		"camera_fov": camera.fov,
		"nearest_response_depth": nearest_depth if nearest_depth < INF else 99.0,
	}


func push_view_status() -> Dictionary:
	var hands = player.get_node_or_null("FirstPersonHands") if player != null else null
	var body = player.get_node_or_null("Body") if player != null else null
	var resolved_frame = player.push_frame if player != null else null
	var contact: Vector3 = resolved_frame.camera_contact_point if resolved_frame != null else stone.global_position + Vector3.UP * 0.55
	var stone_local := Vector3.ZERO
	var contact_local := Vector3.ZERO
	var left_local := Vector3.ZERO
	var right_local := Vector3.ZERO
	var left_forearm_local := Vector3.ZERO
	var right_forearm_local := Vector3.ZERO
	var hand_radius: float = 0.0
	var forearm_radius: float = 0.0
	var minimum_hand_surface_clearance: float = 99.0
	var nearest_hand_to_contact: float = 99.0
	var minimum_forearm_surface_clearance: float = 99.0
	var contact_cue_status: Dictionary = {
		"visible": false,
		"contact_distance": 99.0,
		"camera_x_ratio": 99.0,
		"force_length": 0.0,
	}
	var route_visibility: Dictionary = _route_edge_visibility_status()
	if camera != null:
		camera.force_update_transform()
		stone_local = camera.to_local(stone.global_position)
		contact_local = camera.to_local(contact)
	if camera != null and hands != null:
		var left_hand: Node3D = hands.get_node_or_null("LeftHand")
		var right_hand: Node3D = hands.get_node_or_null("RightHand")
		var left_forearm: Node3D = hands.get_node_or_null("LeftForearm")
		var right_forearm: Node3D = hands.get_node_or_null("RightForearm")
		if left_hand != null:
			left_local = camera.to_local(left_hand.global_position)
			hand_radius = maxf(hand_radius, _hand_visual_radius(left_hand))
			nearest_hand_to_contact = minf(nearest_hand_to_contact, left_hand.global_position.distance_to(contact))
			minimum_hand_surface_clearance = minf(
				minimum_hand_surface_clearance,
				left_hand.global_position.distance_to(stone.global_position) - tuning.stone_radius - _hand_visual_radius(left_hand)
			)
		if right_hand != null:
			right_local = camera.to_local(right_hand.global_position)
			hand_radius = maxf(hand_radius, _hand_visual_radius(right_hand))
			nearest_hand_to_contact = minf(nearest_hand_to_contact, right_hand.global_position.distance_to(contact))
			minimum_hand_surface_clearance = minf(
				minimum_hand_surface_clearance,
				right_hand.global_position.distance_to(stone.global_position) - tuning.stone_radius - _hand_visual_radius(right_hand)
			)
		if left_forearm != null:
			left_forearm_local = camera.to_local(left_forearm.global_position)
			var left_forearm_radius: float = _forearm_visual_radius(left_forearm)
			forearm_radius = maxf(forearm_radius, left_forearm_radius)
			minimum_forearm_surface_clearance = minf(
				minimum_forearm_surface_clearance,
				_forearm_segment_distance_to_stone(left_forearm, stone.global_position) - tuning.stone_radius - left_forearm_radius
			)
		if right_forearm != null:
			right_forearm_local = camera.to_local(right_forearm.global_position)
			var right_forearm_radius: float = _forearm_visual_radius(right_forearm)
			forearm_radius = maxf(forearm_radius, right_forearm_radius)
			minimum_forearm_surface_clearance = minf(
				minimum_forearm_surface_clearance,
				_forearm_segment_distance_to_stone(right_forearm, stone.global_position) - tuning.stone_radius - right_forearm_radius
			)
	var contact_cue = player.get_node_or_null("ContactCue") if player != null else null
	if contact_cue != null and contact_cue.has_method("status"):
		contact_cue_status = contact_cue.call("status", camera, contact)
	var camera_forward := Vector3.ZERO
	if camera != null:
		camera_forward = -camera.global_transform.basis.z.normalized()
	return {
		"push_blend": player.camera_push_blend if player != null else 0.0,
		"hands_visible": hands != null and hands.visible,
		"body_visible": body != null and body.visible,
		"camera_fov": camera.fov if camera != null else 0.0,
		"camera_forward_y": camera_forward.y,
		"camera_to_contact": camera.global_position.distance_to(contact) if camera != null else 99.0,
		"camera_to_stone": camera.global_position.distance_to(stone.global_position) if camera != null and stone != null else 99.0,
		"stone_camera_x": stone_local.x,
		"stone_camera_depth": absf(stone_local.z),
		"stone_camera_x_ratio": absf(stone_local.x) / maxf(0.001, absf(stone_local.z)),
		"contact_camera_x": contact_local.x,
		"contact_camera_depth": absf(contact_local.z),
		"contact_camera_x_ratio": absf(contact_local.x) / maxf(0.001, absf(contact_local.z)),
		"contact_height_offset": contact.y - stone.global_position.y if stone != null else 0.0,
		"left_hand_camera_x": left_local.x,
		"right_hand_camera_x": right_local.x,
		"left_forearm_camera_x": left_forearm_local.x,
		"right_forearm_camera_x": right_forearm_local.x,
		"hand_radius": hand_radius,
		"forearm_radius": forearm_radius,
		"nearest_hand_to_contact": nearest_hand_to_contact,
		"minimum_hand_surface_clearance": minimum_hand_surface_clearance,
		"minimum_forearm_surface_clearance": minimum_forearm_surface_clearance,
		"contact_cue_visible": bool(contact_cue_status.get("visible", false)),
		"contact_cue_to_contact": float(contact_cue_status.get("contact_distance", 99.0)),
		"contact_cue_camera_x_ratio": float(contact_cue_status.get("camera_x_ratio", 99.0)),
		"contact_cue_force_length": float(contact_cue_status.get("force_length", 0.0)),
		"visible_left_route_markers": int(route_visibility.get("left", 0)),
		"visible_right_route_markers": int(route_visibility.get("right", 0)),
		"route_edge_camera_x_ratio": float(route_visibility.get("max_x_ratio", 99.0)),
	}


func _route_edge_visibility_status() -> Dictionary:
	var result: Dictionary = {
		"left": 0,
		"right": 0,
		"max_x_ratio": 99.0,
	}
	if camera == null:
		return result
	var marker_root = get_node_or_null("Mountain/RouteEdgeMarkers")
	if marker_root == null:
		return result
	var max_ratio: float = 0.0
	for child in marker_root.get_children():
		if not (child is Node3D):
			continue
		var marker: Node3D = child
		var local: Vector3 = camera.to_local(marker.global_position)
		if local.z >= -0.1:
			continue
		var depth: float = absf(local.z)
		var x_ratio: float = absf(local.x) / maxf(0.001, depth)
		var y_ratio: float = absf(local.y) / maxf(0.001, depth)
		if x_ratio > 1.15 or y_ratio > 0.82:
			continue
		max_ratio = maxf(max_ratio, x_ratio)
		if marker.global_position.x < 0.0:
			result["left"] = int(result["left"]) + 1
		else:
			result["right"] = int(result["right"]) + 1
	if int(result["left"]) > 0 or int(result["right"]) > 0:
		result["max_x_ratio"] = max_ratio
	return result


func _hand_visual_radius(hand: Node3D) -> float:
	if hand is MeshInstance3D:
		var mesh_instance: MeshInstance3D = hand
		if mesh_instance.mesh is SphereMesh:
			return mesh_instance.mesh.radius * maxf(mesh_instance.scale.x, maxf(mesh_instance.scale.y, mesh_instance.scale.z))
	return 0.11


func _forearm_visual_radius(forearm: Node3D) -> float:
	if forearm is MeshInstance3D:
		var mesh_instance: MeshInstance3D = forearm
		if mesh_instance.mesh is CapsuleMesh:
			return mesh_instance.mesh.radius * maxf(mesh_instance.scale.x, maxf(mesh_instance.scale.z, 1.0))
	return 0.05


func _forearm_segment_distance_to_stone(forearm: Node3D, stone_position: Vector3) -> float:
	if not (forearm is MeshInstance3D):
		return forearm.global_position.distance_to(stone_position)
	var mesh_instance: MeshInstance3D = forearm
	var length: float = mesh_instance.scale.y
	if mesh_instance.mesh is CapsuleMesh:
		length = mesh_instance.mesh.height * mesh_instance.scale.y
	var axis: Vector3 = mesh_instance.global_transform.basis.y.normalized()
	if axis.length_squared() < 0.001:
		return mesh_instance.global_position.distance_to(stone_position)
	var start: Vector3 = mesh_instance.global_position - axis * length * 0.5
	var end: Vector3 = mesh_instance.global_position + axis * length * 0.5
	var segment: Vector3 = end - start
	var t: float = 0.0
	if segment.length_squared() > 0.001:
		t = clampf((stone_position - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	var closest: Vector3 = start + segment * t
	return closest.distance_to(stone_position)


func _set_chapter_end_markers_visible(is_visible: bool) -> void:
	if chapter_end_markers != null:
		chapter_end_markers.visible = is_visible
	if chapter_end_storm_shards != null:
		chapter_end_storm_shards.visible = is_visible
		for child in chapter_end_storm_shards.get_children():
			if child is Node3D:
				child.visible = is_visible
	if chapter_end_light_crack_marker != null:
		chapter_end_light_crack_marker.visible = is_visible


func _update_chapter_end_markers() -> void:
	_set_chapter_end_markers_visible(true)
	if chapter_end_storm_shards != null:
		var index: int = 0
		for child in chapter_end_storm_shards.get_children():
			if child is Node3D:
				var pulse: float = 1.0 + chapter_end_storm_pressure * (0.05 + float(index % 2) * 0.03)
				child.scale = Vector3(pulse, 1.0 + chapter_end_storm_pressure * 0.08, 1.0)
				index += 1
	if chapter_end_light_crack_marker != null:
		chapter_end_light_crack_marker.scale = Vector3(1.0 + chapter_end_light_crack_strength * 0.35, 1.0, 1.0)


func _update_chapter_end_camera(delta: float) -> void:
	if camera == null or stone == null:
		return
	var progress: float = clampf(chapter_end_elapsed_seconds / CHAPTER_END_HOLD_SECONDS, 0.0, 1.0)
	var stone_focus: Vector3 = stone.global_position + Vector3.UP * 0.62
	var route_z: float = lerpf(stone.global_position.z, tuning.ridge_z, 0.42)
	var route_focus: Vector3 = Vector3(
		0.0,
		mountain.height_at(route_z) + 1.0,
		route_z
	)
	var look_target: Vector3 = stone_focus.lerp(route_focus, progress * 0.42)
	var desired: Vector3 = stone.global_position + Vector3(2.4, 1.55, 3.15)
	desired.x += sin(chapter_end_elapsed_seconds * 0.45) * 0.18
	camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-2.6 * maxf(delta, 0.001)))
	camera.look_at(look_target, Vector3.UP)


func _route_contact_position() -> Vector3:
	var downhill: Vector3 = mountain.downhill_tangent_at(stone.global_position.z)
	var position: Vector3 = stone.global_position + downhill * tuning.stone_radius * 1.55
	position.y = mountain.height_at(position.z) + 0.05
	return position


func _route_descent_target() -> Vector3:
	var z: float = maxf(tuning.back_base_z + 2.0, stone.global_position.z + 1.2)
	return Vector3(stone.global_position.x, mountain.height_at(z) + 0.05, z)


func _move_route_player_toward(target: Vector3, speed: float, delta: float) -> void:
	var offset: Vector3 = target - player.global_position
	var max_step: float = maxf(0.01, speed * delta)
	if offset.length() <= max_step:
		player.global_position = target
	else:
		player.global_position += offset.normalized() * max_step
	player.global_position.x = clampf(player.global_position.x, -tuning.path_width * 0.5, tuning.path_width * 0.5)
	player.global_position.z = clampf(player.global_position.z, tuning.back_base_z - 6.0, tuning.front_base_z + 8.0)
	player.global_position.y = mountain.height_at(player.global_position.z) + 0.05


func _update_route_camera(delta: float) -> void:
	var target: Vector3 = stone.global_position + Vector3.UP * 0.55
	var forward: Vector3 = (target - player.global_position).normalized()
	if forward.length_squared() < 0.001:
		forward = Vector3(0.0, 0.0, -1.0)
	var right: Vector3 = Vector3(-forward.z, 0.0, forward.x).normalized()
	var desired: Vector3 = player.global_position - forward * 2.7 + right * 0.75 + Vector3.UP * 1.45
	camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-5.0 * delta))
	camera.look_at(target, Vector3.UP)


func _focus_descent_camera_on_response() -> void:
	if camera == null:
		return
	var focus: Vector3 = player.global_position + Vector3(0.0, 0.8, -4.2)
	if environment_response.response_points.size() > 0:
		var sum := Vector3.ZERO
		for response_point in environment_response.response_points:
			sum += response_point.position
		focus = sum / float(environment_response.response_points.size())
		focus.y += 0.62
	var route_forward := Vector3(0.0, 0.0, -1.0)
	var desired: Vector3 = player.global_position - route_forward * 5.2 + Vector3(2.15, 2.45, 0.0)
	camera.global_position = desired
	camera.fov = maxf(camera.fov, 82.0)
	camera.look_at(focus, Vector3.UP)


func seed_descent_response(force_clear_hum: bool) -> void:
	trail_recorder.clear()
	for index in 8:
		var z: float = tuning.ridge_z - 7.0 - float(index) * 2.2
		var stability: float = 0.82 if index % 3 != 0 else 0.38
		trail_recorder.record(Vector3(0.45 * sin(index), mountain.height_at(z) + 0.03, z), stone.mass, stability)
	level_manager.metrics.ascent_seconds = level_manager.active_level.par_ascent_seconds * (0.88 if force_clear_hum else 1.12)
	level_manager.metrics.contact_stability = 0.86 if force_clear_hum else 0.58
	level_manager.metrics.recovery_count = 1 if force_clear_hum else 0
	level_manager.metrics.rollback_count = 0 if force_clear_hum else 2
	level_manager.metrics.finalize_level(level_manager.active_level)
	environment_response.build_from_trail(trail_recorder.points, level_manager.metrics.daylight_reward)
	humming_controller.apply_result(level_manager.active_level, level_manager.metrics)
	_play_hum_reward()


func _record_loop_trail_sample(loop_ascent_time: float) -> void:
	var z: float = tuning.front_base_z - 6.0 - loop_ascent_time * 4.0
	trail_recorder.record(
		Vector3(0.15 * sin(loop_ascent_time * 5.0), mountain.height_at(z) + 0.03, z),
		stone.mass,
		0.74
	)
	level_manager.metrics.ascent_seconds += 0.1
	level_manager.metrics.contact_stability = maxf(level_manager.metrics.contact_stability, 0.74)


func _place_starting_actors() -> void:
	var player_z: float = tuning.front_base_z + 4.8
	player.global_position = Vector3(0.0, mountain.height_at(player_z) + 0.05, player_z)
	player.camera_yaw = 0.0
	player.camera_pitch = 0.24

	var stone_z: float = tuning.front_base_z + 1.1
	stone.global_position = Vector3(0.0, mountain.height_at(stone_z) + tuning.stone_radius + 0.12, stone_z)
	stone.linear_velocity = Vector3.ZERO
	stone.angular_velocity = Vector3.ZERO
	stone.freeze = true

	camera.global_position = player.global_position + Vector3(0.8, 1.6, tuning.shoulder_distance)
	camera.look_at(stone.global_position + Vector3(0, 0.5, 0), Vector3.UP)


func _apply_stone_physics(level) -> void:
	stone.mass = tuning.stone_mass
	stone.gravity_scale = 1.15
	stone.linear_damp = tuning.stone_linear_damp + level.rain_slip * 0.18
	stone.angular_damp = tuning.stone_angular_damp
	stone.continuous_cd = true
	stone.contact_monitor = true
	stone.max_contacts_reported = 8
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.friction = maxf(0.35, tuning.stone_friction - level.rain_slip * 0.28 - level.stone_smoothness * 0.12)
	material.bounce = 0.01
	stone.physics_material_override = material


func _on_game_phase_changed(next_phase: int) -> void:
	if next_phase == GameStateScript.Phase.ASCENT:
		level_manager.mark_ascent_started()
		stone.freeze = false
	elif next_phase == GameStateScript.Phase.RELEASE:
		level_manager.mark_released(player.global_position)
	elif next_phase == GameStateScript.Phase.DESCENT:
		level_manager.mark_stone_entered_back_slope()
		level_manager.metrics.finalize_level(level_manager.active_level)
		environment_response.build_from_trail(trail_recorder.points, level_manager.metrics.daylight_reward)
		humming_controller.apply_result(level_manager.active_level, level_manager.metrics)
		_play_hum_reward()
	elif next_phase == GameStateScript.Phase.COMPLETE:
		level_manager.mark_complete()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _contact_stability() -> float:
	if player.push_frame == null:
		return 0.0
	var spin_ratio: float = player.push_frame.spin_to_translation_ratio
	return clampf(1.0 - spin_ratio / 10.0, 0.0, 1.0)


func _play_hum_reward() -> void:
	if hum_player == null:
		return
	hum_player.stream = humming_controller.audio_stream
	if hum_player.stream != null and DisplayServer.get_name() != "headless":
		hum_player.play()


func _stop_hum_reward() -> void:
	if hum_player == null:
		return
	hum_player.stop()


func _release_hum_audio() -> void:
	if hum_player != null:
		hum_player.stop()
		hum_player.stream = null
	if humming_controller != null:
		humming_controller.audio_stream = null


func save_playtest_report(path: String = "", tester_id: String = "") -> Error:
	var resolved_path: String = playtest_report_path if path.is_empty() else path
	var resolved_tester: String = playtest_tester_id if tester_id.is_empty() else tester_id
	var screenshot_path: String = _screenshot_path_for_report(resolved_path)
	last_playtest_screenshot_path = screenshot_path
	last_playtest_screenshot_error = _save_playtest_screenshot(screenshot_path)
	var report: String = build_manual_playtest_report(resolved_tester)
	var file := FileAccess.open(resolved_path, FileAccess.WRITE)
	last_playtest_report_path = resolved_path
	last_playtest_report_saved = false
	if file == null:
		last_playtest_report_error = FileAccess.get_open_error()
		_update_hud()
		return last_playtest_report_error
	file.store_string(report)
	file.close()
	last_playtest_report_error = last_playtest_screenshot_error
	last_playtest_report_saved = true
	_update_hud()
	return last_playtest_report_error


func build_manual_playtest_report(tester_id: String = "") -> String:
	var resolved_tester: String = playtest_tester_id if tester_id.is_empty() else tester_id
	route_telemetry.current_phase = game_state.label()
	var session := {
		"date": Time.get_date_string_from_system(),
		"build": "local-godot-manual-snapshot",
		"tester": resolved_tester,
		"platform": OS.get_name(),
		"input_method": "Manual KB+M / trackpad",
		"session_type": "Manual snapshot",
		"environment_response_counts": _environment_response_counts(),
	}
	var report: String = PlaytestReportBuilderScript.build_vertical_slice_report(session, route_telemetry, tuning)
	var lines := report.split("\n")
	lines.append("")
	lines.append("## Manual Snapshot Evidence")
	lines.append("- **Phase**: %s" % game_state.label())
	lines.append("- **Telemetry HUD**: %s" % route_telemetry.hud_summary(tuning))
	lines.append("- **Trail Points**: %d" % trail_recorder.points.size())
	lines.append("- **Response Points**: %d" % environment_response.response_points.size())
	lines.append("- **Response Layer Counts**: %s" % str(_environment_response_counts()))
	lines.append("- **Hum Clarity**: %.2f" % humming_controller.clarity)
	lines.append("- **Generated Hum Stream**: %s" % ("Yes" if humming_controller.audio_stream is AudioStreamWAV else "No"))
	lines.append("- **Screenshot Path**: %s" % last_playtest_screenshot_path)
	lines.append("- **Screenshot Status**: %s" % ("OK" if last_playtest_screenshot_error == OK else error_string(last_playtest_screenshot_error)))
	lines.append("- **Report Saved From Scene**: VerticalSlice")
	if game_state.phase == GameStateScript.Phase.COMPLETE or chapter_end_active:
		var chapter_status: Dictionary = chapter_end_status()
		lines.append("")
		lines.append("## Chapter End Evidence")
		lines.append("- **Chapter End Active**: %s" % ("Yes" if bool(chapter_status.get("active", false)) else "No"))
		lines.append("- **Chapter End Title**: %s" % str(chapter_status.get("title", "Chapter I End")))
		lines.append("- **Hold Elapsed**: %.1fs / %.1fs" % [
			float(chapter_status.get("elapsed_seconds", 0.0)),
			float(chapter_status.get("target_seconds", CHAPTER_END_HOLD_SECONDS)),
		])
		lines.append("- **Next Punishment Pending**: Yes")
		lines.append("- **Next Transition**: %s" % str(chapter_status.get("next_transition", "Next Punishment Pending")))
		lines.append("- **First Loop Ends Beside Stone**: Yes")
		lines.append("- **Returning Storm Beat**: %s" % str(chapter_status.get("visual_beat", "returning storm with small light crack")))
		lines.append("- **Storm Pressure**: %.2f" % float(chapter_status.get("storm_pressure", 0.0)))
		lines.append("- **Light Crack**: %.2f" % float(chapter_status.get("light_crack", 0.0)))
		lines.append("- **Audio Beat**: %s" % str(chapter_status.get("audio_beat", "storm remains; hum resists")))
		lines.append("- **Storm Audio Presence**: %.2f" % float(chapter_status.get("storm_audio_presence", 0.0)))
		lines.append("- **Hum Presence**: %.2f" % float(chapter_status.get("hum_presence", 0.0)))
		lines.append("- **Hum Does Not Overpower Storm**: %s" % ("Yes" if bool(chapter_status.get("hum_not_overpowering_storm", false)) else "No"))
		lines.append("- **Generated Audio Only**: %s" % ("No" if bool(chapter_status.get("uses_external_audio", false)) else "Yes"))
	lines.append("")
	lines.append("## Human Notes To Fill")
	lines.append("- **Burden / physicality**: ")
	lines.append("- **Camera comfort**: ")
	lines.append("- **Route clarity**: ")
	lines.append("- **Descent contrast**: ")
	lines.append("- **Generated hum emotional effect**: ")
	return "\n".join(lines)


func _environment_response_counts() -> Dictionary:
	if environment_response != null and environment_response.has_method("kind_counts"):
		return environment_response.kind_counts()
	return {}


func _screenshot_path_for_report(report_path: String) -> String:
	var base: String = report_path
	if base.get_extension().to_lower() == "md":
		base = base.substr(0, base.length() - 3)
	return "%s.png" % base


func _save_playtest_screenshot(path: String) -> Error:
	if DisplayServer.get_name() == "headless":
		return _save_headless_snapshot_placeholder(path)
	var texture: ViewportTexture = get_viewport().get_texture()
	if texture == null:
		return _save_headless_snapshot_placeholder(path)
	var image: Image = texture.get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return _save_headless_snapshot_placeholder(path)
	return image.save_png(path)


func _save_headless_snapshot_placeholder(path: String) -> Error:
	var width := 320
	var height := 180
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.08, 0.09, 0.10, 1.0))
	var phase_color := Color(0.18, 0.50, 0.86, 1.0)
	if game_state.label() == "descent":
		phase_color = Color(0.35, 0.68, 0.42, 1.0)
	elif game_state.label() == "ascent":
		phase_color = Color(0.72, 0.42, 0.24, 1.0)
	for y in range(24, height - 24):
		for x in range(24, width - 24):
			if (x + y) % 11 < 5:
				image.set_pixel(x, y, phase_color)
	for x in range(0, width):
		image.set_pixel(x, 0, Color.WHITE)
		image.set_pixel(x, height - 1, Color.WHITE)
	for y in range(0, height):
		image.set_pixel(0, y, Color.WHITE)
		image.set_pixel(width - 1, y, Color.WHITE)
	return image.save_png(path)


func _update_hud() -> void:
	if status_label == null or prompt_label == null:
		return
	status_label.text = "Level %d: %s | Phase: %s | Storm %.2f | Hum %.2f" % [
		level_manager.active_level.level_id,
		level_manager.active_level.divine_state,
		game_state.label(),
		weather_controller.active_intensity,
		humming_controller.clarity,
	]
	prompt_label.text = _phase_prompt()
	if last_playtest_report_saved:
		prompt_label.text += " Saved: %s" % last_playtest_report_path
		if last_playtest_screenshot_error == OK:
			prompt_label.text += " | PNG: %s" % last_playtest_screenshot_path
	elif last_playtest_report_error != OK:
		prompt_label.text += " Save failed: %s" % error_string(last_playtest_report_error)
	if telemetry_label != null:
		telemetry_label.text = route_telemetry.hud_summary(tuning)


func _phase_prompt() -> String:
	match game_state.phase:
		GameStateScript.Phase.APPROACH:
			return "Approach the stone. W/A/S/D move; mouse or trackpad aims. F9 saves playtest snapshot."
		GameStateScript.Phase.ASCENT:
			return "Hold W to push through the hands; aim left/right to bias contact. F9 saves playtest snapshot."
		GameStateScript.Phase.RELEASE:
			return "Release: the stone must cross the ridge and fall down the back slope. F9 saves playtest snapshot."
		GameStateScript.Phase.DESCENT:
			return "Walk down the back slope and return to the rolled stone. F9 saves playtest snapshot."
		GameStateScript.Phase.COMPLETE:
			return "Chapter I End. Stay beside the rolled stone; next punishment pending. F9 saves playtest snapshot."
	return "F9 saves playtest snapshot."
