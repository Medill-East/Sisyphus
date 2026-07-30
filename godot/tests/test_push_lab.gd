extends SceneTree

const TuningScript = preload("res://scripts/Tuning.gd")
const PushControllerScript = preload("res://scripts/PushController.gd")
const SNAPSHOT_PATH := "/private/tmp/sisyphus-pushlab-first-person-observation-test.png"
const SEQUENCE_BASE_PATH := "/private/tmp/sisyphus-pushlab-core-sequence-test"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	test_push_lab_scene_exists()
	test_push_lab_presets_are_distinct()
	await test_push_lab_scene_contract()
	await test_push_lab_reports_two_hand_topology()
	await test_push_lab_uses_short_skill_slope_for_core_feel()
	await test_push_lab_first_person_observation_camera()
	await test_first_person_push_view_has_embodied_torso_and_attached_arms()
	await test_first_person_palms_compress_against_pressure_point()
	await test_push_view_uses_readable_fov_and_foreground_hand_scale()
	await test_push_transition_waits_for_close_camera_before_first_person_hands()
	await test_push_transition_hides_hands_until_camera_can_reach_contact()
	await test_push_transition_hides_third_person_arms_before_first_person_takeover()
	await test_push_transition_hides_third_person_arms_immediately_after_engage()
	await test_late_push_transition_uses_short_first_person_forearms()
	await test_push_camera_follows_player_aim_direction()
	await test_push_camera_is_close_enough_for_short_first_person_hands()
	await test_normal_contact_cue_reads_as_short_pressure_hint()
	await test_first_person_hands_do_not_stretch_during_push_transition()
	await test_push_transition_does_not_show_mismatched_arm_layers()
	await test_first_person_hands_stay_outside_stone_surface()
	await test_push_mouse_look_allows_downward_contact_view()
	await test_push_contact_cue_tracks_pressure_point()
	await test_push_lab_route_markers_are_visible_for_peripheral_direction()
	await test_push_lab_pressure_markers_are_visual_only()
	await test_push_lab_ridge_markers_and_progress_are_readable()
	await test_push_view_can_read_ridge_target_in_world()
	await test_push_view_keeps_route_edges_in_peripheral_vision()
	await test_push_lab_can_save_first_person_observation_snapshot()
	await test_push_lab_obstacles_have_collision_bodies()
	if failures.is_empty():
		print("All push lab tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_push_lab_scene_exists() -> void:
	_expect_true(ResourceLoader.exists("res://scenes/PushLab.tscn"), "PushLab scene should exist as an independent feel lab")


func test_push_lab_reports_two_hand_topology() -> void:
	var lab_scene = load("res://scenes/PushLab.tscn")
	var lab = lab_scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("evaluate_two_hand_topology"), "PushLab should expose the two-hand topology diagnostic")
	if lab.has_method("evaluate_two_hand_topology"):
		var result: Dictionary = lab.call("evaluate_two_hand_topology")
		_expect_true(float(result.get("left_only_side_force", 0.0)) > 0.0, "PushLab left-only sample should point right")
		_expect_true(float(result.get("right_only_side_force", 0.0)) < 0.0, "PushLab right-only sample should point left")
		_expect_true(float(result.get("balanced_side_force", INF)) < 0.001, "PushLab balanced sample should cancel lateral force")
		_expect_true(float(result.get("camera_force_delta", INF)) < 0.0001, "PushLab camera sweep should leave force unchanged")
	lab.queue_free()
	await process_frame


func test_push_lab_presets_are_distinct() -> void:
	var tuning = TuningScript.new()
	_expect_true(tuning.has_method("push_lab_preset_names"), "Tuning should expose push lab preset names")
	_expect_true(tuning.has_method("apply_push_lab_preset"), "Tuning should apply push lab presets")
	if not tuning.has_method("push_lab_preset_names") or not tuning.has_method("apply_push_lab_preset"):
		return
	var names: Array = tuning.push_lab_preset_names()
	_expect_true(names.has("heavy"), "push lab should include a heavy preset")
	_expect_true(names.has("standard"), "push lab should include a standard preset")
	_expect_true(names.has("light"), "push lab should include a light preset")
	tuning.apply_push_lab_preset("heavy")
	var heavy_mass: float = tuning.stone_mass
	var heavy_force: float = tuning.push_force
	tuning.apply_push_lab_preset("standard")
	var standard_mass: float = tuning.stone_mass
	var standard_force: float = tuning.push_force
	tuning.apply_push_lab_preset("light")
	var light_mass: float = tuning.stone_mass
	var light_force: float = tuning.push_force
	_expect_true(heavy_mass > standard_mass and standard_mass > light_mass, "presets should step stone mass from heavy to light")
	_expect_true(heavy_force >= standard_force and standard_force >= light_force, "presets should tune force with mass instead of only renaming values")


func test_push_lab_scene_contract() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.get_node_or_null("Mountain") != null, "push lab should contain a mountain slope")
	_expect_true(lab.get_node_or_null("Stone") != null, "push lab should contain the push stone")
	_expect_true(lab.get_node_or_null("Player") != null, "push lab should contain the player")
	_expect_true(lab.get_node_or_null("Camera3D") != null, "push lab should contain its own camera")
	_expect_true(lab.get_node_or_null("HUD/Status") != null, "push lab should contain a tuning status HUD")
	_expect_true(lab.get_node_or_null("HUD/CenterReticle") != null, "push lab should give push aiming a center reference")
	_expect_true(lab.get_node_or_null("DebugForceOverlay") != null, "push lab should contain a force debug overlay toggled by F3")
	_expect_true(lab.has_method("push_motion_state"), "push lab should expose a readable push/rollback motion state")
	var hands = lab.get_node_or_null("Player/FirstPersonHands")
	_expect_true(hands != null, "push lab player should expose first-person hands for non-HUD feedback")
	if hands != null:
		_expect_true(hands.has_method("set_motion_feedback"), "first-person hands should accept push/stall/rollback feedback")
		_expect_true(hands.has_method("feedback_state"), "first-person hands should expose their current motion feedback state")
		_expect_true(hands.has_method("feedback_tint"), "first-person hands should expose visible non-HUD motion tint")
		_expect_true(hands.has_method("palm_compression"), "first-person hands should expose palm compression so pressure is visible without debug vectors")
		_expect_true(hands.get_node_or_null("Chest") != null, "first-person push view should include a torso anchor so hands do not read as floating")
		_expect_true(hands.get_node_or_null("LeftUpperArm") != null, "left first-person arm should connect from shoulder to forearm")
		_expect_true(hands.get_node_or_null("RightUpperArm") != null, "right first-person arm should connect from shoulder to forearm")
		if hands.has_method("set_motion_feedback") and hands.has_method("feedback_tint"):
			hands.set_motion_feedback("rollback", 1.0)
			var tint: Color = hands.feedback_tint()
			_expect_true(tint.r > tint.g and tint.r > tint.b, "rollback hand feedback tint should read warmer than neutral")
			hands.set_motion_feedback("weak", 1.0)
			var weak_tint: Color = hands.feedback_tint()
			_expect_true(weak_tint.r > weak_tint.b, "weak-angle hand feedback should tint visibly without debug vectors")
	var status = lab.get_node_or_null("HUD/Status")
	if status != null:
		var text: String = status.text
		_expect_true(text.contains("Preset"), "push lab HUD should show active preset")
		_expect_true(text.contains("State"), "push lab HUD should show push/stall/rollback state")
		_expect_true(text.contains("Aim"), "push lab HUD should show left/center/right aim side for polarity checks")
		_expect_true(text.contains("Angle"), "push lab HUD should show contact angle quality")
		_expect_true(text.contains("Effort"), "push lab HUD should show the labor rhythm, not only raw force")
		_expect_true(text.contains("Ridge"), "push lab HUD should show remaining distance to the ridge")
		_expect_true(text.contains("Progress"), "push lab HUD should show ascent progress so the route does not feel endless")
		_expect_true(text.contains("Uphill"), "push lab HUD should show uphill force or velocity")
		_expect_true(text.contains("Spin"), "push lab HUD should show spin-to-translation ratio")
	lab.queue_free()
	await process_frame


