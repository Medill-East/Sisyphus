extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const PlayerScene = preload("res://scenes/Player.tscn")
const FirstPersonHandsScene = preload("res://scenes/FirstPersonHands.tscn")
const GameStateScript = preload("res://scripts/GameState.gd")
const TuningScript = preload("res://scripts/Tuning.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")
const PlayerControllerScript = preload("res://scripts/PlayerController.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	test_player_arm_visual_ratio()
	test_first_person_hands_have_torso_anchor()
	test_approach_reach_blend_is_gradual()
	test_two_segment_arm_pose_uses_partial_reach()
	test_push_body_input_preserves_burdened_step_strength()
	test_push_camera_is_close_but_not_inside_stone()
	await test_push_camera_origin_tracks_selected_contact_target()
	await test_biased_push_camera_keeps_peripheral_readability()
	await test_push_look_allows_peripheral_scan_and_low_contact_view()
	await test_mouse_right_aims_to_route_right()
	await test_live_player_push_uses_reticle_aligned_frame()
	await test_player_hand_is_parented_to_arm_chain()
	await test_ascent_without_push_keeps_player_free_to_return()
	await test_descent_idle_does_not_slide()
	await test_descent_input_moves_player()
	await test_complete_phase_locks_player_until_transition()
	await test_push_exit_blends_camera_back_to_shoulder()
	if failures.is_empty():
		print("All player behavior tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_player_arm_visual_ratio() -> void:
	var player = PlayerScene.instantiate()
	root.add_child(player)
	var left_upper = player.get_node_or_null("Body/LeftArm/UpperArm")
	var left_forearm = player.get_node_or_null("Body/LeftArm/Forearm")
	var left_hand = player.get_node_or_null("Body/LeftArm/Hand")
	_expect_true(left_upper != null, "player should have an upper-arm mesh")
	_expect_true(left_forearm != null, "player should have a forearm mesh")
	_expect_true(left_hand != null, "player should have a hand mesh")
	if left_upper != null and left_forearm != null and left_hand != null:
		var forearm_mesh = left_forearm.mesh
		var hand_mesh = left_hand.mesh
		var forearm_spacing: float = absf(left_forearm.position.y - left_upper.position.y)
		_expect_true(hand_mesh.radius >= 0.105, "hand should be large enough relative to the arm: %.3f" % hand_mesh.radius)
		_expect_true(forearm_mesh.height <= 0.42, "forearm capsule mesh should be short enough: %.3f" % forearm_mesh.height)
		_expect_true(forearm_spacing <= 0.32, "forearm should not be staged like a long stick: %.3f" % forearm_spacing)
	player.queue_free()
	await process_frame


func test_first_person_hands_have_torso_anchor() -> void:
	var hands = FirstPersonHandsScene.instantiate()
	root.add_child(hands)
	var chest: MeshInstance3D = hands.get_node_or_null("Chest")
	var left_upper: MeshInstance3D = hands.get_node_or_null("LeftUpperArm")
	var right_upper: MeshInstance3D = hands.get_node_or_null("RightUpperArm")
	_expect_true(chest != null, "first-person push view should include a torso/chest anchor, not only floating hands")
	_expect_true(left_upper != null and right_upper != null, "first-person hands should include upper arms to read as attached to a body")
	if chest != null and chest.mesh is BoxMesh:
		var size: Vector3 = chest.mesh.size
		_expect_true(size.x >= 0.80 and size.y >= 0.24 and size.z >= 0.16, "first-person chest anchor should be visible enough without blocking the lower frame: %s" % str(size))
	hands.queue_free()
	await process_frame


func test_approach_reach_blend_is_gradual() -> void:
	var tuning = TuningScript.new()
	var far_target: float = PlayerControllerScript.calculate_stone_reach_target(tuning.contact_distance + 1.05, false, tuning)
	var edge_target: float = PlayerControllerScript.calculate_stone_reach_target(tuning.contact_distance + 0.36, false, tuning)
	var close_target: float = PlayerControllerScript.calculate_stone_reach_target(tuning.contact_distance - 0.14, false, tuning)
	var engaged_target: float = PlayerControllerScript.calculate_stone_reach_target(tuning.contact_distance + 0.36, true, tuning)
	var first_frame: float = PlayerControllerScript.calculate_reach_blend(0.0, engaged_target, 1.0 / 60.0, tuning)
	_expect_true(far_target <= 0.02, "hands should stay idle when still outside approach reach")
	_expect_true(edge_target > 0.05 and edge_target < 0.55, "approach reach should begin partially instead of snapping on: %.2f" % edge_target)
	_expect_true(close_target > edge_target and close_target < 1.0, "close approach should increase reach without becoming full push instantly: %.2f" % close_target)
	_expect_true(engaged_target == 1.0, "engaged push can request full reach")
	_expect_true(first_frame > 0.0 and first_frame < 0.20, "first contact frame should not jump to full arm extension: %.2f" % first_frame)


func test_two_segment_arm_pose_uses_partial_reach() -> void:
	var tuning = TuningScript.new()
	var left_contact := Vector3(-0.24, 1.02, -0.50)
	var right_contact := Vector3(0.24, 1.02, -0.50)
	var idle_pose = PlayerControllerScript.calculate_two_segment_arm_pose(
		0.0,
		false,
		0.0,
		false,
		left_contact,
		right_contact,
		Vector3(0.0, 0.0, -1.0),
		tuning
	)
	var partial_pose = PlayerControllerScript.calculate_two_segment_arm_pose(
		0.0,
		false,
		0.45,
		false,
		left_contact,
		right_contact,
		Vector3(0.0, 0.0, -1.0),
		tuning
	)
	var full_pose = PlayerControllerScript.calculate_two_segment_arm_pose(
		0.0,
		false,
		1.0,
		true,
		left_contact,
		right_contact,
		Vector3(0.0, 0.0, -1.0),
		tuning
	)
	_expect_true(partial_pose.reach > idle_pose.reach and partial_pose.reach < full_pose.reach, "arm reach should support partial approach poses")
	_expect_true(
		partial_pose.left_hand.distance_to(idle_pose.left_hand) < full_pose.left_hand.distance_to(idle_pose.left_hand) * 0.70,
		"partial approach hands should not visually jump to the full push contact"
	)


func test_push_body_input_preserves_burdened_step_strength() -> void:
	var walking_input := Vector3(0.0, 0.0, -0.46)
	var push_input := Vector3(0.0, 0.0, -0.46)
	var shaped_walk: Vector3 = PlayerControllerScript.shape_body_move_input(walking_input, false)
	var shaped_push: Vector3 = PlayerControllerScript.shape_body_move_input(push_input, true)
	_expect_true(absf(shaped_walk.length() - 1.0) < 0.001, "normal walking input should still normalize for responsive movement")
	_expect_true(shaped_push.length() > 0.40 and shaped_push.length() < 0.55, "push body step should preserve partial burdened input instead of normalizing to full speed: %.2f" % shaped_push.length())


func test_push_camera_is_close_but_not_inside_stone() -> void:
	var tuning = TuningScript.new()
	var player_to_stone: float = tuning.stone_radius * 1.65
	var camera_to_stone: float = player_to_stone - tuning.push_camera_distance
	_expect_true(absf(tuning.push_camera_distance) < tuning.shoulder_distance * 0.25, "push camera should be much closer than the normal shoulder camera")
	_expect_true(camera_to_stone > tuning.stone_radius + 0.45, "push camera should stay outside the stone with hand/contact room")
	_expect_true(camera_to_stone < tuning.shoulder_distance, "push camera should stay near the pushing body")
	_expect_true(tuning.push_camera_fov >= 100.0 and tuning.push_camera_fov <= 112.0, "push camera should stay wide without fisheye distortion")


func test_push_camera_origin_tracks_selected_contact_target() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	var z: float = main.tuning.front_base_z - 4.0
	main.stone.global_position = Vector3(0.0, main.mountain.height_at(z) + main.tuning.stone_radius + 0.08, z)
	main.player.global_position = main.stone.global_position + main.mountain.downhill_tangent_at(z) * main.tuning.stone_radius * 1.55
	main.player.global_position.y = main.mountain.height_at(main.player.global_position.z) + 0.05
	main.player.camera_push_blend = 1.0
	var uphill: Vector3 = main.mountain.uphill_tangent_at(z)
	var side: Vector3 = Vector3(-uphill.z, 0.0, uphill.x).normalized()
	var camera_direction: Vector3 = (uphill + side * 0.42 + Vector3.DOWN * 0.18).normalized()
	var left_contact: Vector3 = main.stone.global_position + (-uphill * 0.62 + side * -0.42 + Vector3.UP * 0.26).normalized() * main.tuning.stone_radius
	var right_contact: Vector3 = main.stone.global_position + (-uphill * 0.62 + side * 0.42 + Vector3.UP * 0.26).normalized() * main.tuning.stone_radius
	var left_origin: Vector3 = main.player.push_camera_origin_for(camera_direction, left_contact, main.stone.global_position, 1.0)
	var right_origin: Vector3 = main.player.push_camera_origin_for(camera_direction, right_contact, main.stone.global_position, 1.0)
	_expect_true(
		absf((right_origin - left_origin).dot(side)) > 0.28,
		"push camera origin should move with the selected reticle contact target instead of staying body-locked"
	)
	_expect_true(
		absf(left_origin.distance_to(left_contact) - main.tuning.push_camera_contact_distance) < 0.28,
		"left push camera origin should keep the selected contact at the tuned first-person distance"
	)
	_expect_true(
		absf(right_origin.distance_to(right_contact) - main.tuning.push_camera_contact_distance) < 0.28,
		"right push camera origin should keep the selected contact at the tuned first-person distance"
	)
	main.queue_free()
	await process_frame


func test_biased_push_camera_keeps_peripheral_readability() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.game_state.phase = GameStateScript.Phase.ASCENT
	var z: float = main.tuning.front_base_z - 4.0
	main.stone.global_position = Vector3(0.0, main.mountain.height_at(z) + main.tuning.stone_radius + 0.08, z)
	main.player.global_position = main.stone.global_position + main.mountain.downhill_tangent_at(z) * main.tuning.stone_radius * 1.55
	main.player.global_position.y = main.mountain.height_at(main.player.global_position.z) + 0.05
	var camera_direction: Vector3 = (main.mountain.uphill_tangent_at(z) + Vector3.RIGHT * 0.9).normalized()
	main.player.push_frame = PushControllerScript.calculate_push_frame(
		main.stone.global_position,
		main.player.global_position,
		camera_direction,
		true,
		0.0,
		main.tuning,
		main.mountain
	)
	main.player.camera_push_blend = 1.0
	main.player._update_camera(1.0, main.stone.global_position, camera_direction, true)
	var camera_to_stone: float = main.camera.global_position.distance_to(main.stone.global_position)
	_expect_true(camera_to_stone > 1.45, "biased push camera should stay outside the stone while keeping route edges readable")
	_expect_true(camera_to_stone < 2.35, "biased push camera should remain an intimate first-person push view")
	_expect_true(main.camera.fov >= 100.0 and main.camera.fov <= 112.0, "push camera should use a readable wide FOV instead of fisheye")
	main.queue_free()
	await process_frame


func test_push_look_allows_peripheral_scan_and_low_contact_view() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.game_state.phase = GameStateScript.Phase.ASCENT
	main.player.push_engaged = true
	main.player.camera_push_blend = 1.0
	var z: float = main.tuning.front_base_z - 4.0
	main.stone.global_position = Vector3(0.0, main.mountain.height_at(z) + main.tuning.stone_radius + 0.08, z)
	main.player.camera_yaw = atan2(main.mountain.uphill_tangent_at(z).x, -main.mountain.uphill_tangent_at(z).z)
	main.player.camera_pitch = -0.06
	main.player.apply_look_delta(Vector2(720.0, 520.0))
	main.player._constrain_push_look(main.stone.global_position)
	var uphill: Vector3 = main.mountain.uphill_tangent_at(z)
	var anchor: float = atan2(uphill.x, -uphill.z)
	_expect_true(absf(main.player.camera_yaw - anchor) >= 1.02, "push view should allow enough side scan for peripheral route judgment")
	_expect_true(main.player.camera_pitch <= -1.15, "push view should allow looking down at hands/contact, not only forward")
	main.queue_free()
	await process_frame


func test_mouse_right_aims_to_route_right() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.game_state.phase = GameStateScript.Phase.ASCENT
	main.player.push_engaged = true
	main.player.camera_push_blend = 1.0
	var z: float = main.tuning.front_base_z - 4.0
	main.stone.global_position = Vector3(0.0, main.mountain.height_at(z) + main.tuning.stone_radius + 0.08, z)
	var uphill: Vector3 = main.mountain.uphill_tangent_at(z)
	var route_side: Vector3 = Vector3(-uphill.z, 0.0, uphill.x).normalized()
	main.player.camera_yaw = atan2(uphill.x, -uphill.z)
	main.player.camera_pitch = -0.06
	main.player.apply_look_delta(Vector2(220.0, 0.0))
	main.player._constrain_push_look(main.stone.global_position)
	var camera_forward: Vector3 = main.player._camera_forward()
	_expect_true(camera_forward.dot(route_side) > 0.30, "moving the mouse/trackpad right should aim toward the route's right side")
	main.queue_free()
	await process_frame


func test_live_player_push_uses_reticle_aligned_frame() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.game_state.phase = GameStateScript.Phase.ASCENT
	var z: float = main.tuning.front_base_z - 5.0
	main.stone.global_position = Vector3(0.0, main.mountain.height_at(z) + main.tuning.stone_radius + 0.08, z)
	main.player.global_position = main.stone.global_position + main.mountain.downhill_tangent_at(z) * main.tuning.stone_radius * 1.55
	main.player.global_position.y = main.mountain.height_at(main.player.global_position.z) + 0.05
	main.player.camera_push_blend = 1.0
	var camera_direction: Vector3 = (main.mountain.uphill_tangent_at(z) + Vector3.LEFT * 0.86 + Vector3.DOWN * 0.38).normalized()
	_expect_true(main.player.has_method("calculate_reticle_aligned_push_frame"), "live player controller should expose reticle-aligned push-frame solving")
	if main.player.has_method("calculate_reticle_aligned_push_frame"):
		var frame = main.player.call(
			"calculate_reticle_aligned_push_frame",
			camera_direction,
			true,
			0.0,
			main.tuning.push_force_ramp_seconds + 0.2
		)
		var origin: Vector3 = main.player.push_camera_origin_for(
			frame.aim_direction,
			frame.camera_contact_point,
			main.stone.global_position,
			main.player.camera_push_blend
		)
		var ray_to_contact: Vector3 = (frame.camera_contact_point - origin).normalized()
		_expect_true(ray_to_contact.dot(frame.aim_direction) > 0.995, "live push frame should align the reticle ray with the chosen hand contact point")
		_expect_true(frame.camera_contact_point.distance_to(main.stone.global_position) <= main.tuning.stone_radius + 0.02, "reticle-aligned contact should stay on the stone surface")
	main.queue_free()
	await process_frame


func test_player_hand_is_parented_to_arm_chain() -> void:
	var player = PlayerScene.instantiate()
	root.add_child(player)
	_expect_true(player.get_node_or_null("Body/LeftArm/Hand") != null, "left hand should live under the left arm chain")
	_expect_true(player.get_node_or_null("Body/RightArm/Hand") != null, "right hand should live under the right arm chain")
	_expect_true(player.get_node_or_null("Body/LeftHand") == null, "left hand should not float directly under body")
	_expect_true(player.get_node_or_null("Body/RightHand") == null, "right hand should not float directly under body")
	player.queue_free()
	await process_frame


func test_ascent_without_push_keeps_player_free_to_return() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.game_state.phase = GameStateScript.Phase.ASCENT
	main.player.push_engaged = false
	var stone_position: Vector3 = main.stone.global_position
	main.player.global_position = stone_position + main.mountain.downhill_tangent_at(stone_position.z) * (main.tuning.contact_distance + 1.0)
	main.player.global_position.y = main.mountain.height_at(main.player.global_position.z) + 0.05
	var start_distance: float = main.player.global_position.distance_to(stone_position)
	main.player.apply_test_move(Vector2(0.0, 1.0), 0.4)
	var end_distance: float = main.player.global_position.distance_to(stone_position)
	_expect_true(end_distance < start_distance - 0.25, "ascent without engaged push should allow walking back toward the stone")
	main.queue_free()
	await process_frame


func test_descent_idle_does_not_slide() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.game_state.phase = GameStateScript.Phase.DESCENT
	main.player.global_position = Vector3(0, main.mountain.height_at(main.tuning.ridge_z - 8.0) + 0.05, main.tuning.ridge_z - 8.0)
	var start_position: Vector3 = main.player.global_position
	for index in 120:
		await physics_frame
	var horizontal_delta := Vector2(
		main.player.global_position.x - start_position.x,
		main.player.global_position.z - start_position.z
	).length()
	_expect_true(horizontal_delta < 0.05, "descent idle should not slide the player down the slope")
	main.queue_free()
	await process_frame


func test_descent_input_moves_player() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.game_state.phase = GameStateScript.Phase.DESCENT
	var start_position: Vector3 = main.player.global_position
	main.player.apply_test_move(Vector2(0.0, 1.0), 0.5)
	var horizontal_delta := Vector2(
		main.player.global_position.x - start_position.x,
		main.player.global_position.z - start_position.z
	).length()
	_expect_true(horizontal_delta > 0.4, "descent input should move the player")
	main.queue_free()
	await process_frame


func test_complete_phase_locks_player_until_transition() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.game_state.phase = GameStateScript.Phase.COMPLETE
	main.player.push_engaged = true
	main.player.camera_push_blend = 1.0
	var start_position: Vector3 = main.player.global_position
	Input.action_press("move_forward")
	Input.action_press("push_left")
	Input.action_press("push_right")
	for index in 60:
		await physics_frame
	Input.action_release("move_forward")
	Input.action_release("push_left")
	Input.action_release("push_right")
	var horizontal_delta := Vector2(
		main.player.global_position.x - start_position.x,
		main.player.global_position.z - start_position.z
	).length()
	_expect_true(horizontal_delta < 0.05, "complete should end chapter control instead of allowing same-scene wandering")
	_expect_true(not main.player.push_engaged, "complete should clear push engagement")
	_expect_true(main.player.camera_push_blend < 1.0, "complete should blend out of push camera")
	main.queue_free()
	await process_frame


func test_push_exit_blends_camera_back_to_shoulder() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	main.player.camera_push_blend = 1.0
	main.player.push_engaged = false
	for index in 30:
		main.player.camera_push_blend = main.player.calculate_camera_blend(main.player.camera_push_blend, false, 1.0 / 60.0, main.tuning)
	_expect_true(main.player.camera_push_blend < 0.35, "camera should blend back toward shoulder view after push exits")
	_expect_true(main.player.camera_push_blend > 0.0, "camera exit should be smooth instead of snapping off")
	main.queue_free()
	await process_frame


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
