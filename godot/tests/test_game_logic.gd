extends SceneTree

const TuningScript = preload("res://scripts/Tuning.gd")
const GameStateScript = preload("res://scripts/GameState.gd")
const MountainBuilderScript = preload("res://scripts/MountainBuilder.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")
const PushLabScript = preload("res://scripts/PushLab.gd")
const PlayerControllerScript = preload("res://scripts/PlayerController.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All game logic tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_mountain_height_is_double_sided()
	test_obstacle_layout_keeps_center_channel_clear()
	test_obstacle_layout_creates_edge_pressure_without_blocking_stone()
	test_route_edge_markers_frame_the_path_without_blocking()
	test_route_camber_bands_create_learnable_pressure()
	test_route_pressure_markers_show_low_side_without_blocking()
	test_push_requires_continuous_input()
	test_push_force_ramps_with_sustained_contact()
	test_push_brace_requires_quality_and_steady_aim()
	test_push_brace_builds_and_collapses()
	test_burden_force_shaping_slows_machine_like_push()
	test_burden_stride_exposes_step_effort_cycle()
	test_push_direction_tracks_camera_aim()
	test_push_engagement_requires_w_and_releases_cleanly()
	test_camera_push_blend_enters_and_exits_smoothly()
	test_camera_aim_has_visible_contact_and_force_authority()
	test_camera_ray_targets_the_reticle_surface()
	test_camera_aim_lift_moves_contact_upward()
	test_camera_aim_down_moves_contact_down_without_lifting_force()
	test_push_force_beats_downhill_gravity()
	test_push_lab_geometry_does_not_override_physics_presets()
	test_camera_aim_does_not_override_uphill_push()
	test_player_anchor_stays_on_downhill_side()
	test_release_to_descent_does_not_move_player()
	test_descent_complete_requires_returning_to_stone()
	test_arm_pose_idle_walk_reach_push()
	test_two_segment_arm_pose_keeps_hands_connected()


func test_mountain_height_is_double_sided() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var front_base := mountain.height_at(tuning.front_base_z)
	var ridge := mountain.height_at(tuning.ridge_z)
	var back_base := mountain.height_at(tuning.back_base_z)
	_expect_near(front_base, 0.0, 0.001, "front base should be ground level")
	_expect_true(ridge > 6.0, "ridge should be high enough to create a mountain")
	_expect_near(back_base, 0.0, 0.001, "back base should return to ground level")
	mountain.free()


func test_push_brace_requires_quality_and_steady_aim() -> void:
	var tuning = TuningScript.new()
	var stable_good: float = PushControllerScript.brace_target(0.84, 0.08, tuning)
	var unstable_good: float = PushControllerScript.brace_target(0.84, 3.6, tuning)
	var stable_bad: float = PushControllerScript.brace_target(0.44, 0.08, tuning)
	_expect_true(stable_good > 0.82, "steady sweet-spot contact should permit a strong body brace")
	_expect_true(unstable_good < 0.22, "rapid camera motion should break leverage even on a good contact point")
	_expect_true(stable_bad < 0.22, "a poor pressure angle should not build enough brace to motor uphill")


func test_push_brace_builds_and_collapses() -> void:
	var tuning = TuningScript.new()
	var brace: float = 0.0
	for index in 60:
		brace = PushControllerScript.update_brace(brace, 1.0, true, 1.0 / 60.0, tuning)
	_expect_true(brace > 0.68 and brace < 1.0, "brace should take sustained contact to build instead of switching on instantly: %.2f" % brace)
	var built_brace: float = brace
	for index in 18:
		brace = PushControllerScript.update_brace(brace, 0.0, true, 1.0 / 60.0, tuning)
	_expect_true(brace < built_brace * 0.48, "unstable or bad contact should collapse brace quickly: %.2f -> %.2f" % [built_brace, brace])
	brace = PushControllerScript.update_brace(brace, 0.0, false, 0.25, tuning)
	_expect_true(brace < 0.08, "releasing W should clear the remaining body brace")


func test_obstacle_layout_keeps_center_channel_clear() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var obstacles := mountain.generate_obstacle_layout()
	_expect_true(obstacles.size() >= tuning.obstacle_density, "obstacle generator should create the requested pressure")
	for obstacle in obstacles:
		_expect_true(absf(obstacle.position.x) >= tuning.clear_path_width * 0.5, "obstacle should not block the center channel")
	mountain.free()


func test_obstacle_layout_creates_edge_pressure_without_blocking_stone() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var obstacles := mountain.generate_obstacle_layout()
	var clear_half: float = tuning.clear_path_width * 0.5
	var minimum_stone_corridor: float = tuning.stone_radius + 0.18
	var pressure_band_outer: float = minimum_stone_corridor + 1.15
	var left_pressure: int = 0
	var right_pressure: int = 0
	var min_radius: float = INF
	var max_radius: float = 0.0
	for obstacle in obstacles:
		var collider_radius: float = obstacle.radius * 0.78
		var inner_edge: float = absf(obstacle.position.x) - collider_radius
		_expect_true(inner_edge >= minimum_stone_corridor, "obstacle collider should leave the stone center corridor passable")
		if inner_edge <= pressure_band_outer:
			if obstacle.position.x < 0.0:
				left_pressure += 1
			else:
				right_pressure += 1
		min_radius = minf(min_radius, obstacle.radius)
		max_radius = maxf(max_radius, obstacle.radius)
	_expect_true(left_pressure >= 2, "left side should have near-channel obstacle pressure")
	_expect_true(right_pressure >= 2, "right side should have near-channel obstacle pressure")
	_expect_true(max_radius - min_radius > 0.32, "obstacle radii should vary enough to read as uneven terrain")
	_expect_true(clear_half > minimum_stone_corridor, "clear path width should leave room for the stone center")
	mountain.free()


func test_route_edge_markers_frame_the_path_without_blocking() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	_expect_true(mountain.has_method("generate_route_marker_layout"), "mountain should expose route edge marker layout for peripheral push readability")
	if not mountain.has_method("generate_route_marker_layout"):
		mountain.free()
		return
	var markers: Array = mountain.generate_route_marker_layout()
	_expect_true(markers.size() >= 10, "route edge markers should give enough repeated peripheral anchors")
	var left_count: int = 0
	var right_count: int = 0
	var min_height: float = INF
	var max_height: float = 0.0
	var min_inner_clearance: float = tuning.clear_path_width * 0.5 + tuning.stone_radius * 0.35
	var max_visible_edge: float = tuning.path_width * 0.5 + 0.65
	for marker in markers:
		var position: Vector3 = marker.position
		min_height = minf(min_height, float(marker.height))
		max_height = maxf(max_height, float(marker.height))
		if position.x < 0.0:
			left_count += 1
		else:
			right_count += 1
		_expect_true(absf(position.x) >= min_inner_clearance, "route marker should not sit in the main stone corridor")
		_expect_true(absf(position.x) <= max_visible_edge, "route marker should stay close enough to read in peripheral vision")
		var expected_height: float = mountain.height_at_position(position.x, position.z) if mountain.has_method("height_at_position") else mountain.height_at(position.z)
		_expect_near(position.y, expected_height, 0.18, "route marker should sit on the mountain surface")
	_expect_true(left_count >= 5 and right_count >= 5, "route markers should frame both sides of the path")
	_expect_true(min_height >= 0.45, "route markers should be tall enough to read while pushing")
	_expect_true(max_height > min_height + 0.18, "route marker heights should vary enough to read as terrain, not UI rails")
	mountain.free()


func test_route_camber_bands_create_learnable_pressure() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	_expect_true(mountain.has_method("route_camber_at"), "mountain should expose route camber pressure bands")
	_expect_true(mountain.has_method("height_at_position"), "mountain should expose x/z height for physical route pressure")
	_expect_true(mountain.has_method("normal_at_position"), "mountain should expose x/z normal for push contact physics")
	var first_z: float = tuning.front_base_z - tuning.route_camber_band_length * 0.5
	var second_z: float = first_z - tuning.route_camber_band_length
	var first_camber: float = mountain.route_camber_at(first_z)
	var second_camber: float = mountain.route_camber_at(second_z)
	_expect_true(absf(first_camber) > 0.45, "first camber band should create readable lateral pressure")
	_expect_true(first_camber * second_camber < 0.0, "adjacent camber bands should alternate direction")
	var left_height: float = mountain.height_at_position(-tuning.path_width * 0.45, first_z)
	var right_height: float = mountain.height_at_position(tuning.path_width * 0.45, first_z)
	_expect_true(absf(right_height - left_height) > 0.18, "camber should materially tilt the route across the stone lane")
	_expect_near(mountain.height_at_position(0.0, first_z), mountain.height_at(first_z), 0.01, "route centerline should keep the original ascent pacing")
	var normal: Vector3 = mountain.normal_at_position(Vector3(tuning.path_width * 0.30, mountain.height_at(first_z), first_z))
	_expect_true(absf(normal.x) > 0.025, "cambered route normal should expose lateral slope to contact physics")
	mountain.free()


func test_route_pressure_markers_show_low_side_without_blocking() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	_expect_true(mountain.has_method("generate_route_pressure_marker_layout"), "mountain should expose natural pressure marker layout")
	if not mountain.has_method("generate_route_pressure_marker_layout"):
		mountain.free()
		return
	var markers: Array = mountain.generate_route_pressure_marker_layout()
	_expect_true(markers.size() >= 6, "pressure markers should repeat across multiple camber bands")
	var left_count: int = 0
	var right_count: int = 0
	var center_clearance: float = tuning.stone_radius + 0.18
	for marker in markers:
		var position: Vector3 = marker.position
		if position.x < 0.0:
			left_count += 1
		else:
			right_count += 1
		_expect_true(absf(position.x) > center_clearance, "pressure markers should not sit in the stone center corridor")
		_expect_true(absf(position.x) < tuning.path_width * 0.5, "pressure markers should stay on the readable route surface")
		_expect_near(position.y, mountain.height_at_position(position.x, position.z), 0.04, "pressure markers should sit on the cambered route surface")
		_expect_true(signf(position.x) == float(marker.side), "pressure marker x should match its low-side hint")
		_expect_true(signf(float(marker.camber)) == -float(marker.side), "pressure marker should sit on the low side of the camber band")
	_expect_true(left_count >= 3 and right_count >= 3, "pressure markers should alternate left and right across the route")
	mountain.free()


func test_push_requires_continuous_input() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var frame_without_push = PushControllerScript.calculate_push_frame(
		Vector3(0, 2.0, 6.0),
		Vector3(0, 0, 7.4),
		Vector3(0, 0, -1),
		false,
		0.0,
		tuning,
		mountain
	)
	var frame_with_push = PushControllerScript.calculate_push_frame(
		Vector3(0, 2.0, 6.0),
		Vector3(0, 0, 7.4),
		Vector3(0, 0, -1),
		true,
		0.0,
		tuning,
		mountain
	)
	_expect_near(frame_without_push.force.length(), 0.0, 0.001, "force should be zero when W is not held")
	_expect_true(frame_with_push.force.length() > 0.1, "force should exist only while pushing")
	_expect_true(frame_with_push.force.length() <= tuning.max_push_force_per_frame, "force should be capped")
	mountain.free()


func test_push_force_ramps_with_sustained_contact() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var player_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * tuning.stone_radius * 1.5
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var early_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		uphill,
		true,
		0.0,
		tuning,
		mountain,
		0.02
	)
	var settled_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		uphill,
		true,
		0.0,
		tuning,
		mountain,
		tuning.push_force_ramp_seconds + 0.2
	)
	_expect_true(early_frame.contact_force.length() < settled_frame.contact_force.length() * 0.72, "contact push should have a short settling ramp while body brace remains the main effort gate")
	_expect_true(settled_frame.contact_force.dot(uphill) > settled_frame.gravity_downhill_component * 0.62, "settled sweet-spot push should contribute meaningful uphill force without becoming a motor")
	mountain.free()


