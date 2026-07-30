extends SceneTree

const VerticalSliceScene = preload("res://scenes/VerticalSlice.tscn")
const GameStateScript = preload("res://scripts/GameState.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")

var failures: Array[String] = []
var route_test_filter: String = "all"


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	_parse_args()
	await _run_named("near_ridge", test_near_ridge_physical_push_reaches_descent_without_teleport)
	await _run_named("front_route", test_front_base_route_smoke_reaches_descent_without_visual_jumps)
	await _run_named("representative_bias", test_representative_route_smoke_bias_window_stays_recoverable)
	await _run_named("push_segment", test_player_input_push_segment_keeps_contact_and_moves_uphill)
	await _run_named("full_player_loop", test_player_input_front_base_route_completes_full_loop_with_descent_steering)
	await _run_named("descent_return", test_player_input_descent_returns_to_stone_and_completes)
	await _run_named("hud", test_vertical_slice_hud_exposes_route_telemetry)
	if failures.is_empty():
		print("All vertical slice route physics tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--route-test="):
			route_test_filter = arg.trim_prefix("--route-test=")


func _run_named(test_name: String, test_callable: Callable) -> void:
	if route_test_filter != "all" and route_test_filter != test_name:
		return
	print("START route physics: %s" % test_name)
	await test_callable.call()
	print("END route physics: %s" % test_name)


func test_near_ridge_physical_push_reaches_descent_without_teleport() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	_prepare_near_ridge_ascent(slice)

	var saw_release := false
	var release_player_position := Vector3.ZERO
	for index in 720:
		if slice.game_state.phase == GameStateScript.Phase.ASCENT:
			_apply_contact_push_step(slice)
		await physics_frame
		if slice.game_state.phase == GameStateScript.Phase.RELEASE and not saw_release:
			saw_release = true
			release_player_position = slice.level_manager.player_position_at_release
		if slice.game_state.phase == GameStateScript.Phase.DESCENT:
			break

	_expect_true(saw_release, "near-ridge physical route should enter release from continuous contact push")
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.DESCENT, "stone should naturally cross onto back slope and enter descent")
	_expect_true(
		slice.level_manager.player_position_at_release.distance_to(release_player_position) < 0.001,
		"release/descent should preserve recorded player position instead of teleporting"
	)
	_expect_true(slice.trail_recorder.points.size() >= 2, "continuous ascent should record stone trail points")
	_expect_true(slice.environment_response.response_points.size() > 0, "descent should build visible response from the real recorded trail")
	_expect_true(slice.humming_controller.clarity > 0.0, "descent should compute hum clarity from run metrics")

	slice.queue_free()
	await process_frame


func test_front_base_route_smoke_reaches_descent_without_visual_jumps() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame

	slice.apply_visual_mode("route")
	var start_z: float = slice.stone.global_position.z
	for index in 6000:
		await physics_frame
		if slice.game_state.phase == GameStateScript.Phase.DESCENT:
			break

	_expect_eq(slice.visual_mode, "route", "route smoke should stay in route mode")
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.DESCENT, "front-base route smoke should physically reach descent")
	_expect_true(start_z - slice.stone.global_position.z > 20.0, "route smoke should move stone from lower front slope toward the ridge")
	_expect_true(slice.trail_recorder.points.size() >= 12, "full route smoke should record a meaningful ascent trail")
	_expect_true(slice.environment_response.response_points.size() > 0, "full route descent should build response from ascent trail")
	_expect_eq(slice.get("route_smoke_teleport_count"), 0, "route smoke should not use visual placement teleports after start")
	var max_lateral = slice.get("route_smoke_max_lateral_offset")
	var bias_recovered = slice.get("route_smoke_bias_recovered")
	_expect_true(max_lateral != null, "route smoke should expose max lateral offset")
	_expect_true(bias_recovered != null, "route smoke should expose bias recovery status")
	if max_lateral != null:
		_expect_true(float(max_lateral) > 0.24, "route smoke should include a visible aim-bias pressure segment, not only centerline pushing")
	if bias_recovered != null:
		_expect_true(bool(bias_recovered), "route smoke should recover from its aim-bias pressure segment before descent")

	slice.queue_free()
	await process_frame


