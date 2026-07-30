extends SceneTree

const TuningScript = preload("res://scripts/Tuning.gd")
const MountainBuilderScript = preload("res://scripts/MountainBuilder.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")

const DT := 1.0 / 60.0

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All two-hand push tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_single_hand_veers_away_from_that_hand()
	test_analog_strengths_produce_distinct_trajectories()
	test_camera_sweep_does_not_change_force_direction()
	test_release_has_no_scripted_assistance()


func test_single_hand_veers_away_from_that_hand() -> void:
	if not _has_two_hand_solver():
		_expect_true(false, "two-hand push solver should exist for single-hand yaw")
		return
	var left_only := _simulate_push(180, 1.0, 0.0)
	var right_only := _simulate_push(180, 0.0, 1.0)
	print(
		"TWO_HAND_SINGLE left_x=%.3f right_x=%.3f left_torque=%.3f right_torque=%.3f"
		% [left_only.end_position.x, right_only.end_position.x, left_only.max_torque, right_only.max_torque]
	)
	_expect_true(
		float(left_only.end_position.x) > 0.12,
		"left-only push should veer the stone right: x %.3f" % float(left_only.end_position.x)
	)
	_expect_true(
		float(right_only.end_position.x) < -0.12,
		"right-only push should veer the stone left: x %.3f" % float(right_only.end_position.x)
	)
	_expect_true(
		float(left_only.max_torque) > 0.1 and float(right_only.max_torque) > 0.1,
		"single-hand pushes must create real off-center torque"
	)


func test_analog_strengths_produce_distinct_trajectories() -> void:
	if not _has_two_hand_solver():
		_expect_true(false, "two-hand push solver should exist for analog trajectory comparison")
		return
	var asymmetric := _simulate_push(180, 0.3, 0.7)
	var full := _simulate_push(180, 1.0, 1.0)
	var endpoint_gap: float = asymmetric.end_position.distance_to(full.end_position)
	print(
		"TWO_HAND_ANALOG asymmetric=%s full=%s endpoint_gap=%.3f"
		% [str(asymmetric.end_position), str(full.end_position), endpoint_gap]
	)
	_expect_true(
		endpoint_gap > 0.30,
		"0.3/0.7 and 1.0/1.0 must produce measurably different trajectories: gap %.3f" % endpoint_gap
	)
	_expect_true(
		absf(float(asymmetric.end_position.x)) > absf(float(full.end_position.x)) + 0.08,
		"asymmetric analog load should leave a lateral signature beyond balanced full load"
	)
	_expect_input_map()


func test_camera_sweep_does_not_change_force_direction() -> void:
	if not _has_two_hand_solver():
		_expect_true(false, "two-hand push solver should exist for camera decoupling")
		return
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var stone_position := Vector3(0.0, mountain.height_at(0.0) + tuning.stone_radius, 0.0)
	var uphill: Vector3 = mountain.uphill_tangent_at(stone_position.z)
	var downhill: Vector3 = mountain.downhill_tangent_at(stone_position.z)
	var player_position: Vector3 = stone_position + downhill * tuning.stone_radius * 1.55
	player_position.y = mountain.height_at(player_position.z) + 0.05
	var camera_left: Vector3 = (uphill + Vector3.LEFT * 1.8 + Vector3.UP * 0.5).normalized()
	var camera_right: Vector3 = (uphill + Vector3.RIGHT * 1.8 + Vector3.DOWN * 0.4).normalized()
	var left_view = _calculate_two_hand_push_frame(
		stone_position, player_position, uphill, camera_left, 0.6, 0.9, tuning, mountain
	)
	var right_view = _calculate_two_hand_push_frame(
		stone_position, player_position, uphill, camera_right, 0.6, 0.9, tuning, mountain
	)
	print(
		"TWO_HAND_CAMERA left_delta=%.6f right_delta=%.6f aggregate_delta=%.6f"
		% [
			left_view.left_force.distance_to(right_view.left_force),
			left_view.right_force.distance_to(right_view.right_force),
			left_view.contact_force.distance_to(right_view.contact_force),
		]
	)
	_expect_true(
		left_view.left_force.distance_to(right_view.left_force) < 0.0001,
		"camera sweep must not change left-hand force vector"
	)
	_expect_true(
		left_view.right_force.distance_to(right_view.right_force) < 0.0001,
		"camera sweep must not change right-hand force vector"
	)
	_expect_true(
		left_view.contact_force.normalized().distance_to(right_view.contact_force.normalized()) < 0.0001,
		"camera sweep must not change aggregate force direction"
	)
	mountain.free()


