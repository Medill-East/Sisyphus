extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const PushControllerScript = preload("res://scripts/PushController.gd")
const GameStateScript = preload("res://scripts/GameState.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	await test_contact_push_uses_offset_force()
	await test_continuous_contact_push_moves_stone_uphill()
	await test_released_contact_push_stops_scripted_climb()
	await test_biased_contact_push_moves_laterally()
	await test_contact_push_does_not_spin_in_place()
	await test_bad_contact_angle_cannot_motor_uphill()
	await test_near_bad_contact_angle_loses_ground_under_load()
	await test_bad_contact_angle_holding_w_cannot_climb()
	await test_standard_bad_angle_holding_w_loses_ground()
	await test_released_stone_rolls_back_downhill()
	await test_standard_released_stone_rolls_back_downhill()
	await test_upward_aim_changes_contact_without_lifting()
	await test_first_person_hands_exist_and_body_can_hide()
	if failures.is_empty():
		print("All contact push physics tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_contact_push_uses_offset_force() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	var frame = PushControllerScript.calculate_push_frame(
		main.stone.global_position,
		_downhill_player_position(main),
		main.mountain.uphill_tangent_at(main.stone.global_position.z),
		true,
		0.0,
		main.tuning,
		main.mountain
	)
	var contact_valid = frame.get("contact_valid")
	var contact_offset = frame.get("contact_offset")
	var force_application_offset = frame.get("force_application_offset")
	var contact_force = frame.get("contact_force")
	_expect_true(contact_valid == true, "push frame should mark the hand contact valid from the downhill side")
	_expect_true(contact_offset is Vector3 and contact_offset.length() > main.tuning.stone_radius * 0.35, "push should use an off-center contact offset")
	_expect_true(
		force_application_offset is Vector3
		and force_application_offset.length() > main.tuning.stone_radius * 0.12
		and force_application_offset.length() < contact_offset.length() * 0.45,
		"two-hand resultant should keep a shorter effective lever arm than the visible palm contact"
	)
	_expect_true(contact_force is Vector3 and contact_force.length() > 1.0, "contact push should produce a positioned force")
	_expect_true(frame.central_force.length() < 0.001, "contact push should not rely on central force as its main driver")
	_expect_true(frame.roll_torque.length() < 0.001, "contact push should not rely on scripted torque")
	main.queue_free()
	await process_frame


func test_continuous_contact_push_moves_stone_uphill() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	var start_z: float = main.stone.global_position.z
	await _simulate_contact_push(main, 300, true, 0.0, Vector3.ZERO)
	var uphill_gain: float = start_z - main.stone.global_position.z
	_expect_true(uphill_gain > 0.85, "continuous contact push should move the stone uphill in real scene physics: %.2f" % uphill_gain)
	main.queue_free()
	await process_frame


func test_released_contact_push_stops_scripted_climb() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	await _simulate_contact_push(main, 130, true, 0.0, Vector3.ZERO)
	var release_z: float = main.stone.global_position.z
	await _simulate_contact_push(main, 150, false, 0.0, Vector3.ZERO)
	var uphill_after_release: float = release_z - main.stone.global_position.z
	_expect_true(uphill_after_release < 0.45, "released stone should not keep climbing from scripted push")
	main.queue_free()
	await process_frame


func test_biased_contact_push_moves_laterally() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	var start_position: Vector3 = main.stone.global_position
	await _simulate_contact_push(main, 260, true, 0.0, Vector3.RIGHT * 0.9)
	var lateral_delta: float = main.stone.global_position.x - start_position.x
	_expect_true(lateral_delta > 0.18, "right-biased camera aim should create visible rightward drift")
	_expect_true(absf(lateral_delta) < 2.2, "biased push should stay recoverable on the route")
	_expect_true(main.stone.global_position.z < start_position.z - 0.45, "biased contact push should still move uphill")
	main.queue_free()
	await process_frame


func test_contact_push_does_not_spin_in_place() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	var start_position: Vector3 = main.stone.global_position
	await _simulate_contact_push(main, 260, true, 0.0, Vector3.RIGHT * 0.55)
	var horizontal_distance := Vector2(
		main.stone.global_position.x - start_position.x,
		main.stone.global_position.z - start_position.z
	).length()
	var spin_ratio: float = main.stone.angular_velocity.length() / maxf(main.stone.linear_velocity.length(), 0.05)
	_expect_true(horizontal_distance > 0.7, "contact push should translate the stone instead of spinning in place: %.2f" % horizontal_distance)
	_expect_true(spin_ratio < 10.0, "contact push angular speed should stay coupled to linear motion: %.2f" % spin_ratio)
	main.queue_free()
	await process_frame


func test_bad_contact_angle_cannot_motor_uphill() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	var stone_position: Vector3 = main.stone.global_position
	var uphill: Vector3 = main.mountain.uphill_tangent_at(stone_position.z)
	var bad_aim: Vector3 = (uphill + Vector3.UP * 1.55 + Vector3.RIGHT * 1.25).normalized()
	var sweet_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		_downhill_player_position(main),
		uphill,
		true,
		0.0,
		main.tuning,
		main.mountain,
		main.tuning.push_force_ramp_seconds + 0.2
	)
	var frame = PushControllerScript.calculate_push_frame(
		stone_position,
		_downhill_player_position(main),
		bad_aim,
		true,
		0.0,
		main.tuning,
		main.mountain,
		main.tuning.push_force_ramp_seconds + 0.2
	)
	_expect_true(
		frame.force_uphill_component < sweet_frame.force_uphill_component * 0.72,
		"bad high/side contact should be materially weaker than a sweet-spot push"
	)
	_expect_true(
		frame.contact_quality < sweet_frame.contact_quality * 0.75,
		"bad high/side contact should expose low angle quality for player feedback"
	)
	main.queue_free()
	await process_frame