func test_push_lab_uses_short_skill_slope_for_core_feel() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab._reset_lab()
	var status: Dictionary = lab.route_progress_status()
	var distance_to_ridge: float = float(status.get("distance_to_ridge", 999.0))
	_expect_true(distance_to_ridge >= 12.0 and distance_to_ridge <= 22.0, "push lab should use a short readable skill slope, not a full endless route: %.2f" % distance_to_ridge)
	_expect_true(float(status.get("ascent_progress", 1.0)) < 0.12, "short slope should still begin near the foot of the climb")
	lab.queue_free()
	await process_frame


func test_push_lab_first_person_observation_camera() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("enter_first_person_push_observation"), "push lab should expose a first-person push observation setup")
	_expect_true(lab.has_method("first_person_push_camera_status"), "push lab should expose camera status for first-person verification")
	if lab.has_method("enter_first_person_push_observation") and lab.has_method("first_person_push_camera_status"):
		lab.enter_first_person_push_observation()
		await physics_frame
		var status: Dictionary = lab.first_person_push_camera_status()
		_expect_true(float(status.get("push_blend", 0.0)) >= 0.98, "first-person observation should use full push blend")
		_expect_true(bool(status.get("hands_visible", false)), "first-person observation should show hands")
		_expect_true(not bool(status.get("body_visible", true)), "first-person observation should hide the third-person body")
		_expect_true(
			float(status.get("camera_to_contact", 99.0)) > 0.40,
			"first-person observation should leave enough room for hands and contact: %.2f" % float(status.get("camera_to_contact", 99.0))
		)
		_expect_true(float(status.get("camera_to_contact", 99.0)) < 2.78, "first-person observation should remain close to hand contact")
		_expect_true(float(status.get("camera_to_stone", 99.0)) < 2.85, "first-person observation should keep the stone close enough to dominate view")
		_expect_true(status.has("left_hand_camera_x"), "first-person status should expose left hand camera-space position")
		_expect_true(status.has("right_hand_camera_x"), "first-person status should expose right hand camera-space position")
		_expect_true(status.has("contact_quality"), "first-person status should expose contact angle quality")
		_expect_true(status.has("burden_stride"), "first-person status should expose current effort stride")
		_expect_true(status.has("burden_recoil"), "first-person status should expose hand recoil during the labor trough")
		_expect_true(status.has("palm_compression"), "first-person status should expose palm compression against the boulder")
		_expect_true(float(status.get("left_hand_camera_x", 0.0)) < -0.14, "left hand should stay visibly left of screen center")
		_expect_true(float(status.get("right_hand_camera_x", 0.0)) > 0.14, "right hand should stay visibly right of screen center")
		_expect_true(float(status.get("hand_center_clearance", 0.0)) > 0.14, "hands should leave the center contact point readable")
		_expect_true(float(status.get("hand_lateral_span", 0.0)) > 0.42, "hands should frame the stone instead of stacking near center")
		_expect_true(float(status.get("nearest_hand_to_contact", 99.0)) < 0.56, "at least one palm should visibly press near the reticle contact point")
		_expect_true(status.has("forearm_center_clearance"), "first-person status should expose forearm center clearance")
		_expect_true(float(status.get("forearm_center_clearance", 0.0)) > 0.12, "forearms should stay to the sides instead of blocking the center contact point")
		_expect_true(float(status.get("forearm_lateral_span", 0.0)) > 0.36, "forearms should read as two separate arms around the stone")
		var palm_width: float = float(status.get("hand_radius", 0.0)) * maxf(float(status.get("left_hand_scale_x", 1.0)), float(status.get("right_hand_scale_x", 1.0)))
		_expect_true(palm_width >= float(status.get("forearm_radius", 1.0)) * 1.65, "flattened palms should be visibly broader than forearms")
	lab.queue_free()
	await process_frame


func test_first_person_push_view_has_embodied_torso_and_attached_arms() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.DOWN * 0.12)
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(bool(status.get("torso_visible", false)), "close push view should show a torso/shoulder anchor, not only floating palms")
	_expect_true(float(status.get("torso_camera_y", 99.0)) < -0.18, "torso anchor should sit at the bottom of the view like a body, not in the reticle")
	_expect_true(float(status.get("upper_arm_lateral_span", 0.0)) > 0.62, "upper arms should visibly connect shoulders to forearms")
	_expect_true(float(status.get("upper_arm_center_clearance", 0.0)) > 0.18, "upper arms should stay off the reticle instead of merging into one central tube")
	_expect_true(float(status.get("forearm_lateral_span", 0.0)) >= 0.46, "forearms should read as two attached arms bracing the stone")
	lab.queue_free()
	await process_frame


func test_first_person_palms_compress_against_pressure_point() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_approach_observation()
	var approach_status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(
		float(approach_status.get("palm_compression", 1.0)) <= 0.02,
		"approach view should not show compressed floating palms before contact"
	)
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.84 + Vector3.UP * 0.24)
	var push_status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(
		float(push_status.get("palm_compression", 0.0)) >= 0.08,
		"active push should visibly squash palms into the selected pressure point"
	)
	_expect_true(
		float(push_status.get("left_hand_scale_x", 0.0)) > float(push_status.get("left_hand_scale_y", 99.0)) * 1.45,
		"left first-person hand should read as a flattened palm, not a round floating ball"
	)
	_expect_true(
		float(push_status.get("right_hand_scale_x", 0.0)) > float(push_status.get("right_hand_scale_y", 99.0)) * 1.45,
		"right first-person hand should read as a flattened palm, not a round floating ball"
	)
	_expect_true(
		float(push_status.get("left_hand_scale_x", 0.0)) > 1.16 and float(push_status.get("right_hand_scale_x", 0.0)) > 1.16,
		"compressed palms should broaden laterally when bearing weight"
	)
	_expect_true(
		float(push_status.get("left_hand_scale_y", 1.0)) < 0.74 and float(push_status.get("right_hand_scale_y", 1.0)) < 0.74,
		"compressed palms should flatten vertically when bearing weight"
	)
	lab.queue_free()
	await process_frame


func test_push_camera_uses_refined_reticle_solve_for_live_contact() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	var aim_bias := Vector3.LEFT * 0.96 + Vector3.UP * 0.32
	lab.enter_first_person_push_observation(aim_bias)
	var uphill: Vector3 = lab.mountain.uphill_tangent_at(lab.stone.global_position.z)
	var camera_direction: Vector3 = (uphill + aim_bias).normalized()
	var refined_frame = lab.player.calculate_reticle_aligned_push_frame(camera_direction, true, aim_bias.x, 999.0)
	_expect_true(refined_frame != null and refined_frame.contact_valid, "refined reticle push solve should produce a valid contact frame")
	if refined_frame != null:
		var visual_origin: Vector3 = lab.player.push_camera_origin_for(
			camera_direction,
			refined_frame.camera_contact_point,
			lab.stone.global_position,
			1.0
		)
		var visual_frame = PushControllerScript.calculate_push_frame(
			lab.stone.global_position,
			lab.player.global_position,
			camera_direction,
			true,
			aim_bias.x,
			lab.tuning,
			lab.mountain,
			999.0,
			visual_origin
		)
		_expect_true(
			visual_frame.camera_contact_point.distance_to(refined_frame.camera_contact_point) < 0.08,
			"live push contact should be stable when re-solved from the actual push camera origin"
		)
	lab.queue_free()
	await process_frame