func test_burden_force_shaping_slows_machine_like_push() -> void:
	var tuning = TuningScript.new()
	_expect_true(tuning.get("burden_target_uphill_speed") != null, "tuning should expose a target uphill speed for burden feel")
	_expect_true(tuning.get("burden_stride_force_depth") != null, "tuning should expose hand-stride force depth")
	var push_controller = PushControllerScript.new()
	_expect_true(push_controller.has_method("shape_contact_force_for_burden"), "push controller should expose burden force shaping for tests")
	if not push_controller.has_method("shape_contact_force_for_burden"):
		push_controller.free()
		return
	var uphill := Vector3(0.0, 0.24, -0.97).normalized()
	var base_force: Vector3 = uphill * 140.0
	var slow_force: Vector3 = push_controller.call("shape_contact_force_for_burden", base_force, uphill, 0.20, 0.31, tuning)
	var fast_force: Vector3 = push_controller.call("shape_contact_force_for_burden", base_force, uphill, 1.55, 0.31, tuning)
	var weak_stride_force: Vector3 = push_controller.call("shape_contact_force_for_burden", base_force, uphill, 0.20, 0.0, tuning)
	_expect_true(fast_force.dot(uphill) < slow_force.dot(uphill) * 0.86, "fast smooth push should be governed down instead of accelerating like a motor")
	_expect_true(weak_stride_force.dot(uphill) < slow_force.dot(uphill) * 0.82, "hand stride trough should create real force variation for burden")
	_expect_true(slow_force.dot(uphill) > 0.0 and weak_stride_force.dot(uphill) > 0.0, "burden shaping should not invert the push force")
	push_controller.free()