func test_near_bad_contact_angle_loses_ground_under_load() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	var start_z: float = main.stone.global_position.z
	var weak_aim := Vector3.RIGHT * 0.72 + Vector3.UP * 0.78
	await _simulate_contact_push(main, 220, true, 0.0, weak_aim)
	var uphill_gain: float = start_z - main.stone.global_position.z
	_expect_true(
		uphill_gain < -0.10,
		"near-bad contact should lose ground under the stone's weight instead of slowly motoring uphill: %.2f" % uphill_gain
	)
	main.queue_free()
	await process_frame


func test_bad_contact_angle_holding_w_cannot_climb() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	var start_z: float = main.stone.global_position.z
	var bad_aim := Vector3.RIGHT * 1.25 + Vector3.UP * 1.35
	var uphill: Vector3 = main.mountain.uphill_tangent_at(main.stone.global_position.z)
	var bad_aim_direction: Vector3 = (uphill + bad_aim).normalized()
	var initial_bad_frame = PushControllerScript.calculate_push_frame(
		main.stone.global_position,
		_downhill_player_position(main),
		bad_aim_direction,
		true,
		0.0,
		main.tuning,
		main.mountain,
		main.tuning.push_force_ramp_seconds + 0.2
	)
	await _simulate_contact_push(main, 210, true, 0.0, bad_aim)
	var uphill_gain: float = start_z - main.stone.global_position.z
	_expect_true(
		uphill_gain < 0.12,
		"holding W at a bad high/side contact should not motor the stone uphill: %.2f" % uphill_gain
	)
	_expect_true(
		initial_bad_frame.contact_quality < main.tuning.first_person_hands_min_contact_quality,
		"bad high/side contact should remain readable as a weak angle while W is held: %.2f threshold %.2f" % [
			initial_bad_frame.contact_quality,
			main.tuning.first_person_hands_min_contact_quality,
		]
	)
	main.queue_free()
	await process_frame


func test_standard_bad_angle_holding_w_loses_ground() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.tuning.apply_push_lab_preset("standard")
	_prepare_ascent(main)
	var start_z: float = main.stone.global_position.z
	var bad_aim := Vector3.RIGHT * 0.92 + Vector3.UP * 0.92
	await _simulate_contact_push(main, 240, true, 0.0, bad_aim)
	var uphill_gain: float = start_z - main.stone.global_position.z
	_expect_true(
		uphill_gain < -0.08,
		"standard preset should make a plausible but wrong high/side pressure point lose ground: %.2f" % uphill_gain
	)
	main.queue_free()
	await process_frame


func test_released_stone_rolls_back_downhill() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	await _simulate_contact_push(main, 90, true, 0.0, Vector3.ZERO)
	main.stone.linear_velocity = Vector3.ZERO
	main.stone.angular_velocity = Vector3.ZERO
	var release_z: float = main.stone.global_position.z
	await _simulate_contact_push(main, 180, false, 0.0, Vector3.ZERO)
	_expect_true(
		main.stone.global_position.z > release_z + 0.42,
		"released stone on the front slope should visibly roll back downhill when the player stops pushing"
	)
	main.queue_free()
	await process_frame


func test_standard_released_stone_rolls_back_downhill() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.tuning.apply_push_lab_preset("standard")
	_prepare_ascent(main)
	await _simulate_contact_push(main, 100, true, 0.0, Vector3.ZERO)
	main.stone.linear_velocity = Vector3.ZERO
	main.stone.angular_velocity = Vector3.ZERO
	var release_z: float = main.stone.global_position.z
	await _simulate_contact_push(main, 180, false, 0.0, Vector3.ZERO)
	_expect_true(
		main.stone.global_position.z > release_z + 0.42,
		"standard preset released stone should roll back downhill on the front slope"
	)
	main.queue_free()
	await process_frame