func test_push_view_uses_readable_fov_and_foreground_hand_scale() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.RIGHT * 0.84 + Vector3.DOWN * 0.22)
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(
		float(status.get("camera_fov", 999.0)) <= 112.0,
		"push FOV should be wide but not fisheye, so direction judgment remains readable"
	)
	_expect_true(
		float(status.get("camera_to_contact", 99.0)) <= 1.52,
		"push camera should sit close enough to read the selected hand pressure point as first-person contact"
	)
	_expect_true(
		float(status.get("hand_radius", 0.0)) >= 0.16,
		"first-person palms should be large enough to read as foreground hands"
	)
	_expect_true(
		float(status.get("forearm_radius", 0.0)) >= 0.06,
		"first-person forearms should be visible cuffs, not hairline rods"
	)
	_expect_true(
		float(status.get("hand_radius", 0.0)) * maxf(float(status.get("left_hand_scale_x", 1.0)), float(status.get("right_hand_scale_x", 1.0))) >= float(status.get("forearm_radius", 1.0)) * 1.65,
		"flattened palms should remain clearly broader than forearms"
	)
	lab.queue_free()
	await process_frame


func test_push_transition_waits_for_close_camera_before_first_person_hands() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 1.05 + Vector3.UP * 0.35)
	lab.player.camera_push_blend = 0.18
	lab.player.update_push_visual_mode()
	lab.player._update_first_person_hands((lab.mountain.uphill_tangent_at(lab.stone.global_position.z) + Vector3.LEFT * 1.05 + Vector3.UP * 0.35).normalized())
	var body = lab.player.get_node_or_null("Body")
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(body != null and body.visible, "early push-camera transition should keep the third-person body until the camera is close")
	_expect_true(hands != null and not hands.visible, "first-person hands should wait until the camera is close enough to avoid stretched forearms")
	lab.queue_free()
	await process_frame


func test_push_transition_hides_hands_until_camera_can_reach_contact() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.95 + Vector3.UP * 0.30)
	var uphill: Vector3 = lab.mountain.uphill_tangent_at(lab.stone.global_position.z)
	var forward := Vector3(uphill.x, 0.0, uphill.z).normalized()
	var right := Vector3(-forward.z, 0.0, forward.x).normalized()
	lab.camera.global_position = lab.player.global_position - forward * lab.tuning.shoulder_distance + right * lab.tuning.shoulder_side_offset + Vector3.UP * lab.tuning.shoulder_height
	lab.camera.look_at(lab.stone.global_position + Vector3.UP * 0.60, Vector3.UP)
	lab.player.camera_push_blend = 0.48
	lab.player.update_push_visual_mode()
	lab.player._update_first_person_hands((uphill + Vector3.LEFT * 0.95 + Vector3.UP * 0.30).normalized())
	var body = lab.player.get_node_or_null("Body")
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(body != null and body.visible, "body should remain visible while the camera is still too far for first-person hands")
	_expect_true(hands != null and not hands.visible, "first-person hands should not appear from a far camera and create long transition arms")
	lab.queue_free()
	await process_frame


func test_push_transition_hides_third_person_arms_before_first_person_takeover() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.9 + Vector3.UP * 0.28)
	var uphill: Vector3 = lab.mountain.uphill_tangent_at(lab.stone.global_position.z)
	var forward := Vector3(uphill.x, 0.0, uphill.z).normalized()
	var right := Vector3(-forward.z, 0.0, forward.x).normalized()
	lab.camera.global_position = lab.player.global_position - forward * lab.tuning.shoulder_distance + right * lab.tuning.shoulder_side_offset + Vector3.UP * lab.tuning.shoulder_height
	lab.camera.look_at(lab.stone.global_position + Vector3.UP * 0.60, Vector3.UP)
	lab.player.camera_push_blend = 0.30
	lab.player.update_push_visual_mode()
	lab.player._update_first_person_hands((uphill + Vector3.LEFT * 0.9 + Vector3.UP * 0.28).normalized())
	var body = lab.player.get_node_or_null("Body")
	var left_arm = lab.player.get_node_or_null("Body/LeftArm")
	var right_arm = lab.player.get_node_or_null("Body/RightArm")
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(body != null and body.visible, "mid push-camera transition should keep the body as the spatial reference")
	_expect_true(left_arm != null and left_arm.visible, "mid push-camera transition should keep connected body arms until first-person hands take over")
	_expect_true(right_arm != null and right_arm.visible, "mid push-camera transition should keep connected body arms until first-person hands take over")
	_expect_true(hands != null and not hands.visible, "first-person hands should still wait until the camera can physically reach the contact point")
	lab.queue_free()
	await process_frame


func test_push_transition_hides_third_person_arms_immediately_after_engage() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.9 + Vector3.UP * 0.24)
	lab.player.camera_push_blend = 0.06
	lab.player.update_push_visual_mode()
	var body = lab.player.get_node_or_null("Body")
	var left_arm = lab.player.get_node_or_null("Body/LeftArm")
	var right_arm = lab.player.get_node_or_null("Body/RightArm")
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(body != null and body.visible, "early push transition should keep torso as body reference")
	_expect_true(left_arm != null and left_arm.visible, "left connected arm should remain visible during early reach-in")
	_expect_true(right_arm != null and right_arm.visible, "right connected arm should remain visible during early reach-in")
	_expect_true(hands != null and not hands.visible, "first-person hands should still wait until the camera can physically reach the contact point")
	lab.queue_free()
	await process_frame


func test_late_push_transition_uses_short_first_person_forearms() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	var aim_bias := Vector3.LEFT * 0.98 + Vector3.UP * 0.30
	lab.enter_first_person_push_observation(aim_bias)
	var aim_direction: Vector3 = (lab.mountain.uphill_tangent_at(lab.stone.global_position.z) + aim_bias).normalized()
	lab.player.camera_push_blend = 0.96
	lab._position_lab_camera(aim_direction, lab.player.push_frame.camera_contact_point, lab.player.camera_push_blend)
	lab.player.update_push_visual_mode()
	lab.player._update_first_person_hands(aim_direction)
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(hands != null, "late push transition should have a first-person hand rig")
	if hands != null:
		_expect_true(hands.visible, "late push transition should show first-person hands instead of a no-hands gap")
		var max_visual_length: float = lab.tuning.first_person_forearm_max_length + 0.04
		_expect_true(
			_forearm_visual_length(hands, "LeftForearm") <= max_visual_length,
			"left first-person forearm should stay short during the third-person to first-person blend"
		)
		_expect_true(
			_forearm_visual_length(hands, "RightForearm") <= max_visual_length,
			"right first-person forearm should stay short during the third-person to first-person blend"
		)
	lab.queue_free()
	await process_frame


func test_push_camera_follows_player_aim_direction() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	var aim_bias := Vector3.LEFT * 0.85 + Vector3.DOWN * 0.42
	lab.enter_first_person_push_observation(aim_bias)
	var camera_forward: Vector3 = -lab.camera.global_transform.basis.z.normalized()
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(float(status.get("contact_camera_x_ratio", 99.0)) < 0.16, "push camera should center the reticle on the selected pressure point")
	_expect_true(camera_forward.y < -0.12, "push camera should allow a readable downward hand/contact view")
	lab.queue_free()
	await process_frame


