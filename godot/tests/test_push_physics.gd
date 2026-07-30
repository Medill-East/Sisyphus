extends SceneTree

const TuningScript = preload("res://scripts/Tuning.gd")
const MountainBuilderScript = preload("res://scripts/MountainBuilder.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All push physics tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_continuous_push_moves_stone_uphill()
	test_released_push_does_not_script_auto_climb()
	test_single_hand_push_offsets_laterally_but_keeps_route_recoverable()
	test_push_does_not_spin_in_place()
	test_camera_sweep_does_not_change_force()


func test_continuous_push_moves_stone_uphill() -> void:
	var result: Dictionary = _simulate_push(240, 0, 1.0, 1.0)
	_expect_true(float(result.max_force_uphill) > 20.0, "continuous push should apply a measurable uphill contact force")
	_expect_true(absf(result.end_position.x) < 1.2, "straight push should stay near the center route")


func test_released_push_does_not_script_auto_climb() -> void:
	var pushed: Dictionary = _simulate_push(120, 0, 1.0, 1.0)
	var released: Dictionary = _simulate_push(160, 0, 0.0, 0.0, pushed.end_position, pushed.end_velocity)
	var uphill_gain_after_release: float = pushed.end_position.z - released.end_position.z
	_expect_true(uphill_gain_after_release < 0.25, "released stone should not continue auto-climbing uphill")


func test_single_hand_push_offsets_laterally_but_keeps_route_recoverable() -> void:
	var result: Dictionary = _simulate_push(240, 0, 1.0, 0.0)
	_expect_true(float(result.max_side_force) > 8.0, "left-only push should create rightward contact force")
	_expect_true(result.end_position.x > 0.15, "left-only push should veer right")


func test_push_does_not_spin_in_place() -> void:
	var result: Dictionary = _simulate_push(240, 0, 1.0, 0.0)
	var horizontal_distance := Vector2(
		result.end_position.x - result.start_position.x,
		result.end_position.z - result.start_position.z
	).length()
	var spin_ratio: float = result.end_angular_speed / maxf(result.end_velocity.length(), 0.05)
	_expect_true(horizontal_distance > 0.75, "push should translate the stone instead of spinning in place")
	_expect_true(spin_ratio < 8.0, "push angular speed should remain coupled to linear motion")


func test_camera_sweep_does_not_change_force() -> void:
	var left_view: Dictionary = _simulate_push(120, 0, 0.6, 0.9, Vector3(INF, INF, INF), Vector3.ZERO, Vector3.ZERO, Vector3.LEFT * 1.7)
	var right_view: Dictionary = _simulate_push(120, 0, 0.6, 0.9, Vector3(INF, INF, INF), Vector3.ZERO, Vector3.ZERO, Vector3.RIGHT * 1.7)
	_expect_true(left_view.end_position.distance_to(right_view.end_position) < 0.0001, "camera sweep should not change the simulated trajectory")
	_expect_true(left_view.last_force.distance_to(right_view.last_force) < 0.0001, "camera sweep should not change the force vector")


func _simulate_push(
	frames: int,
	start_z: float,
	left_strength: float,
	right_strength: float,
	start_position: Vector3 = Vector3(INF, INF, INF),
	start_velocity: Vector3 = Vector3.ZERO,
	start_angular_velocity: Vector3 = Vector3.ZERO,
	aim_offset: Vector3 = Vector3.ZERO
) -> Dictionary:
	var tuning = TuningScript.new()
	var mountain = MountainBuilderScript.new()
	mountain.tuning = tuning
	var dt: float = 1.0 / 60.0
	var position: Vector3 = start_position
	if position.x == INF:
		position = Vector3(0, mountain.height_at(start_z) + tuning.stone_radius, start_z)
	var velocity: Vector3 = start_velocity
	var angular_velocity: Vector3 = start_angular_velocity
	var first_position: Vector3 = position
	var max_force_uphill: float = 0.0
	var max_side_force: float = 0.0
	var max_contact_height: float = -INF
	var last_force: Vector3 = Vector3.ZERO
	for index in frames:
		var uphill: Vector3 = mountain.uphill_tangent_at(position.z)
		var downhill: Vector3 = mountain.downhill_tangent_at(position.z)
		var player_position: Vector3 = position + downhill * tuning.stone_radius * 1.55
		player_position.y = mountain.height_at(player_position.z) + 0.05
		var camera_direction: Vector3 = (uphill + aim_offset).normalized()
		var frame = PushControllerScript.calculate_two_hand_push_frame(
			position,
			player_position,
			uphill,
			camera_direction,
			left_strength,
			right_strength,
			tuning,
			mountain
		)
		var side: Vector3 = Vector3(-uphill.z, 0.0, uphill.x).normalized()
		max_force_uphill = maxf(max_force_uphill, frame.contact_force.dot(uphill))
		max_side_force = maxf(max_side_force, absf(frame.contact_force.dot(side)))
		max_contact_height = maxf(max_contact_height, frame.camera_contact_point.y - position.y)
		last_force = frame.contact_force
		var gravity: Vector3 = Vector3.DOWN * 9.8 * tuning.stone_mass
		var normal: Vector3 = mountain.normal_at(position.z)
		var net_force: Vector3 = frame.contact_force + gravity - normal * gravity.dot(normal)
		velocity += (net_force / tuning.stone_mass) * dt
		velocity *= maxf(0.0, 1.0 - tuning.stone_linear_damp * dt)
		var contact_torque: Vector3 = frame.left_contact_offset.cross(frame.left_force)
		contact_torque += frame.right_contact_offset.cross(frame.right_force)
		angular_velocity += (contact_torque / (tuning.stone_mass * tuning.stone_radius * tuning.stone_radius)) * dt
		var roll_axis: Vector3 = frame.contact_normal.cross(frame.roll_direction)
		if roll_axis.length_squared() > 0.001:
			roll_axis = roll_axis.normalized()
			var roll_spin: Vector3 = roll_axis * angular_velocity.dot(roll_axis)
			var stray_spin: Vector3 = angular_velocity - roll_spin
			angular_velocity = roll_spin + stray_spin * (1.0 - tuning.spin_damping_strength)
		angular_velocity *= maxf(0.0, 1.0 - tuning.stone_angular_damp * dt)
		position += velocity * dt
		position.y = mountain.height_at(position.z) + tuning.stone_radius
	mountain.free()
	return {
		"start_position": first_position,
		"end_position": position,
		"end_velocity": velocity,
		"end_angular_speed": angular_velocity.length(),
		"max_force_uphill": max_force_uphill,
		"max_side_force": max_side_force,
		"max_contact_height": max_contact_height,
		"last_force": last_force,
	}


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