func test_burden_stride_exposes_step_effort_cycle() -> void:
	var tuning = TuningScript.new()
	var push_controller = PushControllerScript.new()
	_expect_true(push_controller.has_method("burden_stride_multiplier"), "push controller should expose effort stride for HUD and hand feedback")
	_expect_true(push_controller.has_method("burden_recoil_from_stride"), "push controller should expose effort recoil for hand feedback")
	if not push_controller.has_method("burden_stride_multiplier") or not push_controller.has_method("burden_recoil_from_stride"):
		push_controller.free()
		return
	var peak_seconds: float = 1.0 / (2.0 * tuning.push_hand_cycle_hz)
	var trough: float = push_controller.call("burden_stride_multiplier", 0.0, tuning)
	var peak: float = push_controller.call("burden_stride_multiplier", peak_seconds, tuning)
	var next_trough: float = push_controller.call("burden_stride_multiplier", 1.0 / tuning.push_hand_cycle_hz, tuning)
	var trough_recoil: float = push_controller.call("burden_recoil_from_stride", trough, tuning)
	var peak_recoil: float = push_controller.call("burden_recoil_from_stride", peak, tuning)
	_expect_true(peak - trough > tuning.burden_stride_force_depth * 0.75, "effort cycle should have a visible push-and-recover force swing")
	_expect_true(absf(next_trough - trough) < 0.04, "effort cycle should repeat predictably across hand steps")
	_expect_true(trough_recoil > 0.82 and peak_recoil < 0.08, "recoil should be high only during the labor trough")

	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var player_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * tuning.stone_radius * 1.5
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var trough_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		uphill,
		true,
		0.0,
		tuning,
		mountain,
		0.0
	)
	var peak_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		uphill,
		true,
		0.0,
		tuning,
		mountain,
		peak_seconds
	)
	_expect_true(trough_frame.burden_recoil > peak_frame.burden_recoil + 0.75, "push frame should expose the labor trough to visuals")
	_expect_true(trough_frame.burden_stride < peak_frame.burden_stride, "push frame should expose stronger force during the effort peak")
	mountain.free()
	push_controller.free()