func test_representative_route_smoke_bias_window_stays_recoverable() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	slice.apply_pacing_profile("representative")
	slice.apply_visual_mode("route")
	for index in 5400:
		await physics_frame
		if bool(slice.get("route_smoke_bias_recovered")):
			break

	var max_lateral = slice.get("route_smoke_max_lateral_offset")
	var bias_recovered = slice.get("route_smoke_bias_recovered")
	_expect_true(max_lateral != null, "representative route smoke should expose max lateral offset")
	_expect_true(bias_recovered != null, "representative route smoke should expose bias recovery status")
	if max_lateral != null:
		_expect_true(float(max_lateral) > 0.24, "representative route smoke should still include a visible aim-bias pressure segment")
		_expect_true(float(max_lateral) < slice.tuning.clear_path_width * 0.85, "representative route smoke bias should stay inside the recoverable channel")
	if bias_recovered != null:
		_expect_true(bool(bias_recovered), "representative route smoke should recover from aim bias early instead of drifting for the whole long slope")
	_expect_true(
		slice.player.global_position.distance_to(slice.stone.global_position) <= slice.tuning.push_disengage_distance + 0.65,
		"representative route smoke should keep player and stone coupled after bias recovery"
	)

	slice.queue_free()
	await process_frame


func test_player_input_push_segment_keeps_contact_and_moves_uphill() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	_prepare_player_input_ascent(slice)
	var start_z: float = slice.stone.global_position.z
	var max_contact_distance: float = 0.0
	Input.action_press("move_forward")
	Input.action_press("push")
	for index in 540:
		await physics_frame
		max_contact_distance = maxf(max_contact_distance, slice.player.global_position.distance_to(slice.stone.global_position))
	Input.action_release("move_forward")
	Input.action_release("push")

	_expect_true(slice.stone.global_position.z < start_z - 1.1, "holding W should move the stone uphill through player control")
	_expect_true(slice.player.push_engaged, "player-controlled push should remain engaged while W is held")
	_expect_true(max_contact_distance <= slice.tuning.push_disengage_distance + 0.18, "player should keep contact range without bot repositioning")
	_expect_true(slice.player.push_frame != null and slice.player.push_frame.contact_valid, "player input should keep valid hand contact")

	slice.queue_free()
	await process_frame


func test_player_input_front_base_route_completes_full_loop_with_descent_steering() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	slice.visual_mode = ""
	slice.player.set_physics_process(true)
	var start_player_position: Vector3 = slice.player.global_position
	Input.action_press("move_forward")
	Input.action_press("push")
	for index in 8000:
		if slice.game_state.phase == GameStateScript.Phase.DESCENT:
			_aim_player_toward_stone(slice)
		await physics_frame
		if slice.game_state.phase == GameStateScript.Phase.COMPLETE:
			break
	Input.action_release("move_forward")
	Input.action_release("push")

	_expect_true(
		slice.game_state.phase == GameStateScript.Phase.COMPLETE,
		"holding W and steering downhill toward the stone should complete the push-up / walk-down loop: phase %s stone_z %.2f contact %.2f max_dist %.2f" % [
			slice.game_state.label(),
			slice.stone.global_position.z,
			slice.route_telemetry.contact_ratio(),
			slice.route_telemetry.max_contact_distance,
		]
	)
	_expect_true(slice.trail_recorder.points.size() >= 12, "player-input full route should record ascent trail")
	_expect_true(slice.level_manager.player_position_at_release.distance_to(start_player_position) > 5.0, "player should physically travel before release instead of being teleported from start")
	_expect_true(slice.environment_response.response_points.size() > 0, "player-input descent should build trail response")
	_expect_true(
		slice.player.global_position.distance_to(slice.stone.global_position) <= slice.tuning.contact_distance + 0.5,
		"player-input full route should finish beside the rolled stone"
	)
	_expect_eq(slice.route_telemetry.playtest_verdict(slice.tuning), "PROCEED", "player-input route telemetry should pass the current hand-play gate")
	_expect_eq(slice.route_telemetry.burden_verdict(slice.tuning), "PROCEED", "player-input route should include measurable burden instead of smooth transport")

	slice.queue_free()
	await process_frame


func test_player_input_descent_returns_to_stone_and_completes() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	_prepare_player_input_descent(slice)
	var start_player_position: Vector3 = slice.player.global_position
	Input.action_press("move_forward")
	for index in 420:
		await physics_frame
		if slice.game_state.phase == GameStateScript.Phase.COMPLETE:
			break
	Input.action_release("move_forward")

	_expect_eq(slice.game_state.phase, GameStateScript.Phase.COMPLETE, "holding W downhill should let player-controlled descent return to the stone and complete")
	_expect_true(
		slice.player.global_position.distance_to(slice.stone.global_position) <= slice.tuning.contact_distance + 0.5,
		"completion should happen near the rolled stone"
	)
	_expect_true(
		slice.player.global_position.distance_to(start_player_position) > 5.0,
		"descent completion should require real player travel, not a phase teleport"
	)
	slice.queue_free()
	await process_frame