func test_upward_aim_changes_contact_without_lifting() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	_prepare_ascent(main)
	var stone_position: Vector3 = main.stone.global_position
	var player_position: Vector3 = _downhill_player_position(main)
	var uphill: Vector3 = main.mountain.uphill_tangent_at(stone_position.z)
	var low_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.DOWN * 0.25).normalized(),
		true,
		0.0,
		main.tuning,
		main.mountain
	)
	var high_frame = PushControllerScript.calculate_push_frame(
		stone_position,
		player_position,
		(uphill + Vector3.UP * 1.0).normalized(),
		true,
		0.0,
		main.tuning,
		main.mountain
	)
	var low_force = low_frame.get("contact_force")
	var high_force = high_frame.get("contact_force")
	_expect_true(high_frame.contact_point.y - low_frame.contact_point.y > 0.20, "upward aim should raise the hand contact point")
	_expect_true(
		low_force is Vector3 and high_force is Vector3 and high_force.normalized().dot(Vector3.UP) <= low_force.normalized().dot(Vector3.UP) + 0.08,
		"upward aim should change contact quality instead of adding a lifting force direction"
	)
	main.queue_free()
	await process_frame


func test_first_person_hands_exist_and_body_can_hide() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	var hands = main.player.get_node_or_null("FirstPersonHands")
	_expect_true(hands != null, "player should have a first-person hands layer")
	if hands != null:
		_expect_true(hands.get_node_or_null("LeftHand") != null, "first-person layer should expose left hand")
		_expect_true(hands.get_node_or_null("RightHand") != null, "first-person layer should expose right hand")
		_expect_true(hands.has_method("update_from_camera"), "first-person hands should own its camera-follow update logic")
	_prepare_ascent(main)
	var uphill: Vector3 = main.mountain.uphill_tangent_at(main.stone.global_position.z)
	main.player.global_position = main.stone.global_position + main.mountain.downhill_tangent_at(main.stone.global_position.z) * main.tuning.stone_radius * 1.55
	main.player.global_position.y = main.mountain.height_at(main.player.global_position.z) + 0.05
	main.player.push_frame = PushControllerScript.calculate_push_frame(
		main.stone.global_position,
		main.player.global_position,
		uphill,
		true,
		0.0,
		main.tuning,
		main.mountain,
		main.tuning.push_force_ramp_seconds + 0.1
	)
	main.player.camera_push_blend = 1.0
	main.player.push_engaged = true
	main.player.push_contact_seconds = main.tuning.first_person_hands_min_contact_seconds + 0.05
	main.camera.global_position = main.player.push_camera_origin_for(
		main.player.push_frame.aim_direction,
		main.player.push_frame.camera_contact_point,
		main.stone.global_position,
		main.player.camera_push_blend
	)
	if main.player.has_method("update_push_visual_mode"):
		main.player.update_push_visual_mode()
	else:
		_expect_true(false, "player should expose update_push_visual_mode for first-person push visuals")
	_expect_true(not main.player.get_node("Body").visible, "third-person body should hide in full push view")
	if hands != null:
		_expect_true(hands.visible, "first-person hands should be visible in full push view")
	main.queue_free()
	await process_frame


func _prepare_ascent(main) -> void:
	main.game_state.phase = GameStateScript.Phase.ASCENT
	main.stone.freeze = false
	var z: float = main.tuning.front_base_z - 4.0
	main.stone.global_position = Vector3(0.0, main.mountain.height_at(z) + main.tuning.stone_radius + 0.04, z)
	main.stone.linear_velocity = Vector3.ZERO
	main.stone.angular_velocity = Vector3.ZERO
	main.player.global_position = _downhill_player_position(main)
	main.player.camera_yaw = 0.0
	main.player.camera_pitch = -0.06


func _simulate_contact_push(main, frames: int, is_pushing: bool, lateral_axis: float, aim_offset: Vector3) -> void:
	for index in frames:
		var uphill: Vector3 = main.mountain.uphill_tangent_at(main.stone.global_position.z)
		var player_position: Vector3 = _downhill_player_position(main)
		main.player.global_position = player_position
		var camera_direction: Vector3 = (uphill + aim_offset).normalized()
		main.player.push_frame = PushControllerScript.apply_push(
			main.stone,
			player_position,
			camera_direction,
			is_pushing,
			lateral_axis,
			main.tuning,
			main.mountain
		)
		await physics_frame


func _downhill_player_position(main) -> Vector3:
	var downhill: Vector3 = main.mountain.downhill_tangent_at(main.stone.global_position.z)
	var position: Vector3 = main.stone.global_position + downhill * main.tuning.stone_radius * 1.55
	position.y = main.mountain.height_at(position.z) + 0.05
	return position


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