func test_push_direction_tracks_camera_aim() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var left_frame = PushControllerScript.calculate_push_frame(
		Vector3(0, 2.0, 6.0),
		Vector3(0, 0, 7.4),
		Vector3(-0.6, 0.15, -1).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	var right_frame = PushControllerScript.calculate_push_frame(
		Vector3(0, 2.0, 6.0),
		Vector3(0, 0, 7.4),
		Vector3(0.6, 0.15, -1).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	_expect_true(left_frame.contact_point.x < right_frame.contact_point.x, "hand contact should follow camera aim")
	_expect_true(left_frame.force.x < 0.0 and right_frame.force.x > 0.0, "lateral force should follow camera aim")
	mountain.free()


func test_push_engagement_requires_w_and_releases_cleanly() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var player_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * tuning.stone_radius * 1.55
	player_position.y = mountain.height_at(player_position.z) + 0.05
	_expect_true(
		PlayerControllerScript.should_engage_push(false, true, false, player_position, stone_position, uphill, tuning),
		"holding W near the downhill face should engage pushing"
	)
	_expect_true(
		not PlayerControllerScript.should_engage_push(false, false, false, player_position, stone_position, uphill, tuning),
		"near stone without W should not engage pushing"
	)
	_expect_true(
		not PlayerControllerScript.should_engage_push(true, true, true, player_position, stone_position, uphill, tuning),
		"pressing S should disengage pushing"
	)
	var far_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * (tuning.push_disengage_distance + 0.25)
	far_position.y = mountain.height_at(far_position.z) + 0.05
	_expect_true(
		not PlayerControllerScript.should_engage_push(true, true, false, far_position, stone_position, uphill, tuning),
		"moving too far from the stone should disengage pushing"
	)
	mountain.free()


func test_camera_push_blend_enters_and_exits_smoothly() -> void:
	var tuning = TuningScript.new()
	var enter: float = PlayerControllerScript.calculate_camera_blend(0.0, true, 1.0 / 60.0, tuning)
	var exit: float = PlayerControllerScript.calculate_camera_blend(0.8, false, 1.0 / 60.0, tuning)
	_expect_true(enter > 0.0 and enter < 0.35, "push camera blend should enter without jumping")
	_expect_true(exit < 0.8 and exit > 0.45, "push camera blend should exit without snapping")


func test_camera_aim_has_visible_contact_and_force_authority() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var player_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * tuning.stone_radius * 1.5
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var side: Vector3 = Vector3(-uphill.z, 0.0, uphill.x).normalized()
	var centered_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		uphill,
		true,
		0.0,
		tuning,
		mountain
	)
	var weak_corner_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + side * 1.25 + Vector3.UP * 1.0).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	var left_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.LEFT * 1.3).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	var right_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.RIGHT * 1.3).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	_expect_true(right_frame.camera_contact_point.x - left_frame.camera_contact_point.x > 0.75, "camera aim should visibly move the hand contact across the stone")
	_expect_true(right_frame.roll_direction.x - left_frame.roll_direction.x > 0.35, "camera aim should create a playable lateral roll direction")
	_expect_true(right_frame.contact_force.x - left_frame.contact_force.x > 25.0, "camera aim should create a playable lateral push difference")
	_expect_true(left_frame.contact_force.dot(uphill) > left_frame.contact_force.length() * 0.74, "left-biased push should still keep enough uphill force")
	_expect_true(right_frame.contact_force.dot(uphill) > right_frame.contact_force.length() * 0.74, "right-biased push should still keep enough uphill force")
	_expect_true(centered_frame.contact_quality > 0.45, "centered downhill-side contact should read as a usable angle")
	_expect_true(weak_corner_frame.contact_quality < centered_frame.contact_quality * 0.75, "high corner contact should visibly read as a weaker angle")
	mountain.free()