func test_vertical_slice_hud_exposes_route_telemetry() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	_expect_true(slice.get("route_telemetry") != null, "vertical slice should own route telemetry")
	var telemetry_label = slice.get_node_or_null("HUD/Telemetry")
	_expect_true(telemetry_label != null, "vertical slice HUD should include telemetry label")
	if telemetry_label != null:
		_expect_true(telemetry_label.text.contains("Contact"), "telemetry HUD should show contact ratio")
		_expect_true(telemetry_label.text.contains("Loss"), "telemetry HUD should show contact loss count")
		_expect_true(telemetry_label.text.contains("Dist"), "telemetry HUD should show player-stone distance")
	slice.queue_free()
	await process_frame


func _prepare_near_ridge_ascent(slice) -> void:
	slice.player.set_physics_process(false)
	slice.visual_mode = ""
	slice.game_state.phase = GameStateScript.Phase.ASCENT
	slice.level_manager.mark_ascent_started()
	slice.trail_recorder.clear()
	slice.environment_response.clear_response()
	var z: float = slice.tuning.ridge_z + 2.8
	slice.stone.freeze = false
	slice.stone.global_position = Vector3(0.0, slice.mountain.height_at(z) + slice.tuning.stone_radius + 0.08, z)
	slice.stone.linear_velocity = Vector3.ZERO
	slice.stone.angular_velocity = Vector3.ZERO
	slice.player.global_position = _downhill_player_position(slice)


func _prepare_player_input_ascent(slice) -> void:
	slice.visual_mode = ""
	slice.player.set_physics_process(true)
	slice.game_state.phase = GameStateScript.Phase.ASCENT
	slice.level_manager.mark_ascent_started()
	slice.trail_recorder.clear()
	slice.environment_response.clear_response()
	var z: float = slice.tuning.front_base_z - 4.0
	slice.stone.freeze = false
	slice.stone.global_position = Vector3(0.0, slice.mountain.height_at(z) + slice.tuning.stone_radius + 0.08, z)
	slice.stone.linear_velocity = Vector3.ZERO
	slice.stone.angular_velocity = Vector3.ZERO
	var start: Vector3 = _downhill_player_position(slice)
	start += slice.mountain.downhill_tangent_at(z) * 0.22
	start.y = slice.mountain.height_at(start.z) + 0.05
	slice.player.global_position = start
	slice.player.camera_yaw = 0.0
	slice.player.camera_pitch = -0.06
	slice.player.push_engaged = false
	slice.player.push_frame = null


func _prepare_player_input_descent(slice) -> void:
	slice.visual_mode = ""
	slice.player.set_physics_process(true)
	slice.game_state.phase = GameStateScript.Phase.DESCENT
	slice.level_manager.mark_released(Vector3(0.0, slice.mountain.height_at(slice.tuning.ridge_z - 1.0) + 0.05, slice.tuning.ridge_z - 1.0))
	slice.level_manager.mark_stone_entered_back_slope()
	slice.trail_recorder.clear()
	slice.environment_response.clear_response()
	var stone_z: float = slice.tuning.back_base_z + 1.3
	slice.stone.freeze = true
	slice.stone.global_position = Vector3(0.65, slice.mountain.height_at(stone_z) + slice.tuning.stone_radius + 0.04, stone_z)
	slice.stone.linear_velocity = Vector3.ZERO
	slice.stone.angular_velocity = Vector3.ZERO
	var player_z: float = slice.tuning.ridge_z - 7.0
	slice.player.global_position = Vector3(0.0, slice.mountain.height_at(player_z) + 0.05, player_z)
	slice.player.camera_yaw = 0.0
	slice.player.camera_pitch = -0.06
	slice.player.push_engaged = false
	slice.player.push_frame = null


func _aim_player_toward_stone(slice) -> void:
	var to_stone := Vector3(
		slice.stone.global_position.x - slice.player.global_position.x,
		0.0,
		slice.stone.global_position.z - slice.player.global_position.z
	)
	if to_stone.length_squared() <= 0.001:
		return
	to_stone = to_stone.normalized()
	slice.player.camera_yaw = atan2(to_stone.x, -to_stone.z)


func _apply_contact_push_step(slice) -> void:
	slice.player.global_position = _downhill_player_position(slice)
	var uphill: Vector3 = slice.mountain.uphill_tangent_at(slice.stone.global_position.z)
	slice.player.push_frame = PushControllerScript.apply_push(
		slice.stone,
		slice.player.global_position,
		uphill,
		true,
		0.0,
		slice.tuning,
		slice.mountain
	)


func _downhill_player_position(slice) -> Vector3:
	var downhill: Vector3 = slice.mountain.downhill_tangent_at(slice.stone.global_position.z)
	var position: Vector3 = slice.stone.global_position + downhill * slice.tuning.stone_radius * 1.55
	position.y = slice.mountain.height_at(position.z) + 0.05
	return position


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
