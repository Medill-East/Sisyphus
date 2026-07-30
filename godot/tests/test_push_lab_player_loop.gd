extends SceneTree

const PushLabScene = preload("res://scenes/PushLab.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	await test_push_lab_starts_with_stone_resting_until_player_pushes()
	await test_transition_contact_ignores_shoulder_camera_parallax()
	await test_player_held_w_pushes_with_real_controller()
	await test_real_controller_push_force_ramps_up()
	await test_real_controller_requires_brace_before_breakaway()
	await test_fast_aim_breaks_brace_while_w_is_held()
	await test_player_body_cannot_overlap_stone_contact_shell()
	await test_push_does_not_hard_snap_player_to_rear_anchor()
	await test_released_mid_slope_stone_rolls_back_downhill()
	await test_player_release_stops_contact_push_and_can_reapproach()
	await test_reapproach_requires_player_to_aim_toward_stone()
	await test_bad_side_contact_loses_push_and_rolls_back()
	await test_camera_bias_changes_manual_push_direction()
	await test_sustained_camera_bias_creates_route_pressure()
	await test_obstacle_glance_slowdown_is_recoverable()
	_release_all_actions()
	if failures.is_empty():
		print("All push lab player-loop tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_push_lab_starts_with_stone_resting_until_player_pushes() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	var start_position: Vector3 = lab.stone.global_position
	for index in 180:
		await physics_frame
	var drift := Vector2(
		lab.stone.global_position.x - start_position.x,
		lab.stone.global_position.z - start_position.z
	).length()
	_expect_true(drift < 0.12, "push lab stone should not roll away before the player starts pushing: %.2f" % drift)
	lab.queue_free()
	await process_frame


func test_transition_contact_ignores_shoulder_camera_parallax() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	_place_stone_on_front_slope(lab, lab.tuning.front_base_z - 6.0)
	lab.player.camera_push_blend = 0.0
	var frame = lab.player.calculate_reticle_aligned_push_frame(
		lab.player._camera_forward(),
		true,
		0.0,
		0.5,
		1.0
	)
	var route_side: Vector3 = Vector3(-frame.uphill_direction.z, 0.0, frame.uphill_direction.x).normalized()
	var contact_side: float = frame.contact_offset.normalized().dot(route_side)
	_expect_true(absf(contact_side) < 0.18, "center push aim should not inherit right-shoulder parallax during camera transition: %.2f" % contact_side)
	_expect_true(frame.contact_quality > 0.82, "center push aim should start inside the learnable pressure band: %.2f" % frame.contact_quality)
	lab.queue_free()
	await process_frame


func test_player_held_w_pushes_with_real_controller() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	var start_stone: Vector3 = lab.stone.global_position
	var start_player: Vector3 = lab.player.global_position
	var max_step: float = 0.0
	var previous_player: Vector3 = start_player
	_press_forward()
	for index in 260:
		await physics_frame
		max_step = maxf(max_step, lab.player.global_position.distance_to(previous_player))
		previous_player = lab.player.global_position
	_release_all_actions()
	var uphill_gain: float = start_stone.z - lab.stone.global_position.z
	var player_gain: float = start_player.z - lab.player.global_position.z
	var spin_ratio: float = lab.stone.angular_velocity.length() / maxf(lab.stone.linear_velocity.length(), 0.05)
	_expect_true(uphill_gain > 0.55, "manual W push should move the stone uphill with the real player controller")
	_expect_true(player_gain > 0.18, "manual W push should move the player by input instead of leaving them behind")
	_expect_true(max_step < 0.14, "player should not be teleported or hard-snapped while pushing: %.3f" % max_step)
	_expect_true(spin_ratio < 10.0, "manual push should translate the stone instead of mostly spinning in place: %.2f" % spin_ratio)
	lab.queue_free()
	await process_frame


func test_real_controller_push_force_ramps_up() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	var early_force: float = -1.0
	var settled_force: float = 0.0
	_press_forward()
	for index in 90:
		await physics_frame
		if lab.player.push_frame != null and lab.player.push_frame.contact_valid:
			if early_force < 0.0:
				early_force = lab.player.push_frame.force_uphill_component
			if index > 55:
				settled_force = maxf(settled_force, lab.player.push_frame.force_uphill_component)
	_release_all_actions()
	_expect_true(early_force > 0.0, "real push should produce an early contact force sample")
	_expect_true(settled_force > early_force * 1.65, "real push force should ramp up while W is held: early %.1f settled %.1f" % [early_force, settled_force])
	lab.queue_free()
	await process_frame


func test_real_controller_requires_brace_before_breakaway() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	_place_stone_on_front_slope(lab, lab.tuning.front_base_z - 6.0)
	var start_z: float = lab.stone.global_position.z
	var samples: Array[String] = []
	_press_forward()
	for index in 18:
		await physics_frame
		if index % 6 == 0:
			samples.append(_brace_sample(lab, index, start_z))
	var early_gain: float = start_z - lab.stone.global_position.z
	var early_brace: float = lab.player.push_brace
	for index in 222:
		await physics_frame
		if index % 24 == 0 or index == 221:
			samples.append(_brace_sample(lab, index + 18, start_z))
	var settled_brace: float = lab.player.push_brace
	var settled_quality: float = lab.player.push_frame.contact_quality if lab.player.push_frame != null else 0.0
	var settled_breakaway: float = lab.player.push_frame.breakaway_ratio if lab.player.push_frame != null else 0.0
	var settled_distance: float = lab.player.global_position.distance_to(lab.stone.global_position)
	var settled_force: Vector3 = lab.player.push_frame.contact_force if lab.player.push_frame != null else Vector3.ZERO
	var settled_uphill: Vector3 = lab.player.push_frame.uphill_direction if lab.player.push_frame != null else Vector3.ZERO
	var settled_offset: Vector3 = lab.player.push_frame.force_application_offset if lab.player.push_frame != null else Vector3.ZERO
	var desired_roll_axis: Vector3 = lab.player.push_frame.contact_normal.cross(settled_uphill).normalized() if lab.player.push_frame != null else Vector3.ZERO
	var torque_alignment: float = settled_offset.cross(settled_force).dot(desired_roll_axis)
	var settled_velocity: Vector3 = lab.stone.linear_velocity
	var settled_angular: Vector3 = lab.stone.angular_velocity
	_release_all_actions()
	var total_gain: float = start_z - lab.stone.global_position.z
	_expect_true(early_gain < 0.12, "first contact should strain before it breaks the stone uphill: %.2f" % early_gain)
	_expect_true(early_brace < 0.48, "brace should still be building during the first effort: %.2f" % early_brace)
	_expect_true(settled_brace > 0.68, "steady sweet-spot contact should eventually establish body leverage: %.2f" % settled_brace)
	_expect_true(
		total_gain > 0.42,
		"established brace should make slow real uphill progress: gain %.2f brace %.2f quality %.2f breakaway %.2f distance %.2f force %s uphill %s velocity %s angular %s torque_align %.2f samples %s" % [
			total_gain,
			settled_brace,
			settled_quality,
			settled_breakaway,
			settled_distance,
			str(settled_force),
			str(settled_uphill),
			str(settled_velocity),
			str(settled_angular),
			torque_alignment,
			str(samples),
		]
	)
	lab.queue_free()
	await process_frame


func test_fast_aim_breaks_brace_while_w_is_held() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	_place_stone_on_front_slope(lab, lab.tuning.front_base_z - 6.0)
	_press_forward()
	for index in 100:
		await physics_frame
	var stable_brace: float = lab.player.push_brace
	var stable_quality: float = lab.player.push_frame.contact_quality if lab.player.push_frame != null else 0.0
	var stable_breakaway: float = lab.player.push_frame.breakaway_ratio if lab.player.push_frame != null else 0.0
	var stable_distance: float = lab.player.global_position.distance_to(lab.stone.global_position)
	var unstable_start_z: float = lab.stone.global_position.z
	for index in 42:
		lab.player.camera_yaw = 0.24 if index % 2 == 0 else -0.24
		await physics_frame
	var unstable_brace: float = lab.player.push_brace
	_release_all_actions()
	var unstable_gain: float = unstable_start_z - lab.stone.global_position.z
	_expect_true(
		stable_brace > 0.64,
		"test needs an established brace before disturbing aim: brace %.2f quality %.2f breakaway %.2f distance %.2f" % [
			stable_brace,
			stable_quality,
			stable_breakaway,
			stable_distance,
		]
	)
	_expect_true(unstable_brace < stable_brace * 0.45, "rapid left/right corrections should break body leverage while W remains held")
	_expect_true(unstable_gain < 0.12, "broken leverage should stop hidden-motor climbing and allow stall/rollback: %.2f" % unstable_gain)
	lab.queue_free()
	await process_frame


func test_player_body_cannot_overlap_stone_contact_shell() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	var downhill: Vector3 = lab.mountain.downhill_tangent_at(lab.stone.global_position.z)
	lab.player.global_position = lab.stone.global_position + downhill * (lab.tuning.stone_radius * 0.78)
	lab.player.global_position.y = lab.mountain.height_at(lab.player.global_position.z) + 0.05
	_press_forward()
	for index in 4:
		await physics_frame
	_release_all_actions()
	var horizontal_delta := Vector2(
		lab.player.global_position.x - lab.stone.global_position.x,
		lab.player.global_position.z - lab.stone.global_position.z
	)
	var min_distance: float = lab.tuning.stone_radius + lab.tuning.player_body_radius + lab.tuning.player_stone_clearance
	_expect_true(horizontal_delta.length() >= min_distance - 0.02, "player body should be kept outside the stone contact shell")
	lab.queue_free()
	await process_frame


func test_push_does_not_hard_snap_player_to_rear_anchor() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	var downhill: Vector3 = lab.mountain.downhill_tangent_at(lab.stone.global_position.z)
	var flat_downhill := Vector3(downhill.x, 0.0, downhill.z).normalized()
	var side := Vector3(-flat_downhill.z, 0.0, flat_downhill.x).normalized()
	var offset: Vector3 = flat_downhill * (lab.tuning.stone_radius * 1.24) + side * 0.62
	lab.player.global_position = lab.stone.global_position + offset
	lab.player.global_position.y = lab.mountain.height_at(lab.player.global_position.z) + 0.05
	var rear_before: float = offset.dot(flat_downhill)
	lab.player._move(1.0 / 60.0, true, true, true)
	var after_offset := Vector3(
		lab.player.global_position.x - lab.stone.global_position.x,
		0.0,
		lab.player.global_position.z - lab.stone.global_position.z
	)
	var rear_after: float = after_offset.dot(flat_downhill)
	_expect_true(absf(rear_after - rear_before) < 0.04, "push movement should not teleport the body onto a hidden rear anchor: %.3f" % absf(rear_after - rear_before))
	lab.queue_free()
	await process_frame


func test_released_mid_slope_stone_rolls_back_downhill() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	_place_stone_on_front_slope(lab, lab.tuning.front_base_z - 10.0)
	_press_forward()
	for index in 85:
		await physics_frame
	_release_all_actions()
	var release_z: float = lab.stone.global_position.z
	var saw_rollback_state: bool = false
	var saw_hand_rollback_cue: bool = false
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	for index in 210:
		await physics_frame
		if lab.has_method("push_motion_state") and lab.push_motion_state() == "rollback":
			saw_rollback_state = true
		if hands != null and hands.has_method("feedback_state") and hands.feedback_state() == "rollback":
			saw_hand_rollback_cue = true
	var rollback_z: float = lab.stone.global_position.z - release_z
	_expect_true(rollback_z > 0.22, "released mid-slope stone should roll back downhill under gravity: %.2f" % rollback_z)
	_expect_true(lab.has_method("push_motion_state"), "push lab should expose a rollback-readable motion state")
	_expect_true(saw_rollback_state, "released mid-slope stone should visibly enter rollback state")
	_expect_true(saw_hand_rollback_cue, "first-person hands should show a rollback cue when the released stone pushes back")
	lab.queue_free()
	await process_frame


func test_player_release_stops_contact_push_and_can_reapproach() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	_press_forward()
	for index in 130:
		await physics_frame
	_release_all_actions()
	await physics_frame
	var release_z: float = lab.stone.global_position.z
	var release_distance: float = lab.player.global_position.distance_to(lab.stone.global_position)
	for index in 100:
		await physics_frame
	var unpowered_gain: float = release_z - lab.stone.global_position.z
	_expect_true(not lab.player.push_engaged, "releasing W should disengage push contact")
	_expect_true(
		unpowered_gain < lab.tuning.stone_radius * 0.58,
		"released stone should only coast briefly after input stops: %.2f" % unpowered_gain
	)

	Input.action_press("move_backward")
	for index in 45:
		await physics_frame
	Input.action_release("move_backward")
	var backed_distance: float = lab.player.global_position.distance_to(lab.stone.global_position)
	_expect_true(backed_distance > release_distance + 0.18, "pressing S after release should let the player actively back away")

	_press_forward()
	for index in 150:
		await physics_frame
	_release_all_actions()
	_expect_true(lab.player.push_engaged or lab.player.push_frame != null, "player should be able to reapproach and regain push contact")
	lab.queue_free()
	await process_frame


func test_reapproach_requires_player_to_aim_toward_stone() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	_place_player_beside_reacquire_anchor(lab)
	var start_x: float = lab.player.global_position.x
	lab.player.camera_yaw = PI * 0.5
	_press_forward()
	for index in 42:
		await physics_frame
	_release_all_actions()
	_expect_true(
		lab.player.global_position.x >= start_x - 0.08,
		"holding W while looking away should not magnet-pull the player back to the stone"
	)

	_place_player_beside_reacquire_anchor(lab)
	var start_distance: float = lab.player.global_position.distance_to(lab.stone.global_position)
	var stone_start_z: float = lab.stone.global_position.z
	lab.player.camera_yaw = -PI * 0.5
	_press_forward()
	for index in 42:
		await physics_frame
	_release_all_actions()
	var end_distance: float = lab.player.global_position.distance_to(lab.stone.global_position)
	_expect_true(
		end_distance < start_distance - 0.20 or lab.player.push_engaged or lab.stone.global_position.z < stone_start_z - 0.05,
		"aiming toward the stone should let the player approach or regain real contact without a hidden lateral pull: start %.2f end %.2f" % [start_distance, end_distance]
	)
	lab.queue_free()
	await process_frame


func test_bad_side_contact_loses_push_and_rolls_back() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	_place_stone_on_front_slope(lab, lab.tuning.front_base_z - 10.0)
	var side := Vector3.RIGHT
	lab.player.global_position = lab.stone.global_position + side * (lab.tuning.stone_radius * 1.65)
	lab.player.global_position.y = lab.mountain.height_at(lab.player.global_position.z) + 0.05
	lab.player.camera_yaw = -1.15
	_press_forward()
	var valid_contact_count: int = 0
	for index in 90:
		await physics_frame
		if lab.player.push_frame != null and lab.player.push_frame.contact_valid:
			valid_contact_count += 1
	_release_all_actions()
	var bad_contact_z: float = lab.stone.global_position.z
	for index in 150:
		await physics_frame
	var rollback_z: float = lab.stone.global_position.z - bad_contact_z
	_expect_true(valid_contact_count < 8, "side-on contact should not keep a valid push for many frames: %d" % valid_contact_count)
	_expect_true(rollback_z > 0.16, "bad side contact on the slope should let the stone roll back downhill: %.2f" % rollback_z)
	lab.queue_free()
	await process_frame


func test_camera_bias_changes_manual_push_direction() -> void:
	var straight = await _run_manual_bias(0.0)
	var right = await _run_manual_bias(0.62)
	var straight_x: float = straight["end_position"].x - straight["start_position"].x
	var right_x: float = right["end_position"].x - right["start_position"].x
	var right_uphill: float = right["start_position"].z - right["end_position"].z
	_expect_true(right_x - straight_x > 0.12, "right camera aim should visibly bias manual push direction")
	_expect_true(right_uphill > 0.35, "biased manual push should still make uphill progress")


func test_sustained_camera_bias_creates_route_pressure() -> void:
	var straight = await _run_mid_slope_bias(0.0)
	var right = await _run_mid_slope_bias(0.34)
	var straight_lateral: float = absf(straight["end_position"].x - straight["start_position"].x)
	var right_lateral: float = right["end_position"].x - right["start_position"].x
	var right_uphill: float = right["start_position"].z - right["end_position"].z
	_expect_true(
		right_lateral > straight_lateral + 0.20,
		"sustained right aim should create visible route pressure: straight %.2f right %.2f" % [straight_lateral, right_lateral]
	)
	_expect_true(
		absf(right["end_position"].x) < right["clear_path_half_width"] + 0.65,
		"sustained right aim should remain recoverable inside the first-level route: x %.2f limit %.2f" % [
			right["end_position"].x,
			right["clear_path_half_width"] + 0.65,
		]
	)
	_expect_true(
		right_uphill > 0.4,
		"moderate biased push should still make uphill progress: gain %.2f quality %.2f brace %.2f breakaway %.2f" % [
			right_uphill,
			right["average_quality"],
			right["average_brace"],
			right["average_breakaway"],
		]
	)


func test_obstacle_glance_slowdown_is_recoverable() -> void:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	var obstacle: Dictionary = _near_channel_front_obstacle(lab, 1.0)
	_expect_true(not obstacle.is_empty(), "test needs a right-side near-channel obstacle")
	if obstacle.is_empty():
		lab.queue_free()
		await process_frame
		return
	_place_stone_for_obstacle_glance(lab, obstacle)
	var start_position: Vector3 = lab.stone.global_position
	var max_air_gap: float = 0.0
	var min_speed_after_contact: float = INF
	var touched_obstacle: bool = false
	_press_forward()
	lab.player.camera_yaw += 0.62
	for index in 170:
		await physics_frame
		var air_gap: float = lab.stone.global_position.y - (lab.mountain.height_at(lab.stone.global_position.z) + lab.tuning.stone_radius)
		max_air_gap = maxf(max_air_gap, air_gap)
		var obstacle_distance: float = Vector2(
			lab.stone.global_position.x - obstacle.position.x,
			lab.stone.global_position.z - obstacle.position.z
		).length()
		if obstacle_distance <= lab.tuning.stone_radius + obstacle.radius * 0.88:
			touched_obstacle = true
		if touched_obstacle:
			min_speed_after_contact = minf(min_speed_after_contact, lab.stone.linear_velocity.length())
	_release_all_actions()
	_expect_true(touched_obstacle, "biased push should actually glance the near-channel obstacle")
	_expect_true(max_air_gap < 0.38, "obstacle glance should not launch the stone upward: %.2f" % max_air_gap)
	_expect_true(min_speed_after_contact < 2.2, "obstacle glance should slow the stone enough to read as impact")

	lab.player.camera_yaw = 0.0
	_press_forward()
	var recover_start_z: float = lab.stone.global_position.z
	for index in 220:
		await physics_frame
	_release_all_actions()
	var recovery_gain: float = recover_start_z - lab.stone.global_position.z
	_expect_true(recovery_gain > 0.22, "after glancing an obstacle, straight push should recover uphill progress")
	_expect_true(absf(lab.stone.global_position.x) < lab.tuning.path_width * 0.5, "obstacle glance should remain recoverable inside the route width")
	_expect_true(start_position.distance_to(lab.stone.global_position) > 0.4, "obstacle test should move the stone through real scene physics")
	lab.queue_free()
	await process_frame


func _run_manual_bias(yaw_offset: float) -> Dictionary:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	lab.player.camera_yaw += yaw_offset
	var start_position: Vector3 = lab.stone.global_position
	_press_forward()
	for index in 230:
		await physics_frame
	_release_all_actions()
	var end_position: Vector3 = lab.stone.global_position
	lab.queue_free()
	await process_frame
	return {
		"start_position": start_position,
		"end_position": end_position,
	}


func _near_channel_front_obstacle(lab, side_sign: float) -> Dictionary:
	var best: Dictionary = {}
	var best_inner_edge: float = INF
	for obstacle in lab.mountain.obstacles:
		if signf(obstacle.position.x) != signf(side_sign):
			continue
		if obstacle.position.z < lab.tuning.ridge_z + 4.0 or obstacle.position.z > lab.tuning.front_base_z - 4.0:
			continue
		var inner_edge: float = absf(obstacle.position.x) - obstacle.radius * 0.78
		if inner_edge < best_inner_edge:
			best = obstacle
			best_inner_edge = inner_edge
	return best


func _place_stone_for_obstacle_glance(lab, obstacle: Dictionary) -> void:
	var side_sign: float = signf(obstacle.position.x)
	var collider_radius: float = obstacle.radius * 0.78
	var z: float = obstacle.position.z + 1.15
	var x: float = obstacle.position.x - side_sign * (lab.tuning.stone_radius + collider_radius + 0.18)
	lab.stone.freeze = false
	lab.stone.sleeping = false
	lab.stone.global_position = Vector3(x, lab.mountain.height_at(z) + lab.tuning.stone_radius + 0.08, z)
	lab.stone.linear_velocity = Vector3.ZERO
	lab.stone.angular_velocity = Vector3.ZERO
	var downhill: Vector3 = lab.mountain.downhill_tangent_at(z)
	lab.player.global_position = lab.stone.global_position + downhill * lab.tuning.stone_radius * 1.55
	lab.player.global_position.y = lab.mountain.height_at(lab.player.global_position.z) + 0.05
	lab.player.camera_yaw = 0.0
	lab.player.camera_pitch = -0.06
	lab.player.push_engaged = false
	lab.player.push_frame = null
	lab.player.push_contact_seconds = 0.0


func _place_player_beside_reacquire_anchor(lab) -> void:
	var downhill: Vector3 = lab.mountain.downhill_tangent_at(lab.stone.global_position.z)
	var anchor: Vector3 = lab.stone.global_position + downhill * lab.tuning.stone_radius * 1.55
	lab.player.global_position = anchor + Vector3.RIGHT * 2.15
	lab.player.global_position.y = lab.mountain.height_at(lab.player.global_position.z) + 0.05
	lab.player.push_engaged = false
	lab.player.push_frame = null
	lab.player.push_contact_seconds = 0.0


func _run_mid_slope_bias(yaw_offset: float) -> Dictionary:
	var lab = PushLabScene.instantiate()
	root.add_child(lab)
	await _settle(lab)
	_place_stone_on_front_slope(lab, lab.tuning.front_base_z - 8.5)
	lab.player.camera_yaw += yaw_offset
	var start_position: Vector3 = lab.stone.global_position
	var quality_sum: float = 0.0
	var brace_sum: float = 0.0
	var breakaway_sum: float = 0.0
	var sample_count: int = 0
	_press_forward()
	for index in 260:
		await physics_frame
		if index >= 80 and lab.player.push_frame != null:
			quality_sum += lab.player.push_frame.contact_quality
			brace_sum += lab.player.push_brace
			breakaway_sum += lab.player.push_frame.breakaway_ratio
			sample_count += 1
	_release_all_actions()
	var end_position: Vector3 = lab.stone.global_position
	var clear_half: float = lab.tuning.clear_path_width * 0.5
	lab.queue_free()
	await process_frame
	return {
		"start_position": start_position,
		"end_position": end_position,
		"clear_path_half_width": clear_half,
		"average_quality": quality_sum / maxf(1.0, float(sample_count)),
		"average_brace": brace_sum / maxf(1.0, float(sample_count)),
		"average_breakaway": breakaway_sum / maxf(1.0, float(sample_count)),
	}


func _place_stone_on_front_slope(lab, z: float) -> void:
	lab.stone.freeze = false
	lab.stone.sleeping = false
	lab.stone.global_position = Vector3(0.0, lab.mountain.height_at(z) + lab.tuning.stone_radius + 0.08, z)
	lab.stone.linear_velocity = Vector3.ZERO
	lab.stone.angular_velocity = Vector3.ZERO
	var downhill: Vector3 = lab.mountain.downhill_tangent_at(z)
	lab.player.global_position = lab.stone.global_position + downhill * lab.tuning.stone_radius * 1.55
	lab.player.global_position.y = lab.mountain.height_at(lab.player.global_position.z) + 0.05
	lab.player.camera_yaw = 0.0
	lab.player.camera_pitch = -0.06
	lab.player.push_engaged = false
	lab.player.push_frame = null
	lab.player.push_contact_seconds = 0.0


func _settle(lab) -> void:
	_release_all_actions()
	await physics_frame
	lab.player.camera_yaw = 0.0
	lab.player.camera_pitch = -0.06
	lab.player.push_engaged = false
	lab.player.camera_push_blend = 0.0
	await physics_frame


func _press_forward() -> void:
	Input.action_press("move_forward")
	Input.action_press("push")


func _brace_sample(lab, frame_index: int, start_z: float) -> String:
	var frame = lab.player.push_frame
	var quality: float = frame.contact_quality if frame != null else 0.0
	var breakaway: float = frame.breakaway_ratio if frame != null else 0.0
	var rear: float = 0.0
	var height: float = 0.0
	var side: float = 0.0
	if frame != null and frame.contact_offset.length_squared() > 0.001:
		var surface: Vector3 = frame.contact_offset.normalized()
		var downhill: Vector3 = -frame.uphill_direction
		var route_side := Vector3(-frame.uphill_direction.z, 0.0, frame.uphill_direction.x).normalized()
		rear = surface.dot(downhill)
		height = surface.dot(frame.contact_normal)
		side = surface.dot(route_side)
	var uphill_velocity: float = lab.stone.linear_velocity.dot(lab.mountain.uphill_tangent_at(lab.stone.global_position.z))
	return "%d:g%.2f b%.2f q%.2f r%.2f v%.2f d%.2f surf(%.2f,%.2f,%.2f) e%s" % [
		frame_index,
		start_z - lab.stone.global_position.z,
		lab.player.push_brace,
		quality,
		breakaway,
		uphill_velocity,
		lab.player.global_position.distance_to(lab.stone.global_position),
		rear,
		height,
		side,
		str(lab.player.push_engaged),
	]


func _release_all_actions() -> void:
	for action in ["move_forward", "push", "move_backward", "move_left", "move_right", "turn_left", "turn_right"]:
		Input.action_release(action)


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