func test_camera_ray_targets_the_reticle_surface() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var downhill: Vector3 = mountain.downhill_tangent_at(stone_position.z)
	var side: Vector3 = Vector3(-uphill.z, 0.0, uphill.x).normalized()
	var camera_origin: Vector3 = stone_position + downhill * tuning.stone_radius * 1.95 + Vector3.UP * 0.34
	var player_position: Vector3 = stone_position + downhill * tuning.stone_radius * 1.55
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var desired_left_working_surface: Vector3 = (downhill * 0.66 - side * 0.50 + Vector3.UP * 0.08).normalized()
	var desired_right_working_surface: Vector3 = (downhill * 0.66 + side * 0.50 + Vector3.UP * 0.08).normalized()
	var left_target: Vector3 = stone_position + desired_left_working_surface * tuning.stone_radius
	var right_target: Vector3 = stone_position + desired_right_working_surface * tuning.stone_radius
	var left_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(left_target - camera_origin).normalized(),
		true,
		0.0,
		tuning,
		mountain,
		999.0,
		camera_origin
	)
	var right_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(right_target - camera_origin).normalized(),
		true,
		0.0,
		tuning,
		mountain,
		999.0,
		camera_origin
	)
	_expect_true(left_frame.camera_contact_point.distance_to(left_target) < 0.16, "camera ray should place the hand at the reticle-selected left working surface")
	_expect_true(right_frame.camera_contact_point.distance_to(right_target) < 0.16, "camera ray should place the hand at the reticle-selected right working surface")
	_expect_true((right_frame.camera_contact_point - left_frame.camera_contact_point).dot(side) > 0.70, "reticle surface targeting should move contact clearly left/right")
	_expect_true(right_frame.contact_force.dot(side) - left_frame.contact_force.dot(side) > 64.0, "reticle surface targeting should produce a strong enough side-force gap to steer deliberately")
	mountain.free()