func test_biased_downward_push_keeps_stone_and_contact_readable() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.85 + Vector3.DOWN * 0.42)
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(float(status.get("stone_camera_x_ratio", 99.0)) < 0.72, "biased/downward push view should keep the stone readable in peripheral vision")
	_expect_true(float(status.get("contact_camera_x_ratio", 99.0)) < 0.46, "biased/downward contact should remain close enough to the reticle to aim deliberately")
	_expect_true(float(status.get("camera_to_stone", 99.0)) > 1.65, "biased/downward camera should not enter the stone")
	_expect_true(float(status.get("camera_to_stone", 0.0)) < 2.75, "biased/downward camera should remain close enough for burden")
	lab.queue_free()
	await process_frame


func test_downward_aim_places_pressure_on_lower_stone_surface() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.DOWN * 1.18)
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(status.has("contact_height_offset"), "push view status should expose contact height for low-look verification")
	_expect_true(
		float(status.get("contact_height_offset", 99.0)) < -0.10,
		"looking down should move the pressure point onto the lower half of the stone"
	)
	_expect_true(
		float(status.get("contact_camera_x_ratio", 99.0)) < 0.22,
		"looking down should keep the pressure point near the screen center"
	)
	_expect_true(
		float(status.get("nearest_hand_to_contact", 99.0)) < 0.50,
		"looking down should still show a palm close to the chosen lower pressure point"
	)
	lab.queue_free()
	await process_frame


func test_left_right_aim_offsets_stone_around_reticle() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 1.02 + Vector3.UP * 0.26)
	var left_status: Dictionary = lab.first_person_push_camera_status()
	lab.enter_first_person_push_observation(Vector3.RIGHT * 1.02 + Vector3.UP * 0.26)
	var right_status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(
		float(left_status.get("stone_camera_x", 0.0)) > 0.12,
		"left reticle aim should leave the stone center visibly to the right of the contact reference"
	)
	_expect_true(
		float(right_status.get("stone_camera_x", 0.0)) < -0.12,
		"right reticle aim should leave the stone center visibly to the left of the contact reference"
	)
	_expect_true(
		float(right_status.get("stone_camera_x", 0.0)) - float(left_status.get("stone_camera_x", 0.0)) < -0.34,
		"left/right aim should visibly swing the stone around the reticle, not render as the same centered picture"
	)
	_expect_true(
		float(left_status.get("stone_camera_x_ratio", 99.0)) < 0.70 and float(right_status.get("stone_camera_x_ratio", 99.0)) < 0.70,
		"left/right aim should not throw the stone so far aside that the push direction feels inverted"
	)
	lab.queue_free()
	await process_frame


func test_biased_push_keeps_pressure_point_under_reticle() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.95 + Vector3.UP * 0.18)
	var left_status: Dictionary = lab.first_person_push_camera_status()
	lab.enter_first_person_push_observation(Vector3.RIGHT * 0.95 + Vector3.UP * 0.18)
	var right_status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(float(left_status.get("contact_camera_x_ratio", 99.0)) < 0.16, "left-biased push pressure point should stay under the reticle")
	_expect_true(float(right_status.get("contact_camera_x_ratio", 99.0)) < 0.16, "right-biased push pressure point should stay under the reticle")
	_expect_true(float(left_status.get("contact_cue_camera_x_ratio", 99.0)) < 0.18, "left-biased contact cue should read as the reticle pressure point")
	_expect_true(float(right_status.get("contact_cue_camera_x_ratio", 99.0)) < 0.18, "right-biased contact cue should read as the reticle pressure point")
	_expect_true(float(left_status.get("contact_side_offset", 0.0)) < -0.24, "left reticle aim should still choose the left stone surface")
	_expect_true(float(right_status.get("contact_side_offset", 0.0)) > 0.24, "right reticle aim should still choose the right stone surface")
	lab.queue_free()
	await process_frame


func test_push_camera_is_close_enough_for_short_first_person_hands() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.65 + Vector3.DOWN * 0.36)
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(float(status.get("camera_to_contact", 99.0)) < 1.82, "push camera should sit close enough that first-person arms do not need to stretch")
	_expect_true(float(status.get("camera_to_contact", 0.0)) > 0.40, "push camera should leave enough space to read the hands and pressure cue")
	_expect_true(float(status.get("nearest_hand_to_contact", 99.0)) < 0.56, "short first-person hands should still visually press near the selected pressure point")
	_expect_true(int(status.get("visible_left_route_markers", 0)) >= 1, "closer push camera should still preserve left peripheral route markers")
	_expect_true(int(status.get("visible_right_route_markers", 0)) >= 1, "closer push camera should still preserve right peripheral route markers")
	lab.queue_free()
	await process_frame


func test_normal_contact_cue_reads_as_short_pressure_hint() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.84 + Vector3.UP * 0.26)
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(bool(status.get("contact_cue_visible", false)), "push view should show a contact pressure cue")
	_expect_true(str(status.get("contact_cue_visual_style", "")) == "pressure_patch", "contact cue should read as a natural pressure patch, not a debug vector")
	_expect_true(not bool(status.get("contact_cue_debug_vector", true)), "normal push view should not expose the contact cue as a debug vector")
	_expect_true(
		float(status.get("contact_cue_force_length", 99.0)) <= 0.22,
		"normal contact cue should be a short surface smear, not a long vector that reads like a stray arm"
	)
	lab.queue_free()
	await process_frame


func test_contact_cue_exposes_pressure_quality_without_debug_colors() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.ZERO)
	var sweet_status: Dictionary = lab.first_person_push_camera_status()
	lab.enter_first_person_push_observation(Vector3.RIGHT * 0.92 + Vector3.UP * 0.92)
	var weak_status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(
		float(sweet_status.get("contact_cue_quality_signal", 0.0)) > float(weak_status.get("contact_cue_quality_signal", 1.0)) + 0.24,
		"pressure cue should visibly distinguish a usable pressure point from a weak high/side point"
	)
	_expect_true(
		float(sweet_status.get("contact_cue_patch_scale", 0.0)) > float(weak_status.get("contact_cue_patch_scale", 99.0)) + 0.12,
		"good pressure should leave a broader grounded patch than weak pressure"
	)
	_expect_true(float(sweet_status.get("contact_cue_saturation_hint", 1.0)) < 0.22, "good pressure cue should stay muted, not debug-colored")
	_expect_true(float(weak_status.get("contact_cue_saturation_hint", 1.0)) < 0.22, "weak pressure cue should stay muted, not debug-colored")
	lab.queue_free()
	await process_frame


func test_sustained_biased_push_keeps_stone_in_view() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	for index in 120:
		lab._drive_lab_push(Vector3.LEFT * 0.9, true, 1.0 / 60.0)
		await physics_frame
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(float(status.get("stone_camera_x_ratio", 99.0)) < 0.76, "sustained biased push should not lose the stone from peripheral view")
	_expect_true(float(status.get("contact_camera_x_ratio", 99.0)) < 0.58, "sustained biased push should keep the pressure point aimable")
	_expect_true(float(status.get("camera_to_stone", 99.0)) < 2.85, "sustained biased push should keep a close burden camera")
	lab.queue_free()
	await process_frame


func test_first_person_hands_do_not_stretch_during_push_transition() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.9 + Vector3.UP * 0.25)
	lab.player.camera_push_blend = 0.45
	lab.player.update_push_visual_mode()
	lab.player._update_first_person_hands((lab.mountain.uphill_tangent_at(lab.stone.global_position.z) + Vector3.LEFT * 0.9 + Vector3.UP * 0.25).normalized())
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(hands != null, "push transition should have a first-person hand rig")
	if hands != null:
		if hands.visible:
			var max_visual_length: float = lab.tuning.first_person_forearm_max_length + 0.04
			_expect_true(_forearm_visual_length(hands, "LeftForearm") <= max_visual_length, "left first-person forearm should not stretch during camera blend")
			_expect_true(_forearm_visual_length(hands, "RightForearm") <= max_visual_length, "right first-person forearm should not stretch during camera blend")
	lab.queue_free()
	await process_frame