func test_release_has_no_scripted_assistance() -> void:
	if not _has_two_hand_solver():
		_expect_true(false, "two-hand push solver should exist for honest release")
		return
	var pushed := _simulate_push(90, 1.0, 1.0)
	var released := _simulate_push(
		120,
		0.0,
		0.0,
		pushed.end_position,
		pushed.end_velocity,
		pushed.end_angular_velocity
	)
	_expect_true(float(released.max_contact_force) < 0.0001, "released hands must apply zero scripted contact force")
	var uphill_gain_after_release: float = pushed.end_position.z - released.end_position.z
	print(
		"TWO_HAND_RELEASE max_contact_force=%.6f uphill_gain=%.3f end_velocity=%s"
		% [released.max_contact_force, uphill_gain_after_release, str(released.end_velocity)]
	)
	_expect_true(
		uphill_gain_after_release < 0.20,
		"released stone should stall or roll back instead of receiving climb assistance: gain %.3f" % uphill_gain_after_release
	)


func _simulate_push(
	frames: int,
	left_strength: float,
	right_strength: float,
	start_position: Vector3 = Vector3(INF, INF, INF),
	start_velocity: Vector3 = Vector3.ZERO,
	start_angular_velocity: Vector3 = Vector3.ZERO
) -> Dictionary:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var position: Vector3 = start_position
	if position.x == INF:
		position = Vector3(0.0, mountain.height_at(0.0) + tuning.stone_radius, 0.0)
	var velocity: Vector3 = start_velocity
	var angular_velocity: Vector3 = start_angular_velocity
	var max_torque: float = 0.0
	var max_contact_force: float = 0.0
	for _index in frames:
		var uphill: Vector3 = mountain.uphill_tangent_at(position.z)
		var downhill: Vector3 = mountain.downhill_tangent_at(position.z)
		var player_position: Vector3 = position + downhill * tuning.stone_radius * 1.55
		player_position.y = mountain.height_at(player_position.z) + 0.05
		var frame = _calculate_two_hand_push_frame(
			position,
			player_position,
			uphill,
			uphill,
			left_strength,
			right_strength,
			tuning,
			mountain
		)
		var gravity: Vector3 = Vector3.DOWN * 9.8 * tuning.stone_mass
		var normal: Vector3 = mountain.normal_at(position.z)
		var net_force: Vector3 = frame.left_force + frame.right_force + gravity - normal * gravity.dot(normal)
		velocity += net_force / tuning.stone_mass * DT
		velocity *= maxf(0.0, 1.0 - tuning.stone_linear_damp * DT)
		var torque: Vector3 = frame.left_contact_offset.cross(frame.left_force)
		torque += frame.right_contact_offset.cross(frame.right_force)
		angular_velocity += torque / (tuning.stone_mass * tuning.stone_radius * tuning.stone_radius) * DT
		angular_velocity *= maxf(0.0, 1.0 - tuning.stone_angular_damp * DT)
		position += velocity * DT
		position.y = mountain.height_at(position.z) + tuning.stone_radius
		max_torque = maxf(max_torque, torque.length())
		max_contact_force = maxf(max_contact_force, frame.contact_force.length())
	mountain.free()
	return {
		"end_position": position,
		"end_velocity": velocity,
		"end_angular_velocity": angular_velocity,
		"max_torque": max_torque,
		"max_contact_force": max_contact_force,
	}


func _has_two_hand_solver() -> bool:
	var controller_script: Script = PushControllerScript
	return controller_script.has_method("calculate_two_hand_push_frame")


func _expect_input_map() -> void:
	_expect_true(InputMap.has_action("push_left"), "input map should define push_left")
	_expect_true(InputMap.has_action("push_right"), "input map should define push_right")
	_expect_true(not InputMap.has_action("push"), "legacy push action should be retired")
	var left_has_trigger: bool = false
	var left_has_mouse: bool = false
	for event in InputMap.action_get_events("push_left"):
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_LEFT:
			left_has_trigger = true
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			left_has_mouse = true
	var right_has_trigger: bool = false
	var right_has_mouse: bool = false
	for event in InputMap.action_get_events("push_right"):
		if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT:
			right_has_trigger = true
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			right_has_mouse = true
	_expect_true(left_has_trigger and left_has_mouse, "push_left should map LT plus binary mouse-left fallback")
	_expect_true(right_has_trigger and right_has_mouse, "push_right should map RT plus binary mouse-right fallback")


func _calculate_two_hand_push_frame(
	stone_position: Vector3,
	player_position: Vector3,
	body_direction: Vector3,
	camera_direction: Vector3,
	left_strength: float,
	right_strength: float,
	tuning,
	mountain
):
	var controller_script: Script = PushControllerScript
	return controller_script.call(
		"calculate_two_hand_push_frame",
		stone_position,
		player_position,
		body_direction,
		camera_direction,
		left_strength,
		right_strength,
		tuning,
		mountain
	)


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