func test_camera_aim_lift_moves_contact_upward() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var player_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * tuning.stone_radius * 1.5
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var low_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.DOWN * 0.3).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	var high_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.UP * 1.1).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	_expect_true(high_frame.camera_contact_point.y - low_frame.camera_contact_point.y > 0.22, "looking upward should move the hand contact upward")
	_expect_true(
		high_frame.contact_force.normalized().dot(Vector3.UP) <= low_frame.contact_force.normalized().dot(Vector3.UP) + 0.08,
		"looking upward should change contact quality instead of adding a lifting force direction"
	)
	mountain.free()


func test_camera_aim_down_moves_contact_down_without_lifting_force() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var player_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * tuning.stone_radius * 1.5
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var center_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		uphill,
		true,
		0.0,
		tuning,
		mountain
	)
	var low_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.DOWN * 1.05).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	_expect_true(center_frame.contact_valid and low_frame.contact_valid, "center and low aim should both remain valid push contacts")
	_expect_true(center_frame.camera_contact_point.y - low_frame.camera_contact_point.y > 0.24, "looking down should visibly move the hand contact lower on the stone")
	_expect_true(
		low_frame.contact_force.normalized().dot(Vector3.UP) <= center_frame.contact_force.normalized().dot(Vector3.UP) + 0.08,
		"looking down should not add a new vertical lifting direction"
	)
	mountain.free()


func test_push_force_beats_downhill_gravity() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(3.5) + tuning.stone_radius, 3.5)
	var player_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * tuning.stone_radius * 1.5
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		mountain.uphill_tangent_at(stone_position.z),
		true,
		0.0,
		tuning,
		mountain
	)
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var push_uphill: float = frame.contact_force.dot(uphill)
	var gravity_downhill: float = tuning.stone_mass * 9.8 * tuning.stone_gravity_scale * maxf(0.0, -Vector3.DOWN.dot(uphill))
	_expect_true(push_uphill > gravity_downhill * 0.62, "sweet-spot push uphill component should contribute meaningful force while preserving rollback risk")
	mountain.free()


func test_push_lab_geometry_does_not_override_physics_presets() -> void:
	var physical_fields: Array[String] = [
		"stone_mass",
		"stone_gravity_scale",
		"push_force",
		"push_contact_spring",
		"max_contact_push_force",
		"push_quality_dead_zone",
		"push_quality_curve",
		"aim_force_strength",
	]
	for preset_name in TuningScript.push_lab_preset_names():
		var expected = TuningScript.new()
		expected.apply_push_lab_preset(preset_name)
		var lab = PushLabScript.new()
		lab.active_preset = preset_name
		lab.tuning.apply_push_lab_preset(preset_name)
		lab._apply_short_skill_slope_geometry()
		for field_name in physical_fields:
			_expect_true(
				is_equal_approx(float(lab.tuning.get(field_name)), float(expected.get(field_name))),
				"push-lab geometry must not secretly override %s for the %s preset" % [field_name, preset_name]
			)
		lab.free()


func test_camera_aim_does_not_override_uphill_push() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var player_position: Vector3 = stone_position + mountain.downhill_tangent_at(stone_position.z) * tuning.stone_radius * 1.5
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var left_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.LEFT * 0.8).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	var right_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.RIGHT * 0.8).normalized(),
		true,
		0.0,
		tuning,
		mountain
	)
	_expect_true(left_frame.contact_force.dot(uphill) > left_frame.contact_force.length() * 0.82, "left aim should keep most force uphill")
	_expect_true(right_frame.contact_force.dot(uphill) > right_frame.contact_force.length() * 0.82, "right aim should keep most force uphill")
	_expect_true(absf(left_frame.contact_force.x) < left_frame.contact_force.dot(uphill) * 0.55, "left aim lateral force should remain limited")
	_expect_true(absf(right_frame.contact_force.x) < right_frame.contact_force.dot(uphill) * 0.55, "right aim lateral force should remain limited")
	mountain.free()