func test_push_transition_does_not_show_mismatched_arm_layers() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.75 + Vector3.UP * 0.18)
	lab.player.camera_push_blend = 0.45
	lab.player.update_push_visual_mode()
	var body_arm = lab.player.get_node_or_null("Body/LeftArm")
	var body = lab.player.get_node_or_null("Body")
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(body != null and body.visible, "mid push transition should keep the torso as the spatial reference until first-person hands can stay short")
	_expect_true(body_arm != null and body_arm.visible, "third-person arms should stay connected during the reach-in transition")
	_expect_true(hands != null and not hands.visible, "first-person hands should wait until the camera is close enough for bounded forearms")
	lab.queue_free()
	await process_frame


func test_first_person_hands_stay_outside_stone_surface() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.RIGHT * 0.9 + Vector3.UP * 0.35)
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(hands != null, "push observation should have first-person hands")
	if hands != null:
		var hand_radius: float = _hand_visual_radius(hands, "LeftHand")
		var minimum_center_distance: float = lab.tuning.stone_radius + hand_radius * 0.92
		var left_hand: Node3D = hands.get_node_or_null("LeftHand")
		var right_hand: Node3D = hands.get_node_or_null("RightHand")
		_expect_true(left_hand.global_position.distance_to(lab.stone.global_position) >= minimum_center_distance, "left palm center should stay outside the stone surface")
		_expect_true(right_hand.global_position.distance_to(lab.stone.global_position) >= minimum_center_distance, "right palm center should stay outside the stone surface")
	lab.enter_first_person_push_observation(Vector3.LEFT * 1.05 + Vector3.UP * 0.42)
	await physics_frame
	if hands != null:
		var hand_radius_left: float = _hand_visual_radius(hands, "LeftHand")
		var minimum_left_distance: float = lab.tuning.stone_radius + hand_radius_left * 0.92
		var left_hand_high: Node3D = hands.get_node_or_null("LeftHand")
		var right_hand_high: Node3D = hands.get_node_or_null("RightHand")
		_expect_true(left_hand_high.global_position.distance_to(lab.stone.global_position) >= minimum_left_distance, "left/high aim should not sink the left palm into the stone")
		_expect_true(right_hand_high.global_position.distance_to(lab.stone.global_position) >= minimum_left_distance, "left/high aim should not sink the right palm into the stone")
	lab.queue_free()
	await process_frame


func test_first_person_forearms_do_not_cut_through_stone_on_high_corner_push() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 1.08 + Vector3.UP * 0.46)
	var hands = lab.player.get_node_or_null("FirstPersonHands")
	_expect_true(hands != null, "high-corner push should have first-person hands")
	if hands != null:
		var left_clearance: float = _forearm_segment_clearance_to_stone(hands, "LeftForearm", lab.stone.global_position)
		var right_clearance: float = _forearm_segment_clearance_to_stone(hands, "RightForearm", lab.stone.global_position)
		var forearm_radius: float = _forearm_visual_radius(hands, "LeftForearm")
		var minimum_clearance: float = lab.tuning.stone_radius + forearm_radius * 0.45
		_expect_true(left_clearance >= minimum_clearance, "left forearm should not cut through the stone on high-left aim")
		_expect_true(right_clearance >= minimum_clearance, "right forearm should not cut through the stone on high-left aim")
	lab.queue_free()
	await process_frame


func test_push_mouse_look_allows_downward_contact_view() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation()
	_expect_true(lab.player.has_method("apply_look_delta"), "player should expose mouse/trackpad look logic for push-view tests")
	if lab.player.has_method("apply_look_delta"):
		lab.player.camera_pitch = -0.06
		lab.player.apply_look_delta(Vector2(0.0, 280.0))
	_expect_true(lab.player.camera_pitch <= -0.52, "push camera should allow the player to look down at hands/contact")
	lab.queue_free()
	await process_frame


func test_push_mouse_look_keeps_left_right_aim_authority() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation()
	_expect_true(lab.player.has_method("apply_look_delta"), "player should expose mouse/trackpad look logic for side-bias tests")
	if lab.player.has_method("apply_look_delta"):
		var start_yaw: float = lab.player.camera_yaw
		lab.player.apply_look_delta(Vector2(260.0, 0.0))
		_expect_true(
			absf(lab.player.camera_yaw - start_yaw) > 0.45,
			"push camera should allow enough left/right aim motion to choose a pressure point"
		)
		lab.player.camera_pitch = -0.06
		lab.player.apply_look_delta(Vector2(0.0, 330.0))
		_expect_true(
			lab.player.camera_pitch <= -0.72,
			"push camera should allow a real look-down inspection of hands and contact"
		)
	lab.queue_free()
	await process_frame


func test_push_contact_cue_tracks_pressure_point() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.RIGHT * 0.42 + Vector3.UP * 0.12)
	await physics_frame
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(bool(status.get("contact_cue_visible", false)), "push view should show a world-space contact cue")
	_expect_true(float(status.get("contact_cue_to_contact", 99.0)) < 0.14, "contact cue should sit on the current pressure point")
	_expect_true(float(status.get("contact_cue_camera_x_ratio", 99.0)) < 0.48, "contact cue should remain near enough to aim deliberately")
	_expect_true(float(status.get("contact_cue_force_length", 0.0)) > 0.06, "subtle contact cue should still expose force direction, not only a dot")
	_expect_true(str(status.get("contact_cue_visual_style", "")) == "pressure_patch", "contact cue should expose a pressure-patch style for visual QA")
	lab.enter_approach_observation()
	await physics_frame
	status = lab.first_person_push_camera_status()
	_expect_true(not bool(status.get("contact_cue_visible", true)), "contact cue should hide outside active push")
	lab.queue_free()
	await process_frame


func test_push_lab_route_markers_are_visible_for_peripheral_direction() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	var marker_root = lab.get_node_or_null("Mountain/RouteEdgeMarkers")
	_expect_true(marker_root != null, "push lab mountain should expose visible route edge markers")
	if marker_root != null:
		_expect_true(marker_root.get_child_count() >= 10, "route edge markers should repeat along the slope")
		var left_seen: bool = false
		var right_seen: bool = false
		for child in marker_root.get_children():
			if child is MeshInstance3D:
				left_seen = left_seen or child.position.x < 0.0
				right_seen = right_seen or child.position.x > 0.0
				_expect_true(not (child is CollisionObject3D), "route edge marker visuals should not add hidden blockers")
		_expect_true(left_seen and right_seen, "route edge markers should frame both sides for peripheral direction judgment")
	lab.queue_free()
	await process_frame


func test_push_lab_pressure_markers_are_visual_only() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	var marker_root = lab.get_node_or_null("Mountain/RoutePressureMarkers")
	_expect_true(marker_root != null, "push lab mountain should expose natural pressure-band markers")
	if marker_root != null:
		_expect_true(marker_root.get_child_count() >= 6, "pressure markers should repeat enough to read route camber")
		var left_seen: bool = false
		var right_seen: bool = false
		for child in marker_root.get_children():
			if child is MeshInstance3D:
				left_seen = left_seen or child.position.x < 0.0
				right_seen = right_seen or child.position.x > 0.0
				_expect_true(not (child is CollisionObject3D), "pressure marker visuals should not add hidden blockers")
		_expect_true(left_seen and right_seen, "pressure markers should alternate sides instead of implying one constant slope")
	lab.queue_free()
	await process_frame


func test_push_lab_ridge_markers_and_progress_are_readable() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	var ridge_markers = lab.get_node_or_null("Mountain/RidgeGateMarkers")
	_expect_true(ridge_markers != null, "push lab should mark the ridge as the visible end of the climb")
	if ridge_markers != null:
		_expect_true(ridge_markers.get_child_count() >= 3, "ridge marker should include side posts and a crest line")
		for child in ridge_markers.get_children():
			_expect_true(child is MeshInstance3D, "ridge markers should be visual meshes only")
			_expect_true(not (child is CollisionObject3D), "ridge markers should not add hidden blockers")
	_expect_true(lab.has_method("route_progress_status"), "push lab should expose route progress status")
	if lab.has_method("route_progress_status"):
		lab._reset_lab()
		var front_status: Dictionary = lab.route_progress_status()
		_expect_true(float(front_status.get("distance_to_ridge", 0.0)) > 20.0, "front start should show real remaining climb distance")
		_expect_true(float(front_status.get("ascent_progress", 1.0)) < 0.10, "front start should not look like route completion")
		lab.stone.global_position.z = lab.tuning.ridge_z + 1.2
		var ridge_status: Dictionary = lab.route_progress_status()
		_expect_true(float(ridge_status.get("distance_to_ridge", 99.0)) <= 1.3, "near ridge should report short remaining distance")
		_expect_true(float(ridge_status.get("ascent_progress", 0.0)) > 0.92, "near ridge should show the climb is almost done")
	var status = lab.get_node_or_null("HUD/Status")
	var controls = lab.get_node_or_null("HUD/Controls")
	_expect_true(status != null and status.text.contains("Ridge") and status.text.contains("Progress"), "HUD should surface ridge/progress while testing")
	_expect_true(controls != null and controls.text.contains("Ridge posts"), "controls should explain ridge posts are route markers, not debug vectors")
	lab.queue_free()
	await process_frame


func test_push_view_can_read_ridge_target_in_world() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.DOWN * 0.10)
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(int(status.get("visible_ridge_markers", 0)) >= 2, "push view should keep the ridge target readable as world geometry")
	_expect_true(float(status.get("ridge_marker_camera_x_ratio", 99.0)) < 0.92, "ridge target should sit within peripheral view, not outside the frame")
	var ridge_markers = lab.get_node_or_null("Mountain/RidgeGateMarkers")
	if ridge_markers != null:
		var tall_posts: int = 0
		for child in ridge_markers.get_children():
			if child is MeshInstance3D and child.has_meta("read_height"):
				if float(child.get_meta("read_height", 0.0)) >= 1.75:
					tall_posts += 1
		_expect_true(tall_posts >= 2, "ridge posts should be tall enough to read over the stone in push view")
	lab.queue_free()
	await process_frame


func test_push_view_keeps_route_edges_in_peripheral_vision() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	lab.enter_first_person_push_observation(Vector3.LEFT * 0.72 + Vector3.DOWN * 0.32)
	var status: Dictionary = lab.first_person_push_camera_status()
	_expect_true(status.has("visible_left_route_markers"), "push view status should expose visible left route markers")
	_expect_true(status.has("visible_right_route_markers"), "push view status should expose visible right route markers")
	_expect_true(int(status.get("visible_left_route_markers", 0)) >= 1, "left route edge should remain readable in push-view peripheral vision")
	_expect_true(int(status.get("visible_right_route_markers", 0)) >= 1, "right route edge should remain readable in push-view peripheral vision")
	_expect_true(float(status.get("route_edge_camera_x_ratio", 99.0)) < 1.15, "route edges should sit inside the widened push-view periphery")
	lab.queue_free()
	await process_frame


func test_push_lab_can_save_first_person_observation_snapshot() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("save_observation_snapshot"), "push lab should save its own viewport observation snapshot")
	if lab.has_method("save_observation_snapshot"):
		lab.enter_first_person_push_observation()
		for index in 3:
			await process_frame
		var evidence: Dictionary = lab.save_observation_snapshot(SNAPSHOT_PATH)
		_expect_true(int(evidence.get("error", ERR_UNAVAILABLE)) == OK, "push lab observation snapshot should save without error")
		_expect_true(FileAccess.file_exists(SNAPSHOT_PATH), "push lab observation snapshot PNG should be written")
		if FileAccess.file_exists(SNAPSHOT_PATH):
			var image := Image.load_from_file(SNAPSHOT_PATH)
			_expect_true(image != null and image.get_width() >= 320 and image.get_height() >= 180, "push lab observation snapshot should be a readable image")
		_expect_true(str(evidence.get("path", "")) == SNAPSHOT_PATH, "snapshot evidence should report saved path")
		_expect_true(float(evidence.get("hand_center_clearance", 0.0)) > 0.14, "snapshot evidence should include first-person hand layout metrics")
		_expect_true(bool(evidence.get("hands_visible", false)), "snapshot evidence should record visible first-person hands")
		_expect_true(not bool(evidence.get("body_visible", true)), "snapshot evidence should record hidden third-person body")
	lab.queue_free()
	await process_frame