func test_player_anchor_stays_on_downhill_side() -> void:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position: Vector3 = Vector3(0, mountain.height_at(4.0) + tuning.stone_radius, 4.0)
	var side_player: Vector3 = stone_position + Vector3(2.2, 0, 0.2)
	side_player.y = mountain.height_at(side_player.z) + 0.05
	var frame = PushControllerScript.calculate_push_frame(
		stone_position,
		side_player,
		(mountain.uphill_tangent_at(stone_position.z) + Vector3.RIGHT * 0.6).normalized(),
		true,
		1.0,
		tuning,
		mountain
	)
	var downhill: Vector3 = mountain.downhill_tangent_at(stone_position.z)
	_expect_true((frame.player_anchor - stone_position).dot(downhill) > tuning.stone_radius, "player anchor should stay downhill of the stone")
	mountain.free()


func test_release_to_descent_does_not_move_player() -> void:
	var tuning = TuningScript.new()
	var state = GameStateScript.new()
	state.tuning = tuning
	state.phase = GameStateScript.Phase.RELEASE
	var before := Vector3(0.2, 8.0, tuning.ridge_z - 0.4)
	var after = state.advance(
		0.2,
		before,
		Vector3(0.1, 7.4, tuning.ridge_z - 1.6),
		Vector3(0, -0.1, -0.8)
	)
	_expect_eq(state.phase, GameStateScript.Phase.DESCENT, "stone rolling down backside should enter descent")
	_expect_eq(after, before, "phase transition must not teleport the player")


func test_descent_complete_requires_returning_to_stone() -> void:
	var tuning = TuningScript.new()
	var state = GameStateScript.new()
	state.tuning = tuning
	state.phase = GameStateScript.Phase.DESCENT
	var stone_low_far := Vector3(tuning.path_width * 0.45, 1.2, tuning.back_base_z + 1.4)
	var player_at_back_foot_far := Vector3(-tuning.path_width * 0.45, 1.0, tuning.back_base_z + 2.0)
	state.advance(0.1, player_at_back_foot_far, stone_low_far, Vector3.ZERO)
	_expect_eq(
		state.phase,
		GameStateScript.Phase.DESCENT,
		"descent should not complete just because the player reached the back foot; they must return to the stone"
	)
	var player_near_stone := stone_low_far + Vector3(0.0, 0.0, tuning.contact_distance * 0.42)
	state.advance(0.1, player_near_stone, stone_low_far, Vector3.ZERO)
	_expect_eq(state.phase, GameStateScript.Phase.COMPLETE, "descent should complete after the player returns to the low stone")


func test_arm_pose_idle_walk_reach_push() -> void:
	var tuning = TuningScript.new()
	var idle = PlayerControllerScript.calculate_arm_pose(0.5, false, false, Vector3.ZERO, tuning)
	var walk = PlayerControllerScript.calculate_arm_pose(0.5, true, false, Vector3.ZERO, tuning)
	var reach = PlayerControllerScript.calculate_arm_pose(0.5, false, true, Vector3(0, 0.1, -1), tuning)
	var push = PlayerControllerScript.calculate_arm_pose(0.5, true, true, Vector3(0.4, 0.2, -1), tuning)
	_expect_near(idle.swing, 0.0, 0.001, "idle arms should rest instead of swaying")
	_expect_true(absf(walk.swing) > 0.01, "walking should add arm swing")
	_expect_true(reach.reach > idle.reach, "near stone should extend hands")
	_expect_true(push.contact_offset.x > reach.contact_offset.x, "push hands should follow camera contact offset")


func test_two_segment_arm_pose_keeps_hands_connected() -> void:
	var tuning = TuningScript.new()
	var pose = PlayerControllerScript.calculate_two_segment_arm_pose(
		0.25,
		true,
		true,
		true,
		Vector3(-0.3, 1.08, -0.52),
		Vector3(0.3, 1.08, -0.52),
		Vector3(0.45, 0.18, -1.0).normalized(),
		tuning
	)
	_expect_true(pose.left_shoulder.distance_to(pose.left_elbow) <= tuning.arm_upper_length + 0.08, "left upper arm should remain connected")
	_expect_true(pose.left_elbow.distance_to(pose.left_hand) <= tuning.arm_forearm_length + 0.10, "left forearm should remain connected to hand")
	_expect_true(pose.right_shoulder.distance_to(pose.right_elbow) <= tuning.arm_upper_length + 0.08, "right upper arm should remain connected")
	_expect_true(pose.right_elbow.distance_to(pose.right_hand) <= tuning.arm_forearm_length + 0.10, "right forearm should remain connected to hand")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.4f, got %.4f" % [message, expected, actual])


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