func test_push_lab_can_save_core_evidence_sequence() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("save_core_evidence_sequence"), "push lab should save approach/push/bias/release evidence sequence")
	if lab.has_method("save_core_evidence_sequence"):
		var sequence: Array = await lab.save_core_evidence_sequence(SEQUENCE_BASE_PATH)
		_expect_true(sequence.size() == 5, "core evidence sequence should contain approach, push, left, right, and rollback snapshots")
		var by_label: Dictionary = {}
		for entry in sequence:
			var label: String = str(entry.get("label", ""))
			by_label[label] = entry
			var path: String = str(entry.get("path", ""))
			_expect_true(FileAccess.file_exists(path), "sequence snapshot should exist for %s" % label)
			if FileAccess.file_exists(path):
				var image := Image.load_from_file(path)
				_expect_true(image != null and image.get_width() >= 320 and image.get_height() >= 180, "sequence snapshot image should be readable for %s" % label)
		_expect_true(by_label.has("approach"), "sequence should include approach snapshot")
		_expect_true(by_label.has("push"), "sequence should include normal push snapshot")
		_expect_true(by_label.has("left_bias"), "sequence should include left-biased push snapshot")
		_expect_true(by_label.has("right_bias"), "sequence should include right-biased push snapshot")
		_expect_true(by_label.has("release_rollback"), "sequence should include release/rollback snapshot")
		if by_label.has("approach"):
			_expect_true(not bool(by_label["approach"].get("hands_visible", true)), "approach snapshot should not show first-person hands")
			_expect_true(bool(by_label["approach"].get("body_visible", false)), "approach snapshot should keep the third-person body visible")
		if by_label.has("push"):
			_expect_true(str(by_label["push"].get("motion_state", "")) == "push", "push snapshot should record active push state")
			_expect_true(bool(by_label["push"].get("contact_valid", false)), "push snapshot should record valid contact")
		if by_label.has("left_bias"):
			_expect_true(str(by_label["left_bias"].get("motion_state", "")) == "push", "left-biased snapshot should still be an active push")
			_expect_true(float(by_label["left_bias"].get("left_hand_camera_x", 0.0)) < -0.14, "left-biased snapshot should preserve readable left hand framing")
			_expect_true(float(by_label["left_bias"].get("nearest_hand_to_contact", 99.0)) < 0.56, "left-biased snapshot should show a palm pressing close to the contact cue")
			_expect_true(by_label["left_bias"].has("stone_camera_x_ratio"), "left-biased snapshot should expose stone camera readability ratio")
			_expect_true(by_label["left_bias"].has("contact_camera_x_ratio"), "left-biased snapshot should expose contact camera readability ratio")
			_expect_true(float(by_label["left_bias"].get("stone_camera_x_ratio", 99.0)) < 0.72, "left-biased snapshot should not push the stone center too far out of view")
			_expect_true(float(by_label["left_bias"].get("contact_camera_x_ratio", 99.0)) < 0.46, "left-biased contact should remain near enough to the camera center to aim deliberately")
			_expect_true(float(by_label["left_bias"].get("camera_to_stone", 0.0)) > 1.45, "left-biased snapshot should stay outside the stone while keeping it readable")
			_expect_true(float(by_label["left_bias"].get("contact_side_offset", 0.0)) < -0.18, "left-biased contact should move to the left side of the stone")
			_expect_true(float(by_label["left_bias"].get("force_side_component", 0.0)) < -8.0, "left-biased force should push leftward, not only move the hands")
		if by_label.has("right_bias"):
			_expect_true(str(by_label["right_bias"].get("motion_state", "")) == "push", "right-biased snapshot should still be an active push")
			_expect_true(float(by_label["right_bias"].get("right_hand_camera_x", 0.0)) > 0.14, "right-biased snapshot should preserve readable right hand framing")
			_expect_true(float(by_label["right_bias"].get("nearest_hand_to_contact", 99.0)) < 0.56, "right-biased snapshot should show a palm pressing close to the contact cue")
			_expect_true(float(by_label["right_bias"].get("stone_camera_x_ratio", 99.0)) < 0.72, "right-biased snapshot should not push the stone center too far out of view")
			_expect_true(float(by_label["right_bias"].get("contact_camera_x_ratio", 99.0)) < 0.46, "right-biased contact should remain near enough to the camera center to aim deliberately")
			_expect_true(float(by_label["right_bias"].get("camera_to_stone", 0.0)) > 1.45, "right-biased snapshot should stay outside the stone while keeping it readable")
			_expect_true(float(by_label["right_bias"].get("contact_side_offset", 0.0)) > 0.18, "right-biased contact should move to the right side of the stone")
			_expect_true(float(by_label["right_bias"].get("force_side_component", 0.0)) > 8.0, "right-biased force should push rightward, not only move the hands")
		if by_label.has("left_bias") and by_label.has("right_bias"):
			var contact_delta: float = float(by_label["right_bias"].get("contact_side_offset", 0.0)) - float(by_label["left_bias"].get("contact_side_offset", 0.0))
			var force_delta: float = float(by_label["right_bias"].get("force_side_component", 0.0)) - float(by_label["left_bias"].get("force_side_component", 0.0))
			_expect_true(contact_delta > 0.55, "left/right aim should visibly move hand contact across the stone")
			_expect_true(force_delta > 18.0, "left/right aim should produce opposite playable side force")
			var visual_delta: float = _snapshot_visual_delta(
				str(by_label["left_bias"].get("path", "")),
				str(by_label["right_bias"].get("path", ""))
			)
			_expect_true(visual_delta > 0.022, "left/right evidence snapshots should be visually distinguishable, not only numerically different: %.4f" % visual_delta)
		if by_label.has("release_rollback"):
			_expect_true(str(by_label["release_rollback"].get("motion_state", "")) == "rollback", "release snapshot should record rollback after letting go")
			_expect_true(not bool(by_label["release_rollback"].get("contact_valid", true)), "release snapshot should record no active contact")
	lab.queue_free()
	await process_frame


func test_push_lab_obstacles_have_collision_bodies() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	var obstacle_root = lab.get_node_or_null("Mountain/ObstacleStones")
	_expect_true(obstacle_root != null, "push lab mountain should build obstacle root")
	if obstacle_root != null:
		_expect_true(obstacle_root.get_child_count() >= lab.tuning.obstacle_density, "push lab should instantiate obstacle bodies")
		var checked: int = 0
		for child in obstacle_root.get_children():
			if checked >= 6:
				break
			_expect_true(child is StaticBody3D, "obstacle should be a StaticBody3D, not only a visual mesh")
			_expect_true(child.get_node_or_null("CollisionShape3D") != null, "obstacle should expose a collision shape")
			checked += 1
	lab.queue_free()
	await process_frame


func test_push_lab_can_evaluate_aim_control_drill() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("evaluate_aim_control_drill"), "push lab should expose an aim-control drill for hand/contact/roll validation")
	if lab.has_method("evaluate_aim_control_drill"):
		var result: Dictionary = await lab.evaluate_aim_control_drill()
		_expect_true(bool(result.get("success", false)), "aim-control drill should pass: %s" % str(result))
		_expect_true(result.has("left") and result.has("right") and result.has("center"), "aim-control drill should report left, center, and right runs")
		var left: Dictionary = result.get("left", {})
		var right: Dictionary = result.get("right", {})
		var center: Dictionary = result.get("center", {})
		_expect_true(float(left.get("contact_side_offset", 0.0)) < -0.18, "left aim should move hand contact to the stone's left side")
		_expect_true(float(right.get("contact_side_offset", 0.0)) > 0.18, "right aim should move hand contact to the stone's right side")
		_expect_true(float(left.get("force_side_component", 0.0)) < -8.0, "left aim should apply leftward force")
		_expect_true(float(right.get("force_side_component", 0.0)) > 8.0, "right aim should apply rightward force")
		_expect_true(float(left.get("lateral_delta", 0.0)) < -0.08, "left aim should make the stone drift left in real physics")
		_expect_true(float(right.get("lateral_delta", 0.0)) > 0.08, "right aim should make the stone drift right in real physics")
		_expect_true(float(right.get("lateral_delta", 0.0)) - float(left.get("lateral_delta", 0.0)) > 0.28, "left/right aim should create a visible physical drift gap")
		_expect_true(absf(float(center.get("lateral_delta", 99.0))) < 0.16, "center aim should remain close to the main channel")
		_expect_true(float(left.get("uphill_gain", 0.0)) > 0.04, "left aim should keep a small uphill component while biasing; angle mastery covers whether it can truly climb")
		_expect_true(float(right.get("uphill_gain", 0.0)) > 0.04, "right aim should keep a small uphill component while biasing; angle mastery covers whether it can truly climb")
		_expect_true(float(left.get("contact_ratio", 0.0)) > 0.92, "left aim should keep sustained contact")
		_expect_true(float(right.get("contact_ratio", 0.0)) > 0.92, "right aim should keep sustained contact")
		_expect_true(float(left.get("max_spin_to_translation_ratio", 99.0)) < 12.0, "left aim should not devolve into in-place spin")
		_expect_true(float(right.get("max_spin_to_translation_ratio", 99.0)) < 12.0, "right aim should not devolve into in-place spin")
	lab.queue_free()
	await process_frame


func test_push_lab_can_evaluate_angle_mastery_drill() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("evaluate_angle_mastery_drill"), "push lab should gate whether wrong pressure angles fail")
	if lab.has_method("evaluate_angle_mastery_drill"):
		var result: Dictionary = await lab.evaluate_angle_mastery_drill()
		_expect_true(bool(result.get("success", false)), "angle mastery drill should pass on the current tuned baseline: %s" % str(result))
		_expect_true(float(result.get("center_gain", 0.0)) > 0.34, "sweet spot should make real uphill progress")
		_expect_true(float(result.get("high_side_gain", 99.0)) < -0.08, "bad high-side contact should lose ground, not merely stop climbing")
		_expect_true(
			float(result.get("high_side_quality", 99.0)) < float(result.get("center_quality", 0.0)) * 0.72,
			"bad high-side contact should read as lower quality than the sweet spot"
		)
	lab.queue_free()
	await process_frame


func test_push_lab_can_evaluate_short_slope_angle_gate() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("evaluate_short_slope_angle_gate"), "push lab should expose a short-slope angle gate for the core trick")
	if lab.has_method("evaluate_short_slope_angle_gate"):
		var result: Dictionary = await lab.evaluate_short_slope_angle_gate()
		_expect_true(bool(result.get("success", false)), "short-slope angle gate should pass: %s" % str(result))
		_expect_true(float(result.get("sweet_gain", 0.0)) > 0.42, "sweet spot should visibly climb on the short lab slope")
		_expect_true(float(result.get("near_miss_gain", 99.0)) < float(result.get("sweet_gain", 0.0)) * 0.25, "near-miss angle should not be enough to grind uphill with W")
		_expect_true(float(result.get("near_miss_rollback", 0.0)) > 0.18, "near-miss angle should give ground back to the slope")
		_expect_true(float(result.get("quality_gap", 0.0)) > 0.22, "sweet spot and near-miss contact should be mechanically distinguishable")
	lab.queue_free()
	await process_frame


func test_push_lab_can_evaluate_slow_aim_polarity_drill() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("evaluate_aim_polarity_drill"), "push lab should expose a slow aim-polarity drill for perceived left/right debugging")
	if lab.has_method("evaluate_aim_polarity_drill"):
		var result: Dictionary = await lab.evaluate_aim_polarity_drill()
		_expect_true(bool(result.get("success", false)), "slow aim-polarity drill should pass: %s" % str(result))
		_expect_true(result.has("left") and result.has("right") and result.has("center"), "aim-polarity drill should report left, center, and right runs")
		var left: Dictionary = result.get("left", {})
		var right: Dictionary = result.get("right", {})
		var center: Dictionary = result.get("center", {})
		_expect_true(bool(left.get("polarity_consistent", false)), "left aim should align contact, force, drift, and screen read")
		_expect_true(bool(right.get("polarity_consistent", false)), "right aim should align contact, force, drift, and screen read")
		_expect_true(float(left.get("contact_side_offset", 0.0)) < -0.18, "left polarity drill should record left contact")
		_expect_true(float(right.get("contact_side_offset", 0.0)) > 0.18, "right polarity drill should record right contact")
		_expect_true(float(left.get("force_side_component", 0.0)) < -8.0, "left polarity drill should record leftward force")
		_expect_true(float(right.get("force_side_component", 0.0)) > 8.0, "right polarity drill should record rightward force")
		_expect_true(float(left.get("lateral_delta", 0.0)) < -0.06, "left polarity drill should record real left drift")
		_expect_true(float(right.get("lateral_delta", 0.0)) > 0.06, "right polarity drill should record real right drift")
		_expect_true(float(left.get("stone_screen_x", 0.0)) > 0.08, "left pressure point should leave stone center to the right of the reticle")
		_expect_true(float(right.get("stone_screen_x", 0.0)) < -0.08, "right pressure point should leave stone center to the left of the reticle")
		_expect_true(float(result.get("drift_gap", 0.0)) > 0.24, "slow polarity drill should show a visible left/right drift gap")
		_expect_true(absf(float(center.get("lateral_delta", 99.0))) < 0.22, "center polarity drill may show route pressure but should not drift strongly")
		var left_samples: Array = left.get("samples", [])
		var right_samples: Array = right.get("samples", [])
		_expect_true(left_samples.size() >= 4, "left polarity drill should keep a slow-motion sample trail")
		_expect_true(right_samples.size() >= 4, "right polarity drill should keep a slow-motion sample trail")
	lab.queue_free()
	await process_frame


func test_push_lab_can_evaluate_bias_recovery_route() -> void:
	if not ResourceLoader.exists("res://scenes/PushLab.tscn"):
		return
	var scene: PackedScene = load("res://scenes/PushLab.tscn")
	var lab = scene.instantiate()
	root.add_child(lab)
	await physics_frame
	_expect_true(lab.has_method("evaluate_bias_recovery_route"), "push lab should expose a bias/glance/recovery route evaluator")
	if lab.has_method("evaluate_bias_recovery_route"):
		for side_sign in [-1.0, 1.0]:
			var result: Dictionary = await lab.evaluate_bias_recovery_route(side_sign)
			var side_label := "left" if side_sign < 0.0 else "right"
			_expect_true(result.has("success") and result.has("status"), "%s bias recovery route should return a gate result: %s" % [side_label, str(result)])
			_expect_true(float(result.get("max_air_gap", 99.0)) < 0.38, "%s biased obstacle glance should not launch the stone" % side_label)
			if bool(result.get("touched_obstacle", false)):
				_expect_true(float(result.get("min_speed_after_contact", 99.0)) < 2.2, "%s obstacle glance should visibly slow the stone" % side_label)
			_expect_true(absf(float(result.get("final_x", 99.0))) < float(result.get("clear_path_half_width", 0.0)) + 0.55, "%s route should remain recoverable inside the main channel" % side_label)
			_expect_true(float(result.get("total_distance", 0.0)) > 0.4, "%s route evaluator should move the stone through real scene physics" % side_label)
			_expect_true(float(result.get("max_spin_to_translation_ratio", 99.0)) < 12.0, "%s route evaluator should catch non-physical in-place spinning" % side_label)
	lab.queue_free()
	await process_frame


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _forearm_visual_length(hands: Node, node_name: String) -> float:
	var forearm = hands.get_node_or_null(node_name)
	if forearm == null or not (forearm is MeshInstance3D) or forearm.mesh == null:
		return INF
	var mesh_height: float = forearm.mesh.height if forearm.mesh is CapsuleMesh else 1.0
	return mesh_height * forearm.scale.y


func _hand_visual_radius(hands: Node, node_name: String) -> float:
	var hand = hands.get_node_or_null(node_name)
	if hand == null or not (hand is MeshInstance3D) or hand.mesh == null:
		return 0.0
	if hand.mesh is SphereMesh:
		return hand.mesh.radius
	return 0.0


func _forearm_visual_radius(hands: Node, node_name: String) -> float:
	var forearm = hands.get_node_or_null(node_name)
	if forearm == null or not (forearm is MeshInstance3D) or forearm.mesh == null:
		return 0.0
	if forearm.mesh is CapsuleMesh:
		return forearm.mesh.radius
	return 0.0


func _forearm_segment_clearance_to_stone(hands: Node, node_name: String, stone_position: Vector3) -> float:
	var forearm = hands.get_node_or_null(node_name)
	if forearm == null or not (forearm is MeshInstance3D) or forearm.mesh == null:
		return 0.0
	var length: float = _forearm_visual_length(hands, node_name)
	var axis: Vector3 = forearm.global_transform.basis.y.normalized()
	if axis.length_squared() < 0.001:
		return forearm.global_position.distance_to(stone_position)
	var start: Vector3 = forearm.global_position - axis * length * 0.5
	var end: Vector3 = forearm.global_position + axis * length * 0.5
	var segment: Vector3 = end - start
	var t: float = 0.0
	if segment.length_squared() > 0.001:
		t = clampf((stone_position - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	var closest: Vector3 = start + segment * t
	return closest.distance_to(stone_position)


func _snapshot_visual_delta(left_path: String, right_path: String) -> float:
	if not FileAccess.file_exists(left_path) or not FileAccess.file_exists(right_path):
		return 0.0
	var left_image := Image.load_from_file(left_path)
	var right_image := Image.load_from_file(right_path)
	if left_image == null or right_image == null:
		return 0.0
	if left_image.get_width() != right_image.get_width() or left_image.get_height() != right_image.get_height():
		return 1.0
	var width: int = left_image.get_width()
	var height: int = left_image.get_height()
	var step_x: int = max(1, width / 64)
	var step_y: int = max(1, height / 36)
	var total: float = 0.0
	var samples: int = 0
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var left_color: Color = left_image.get_pixel(x, y)
			var right_color: Color = right_image.get_pixel(x, y)
			total += absf(left_color.r - right_color.r)
			total += absf(left_color.g - right_color.g)
			total += absf(left_color.b - right_color.b)
			samples += 3
	if samples == 0:
		return 0.0
	return total / float(samples)
