extends SceneTree

const VerticalSliceScene = preload("res://scenes/VerticalSlice.tscn")
const GameStateScript = preload("res://scripts/GameState.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	await test_representative_pacing_profile_rebuilds_scene_route()
	await test_visual_modes_cover_task_10_states()
	await test_push_view_status_matches_reticle_contact()
	await test_push_transition_uses_bounded_first_person_hands()
	await test_connected_loop_visual_mode_progresses_through_required_states()
	await test_push_exit_modes_reset_third_person_pose()
	if failures.is_empty():
		print("All vertical slice visual mode tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_representative_pacing_profile_rebuilds_scene_route() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	_expect_true(slice.has_method("apply_pacing_profile"), "vertical slice should expose a pacing profile switch")
	if slice.has_method("apply_pacing_profile"):
		slice.apply_pacing_profile("representative")
		var front_distance: float = slice.tuning.front_base_z - slice.tuning.ridge_z
		var back_distance: float = slice.tuning.ridge_z - slice.tuning.back_base_z
		_expect_true(slice.tuning.pacing_profile_name == "representative", "representative pacing should be applied to tuning")
		_expect_true(front_distance >= 220.0, "representative scene should rebuild with extended ascent route")
		_expect_true(back_distance >= 520.0, "representative scene should rebuild with extended descent route")
		_expect_true(slice.mountain.obstacles.size() >= 80, "representative scene should rebuild obstacle pressure for the longer route")
		_expect_true(slice.stone.global_position.z > slice.tuning.front_base_z, "representative scene should move the starting stone to the extended front base")
	slice.queue_free()
	await process_frame


func test_visual_modes_cover_task_10_states() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	_expect_true(slice.has_method("apply_visual_mode"), "vertical slice should expose visual verification modes")
	if not slice.has_method("apply_visual_mode"):
		slice.queue_free()
		await process_frame
		return

	slice.apply_visual_mode("approach")
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.APPROACH, "approach visual mode should use approach phase")
	_expect_true(not slice.player.push_engaged, "approach mode should not engage push")

	slice.apply_visual_mode("push")
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.ASCENT, "push visual mode should use ascent phase")
	_expect_true(slice.player.push_engaged, "push mode should engage first-person push")
	_expect_true(slice.player.push_frame != null and slice.player.push_frame.contact_valid, "push mode should create valid contact")

	slice.apply_visual_mode("left")
	var left_x: float = slice.player.push_frame.camera_contact_point.x
	slice.apply_visual_mode("right")
	var right_x: float = slice.player.push_frame.camera_contact_point.x
	_expect_true(right_x - left_x > 0.45, "left/right visual modes should visibly move contact point")

	slice.apply_visual_mode("release")
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.RELEASE, "release visual mode should use release phase")
	_expect_true(not slice.player.push_engaged, "release mode should disengage push")

	slice.apply_visual_mode("descent")
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.DESCENT, "descent visual mode should use descent phase")
	_expect_true(slice.environment_response.response_points.size() > 0, "descent mode should show trail response")
	_expect_true(slice.has_method("descent_response_view_status"), "descent mode should expose camera visibility for changed path")
	if slice.has_method("descent_response_view_status"):
		var descent_view: Dictionary = slice.descent_response_view_status()
		_expect_true(int(descent_view.get("visible_response_points", 0)) >= 4, "descent camera should frame multiple changed-path markers")
		_expect_true(float(descent_view.get("camera_fov", 0.0)) >= 78.0, "descent camera should open up enough to read the changed world")
		_expect_true(float(descent_view.get("nearest_response_depth", 99.0)) > 1.2, "descent camera should observe response markers instead of clipping into them")

	slice.apply_visual_mode("hum")
	_expect_true(slice.humming_controller.clarity > 0.6, "hum reward mode should show clear humming")
	_expect_true(slice.get_node_or_null("HumPlayer") is AudioStreamPlayer, "vertical slice should expose a hum audio player")
	if slice.get_node_or_null("HumPlayer") is AudioStreamPlayer:
		var hum_player: AudioStreamPlayer = slice.get_node("HumPlayer")
		_expect_true(hum_player.stream is AudioStreamWAV, "hum mode should assign generated hum audio to the player")
		if DisplayServer.get_name() != "headless":
			_expect_true(hum_player.playing, "hum mode should start the generated hum audio outside headless tests")

	slice.apply_visual_mode("complete")
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.COMPLETE, "complete visual mode should end the first loop")
	_expect_true(not slice.player.push_engaged, "complete visual mode should not keep push engaged")
	_expect_true(
		slice.player.global_position.distance_to(slice.stone.global_position) <= slice.tuning.contact_distance + 0.5,
		"complete visual mode should show the player back beside the rolled stone"
	)
	_expect_true(not slice.prompt_label.text.contains("Hold W to push"), "complete prompt should not invite another same-scene push loop")
	_expect_true(slice.prompt_label.text.contains("Chapter"), "complete prompt should frame this as a chapter/loop ending")
	_expect_true(slice.has_method("chapter_end_status"), "complete should expose a chapter-end hold status for playtest reports")
	if slice.has_method("chapter_end_status"):
		var status: Dictionary = slice.chapter_end_status()
		_expect_true(bool(status.get("active", false)), "complete should begin the chapter-end hold shell")
		_expect_true(str(status.get("title", "")).contains("Chapter I End"), "chapter-end title should identify the first chapter ending")
		_expect_true(str(status.get("next_transition", "")).contains("pending"), "chapter-end should leave the next punishment transition pending")
		var camera_before: Vector3 = slice.camera.global_position
		if slice.has_method("advance_chapter_end_hold"):
			slice.advance_chapter_end_hold(3.0)
		var status_after: Dictionary = slice.chapter_end_status()
		_expect_true(float(status_after.get("elapsed_seconds", 0.0)) >= 3.0, "chapter-end hold should track reflective pause time")
		_expect_true(slice.camera.global_position.distance_to(camera_before) > 0.05, "chapter-end hold should move the camera into a reflective composition")
		_expect_true(slice.camera.global_position.distance_to(slice.stone.global_position) > 2.0, "chapter-end camera should observe the stone rather than clip into it")
		_expect_true(str(status_after.get("visual_beat", "")).contains("storm"), "chapter-end status should name the returning storm beat")
		_expect_true(float(status_after.get("storm_pressure", 0.0)) > 0.55, "chapter-end should visually bring divine pressure back")
		_expect_true(float(status_after.get("light_crack", 0.0)) > 0.0, "chapter-end should expose a small light crack rather than pure comfort")
		_expect_true(slice.get_node_or_null("ChapterEndMarkers/LightCrack") is MeshInstance3D, "chapter-end should have a visible light crack marker")
		_expect_true(slice.get_node_or_null("ChapterEndMarkers/StormShards") is Node3D, "chapter-end should group storm shards instead of one debug wall")
		var storm_shards: Node3D = slice.get_node_or_null("ChapterEndMarkers/StormShards")
		if storm_shards != null:
			_expect_true(storm_shards.get_child_count() >= 3, "chapter-end storm should use multiple narrow shards")
			for child in storm_shards.get_children():
				_expect_true(child is MeshInstance3D, "storm shard should be a visible mesh")
				if child is MeshInstance3D:
					var mesh_instance: MeshInstance3D = child
					_expect_true(mesh_instance.visible, "storm shard should be visible at chapter end")
					if mesh_instance.mesh is BoxMesh:
						var size: Vector3 = mesh_instance.mesh.size
						_expect_true(size.x <= 1.8, "storm shard should stay narrow, not become a wall: %.2f" % size.x)
						_expect_true(size.y >= 2.4, "storm shard should read as a vertical storm strip: %.2f" % size.y)
		if slice.get_node_or_null("ChapterEndMarkers/LightCrack") is MeshInstance3D:
			_expect_true(slice.get_node("ChapterEndMarkers/LightCrack").visible, "light crack marker should be visible at chapter end")
	slice.queue_free()
	await process_frame


func test_push_exit_modes_reset_third_person_pose() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame

	slice.apply_visual_mode("push")
	_expect_true(slice.player.push_engaged, "setup should enter push mode")
	_expect_true(slice.player.push_frame != null, "setup should create a push frame")

	slice.apply_visual_mode("descent")
	_expect_true(not slice.player.push_engaged, "descent should exit engaged push")
	_expect_true(slice.player.push_frame == null, "descent should clear stale push contact frame")
	_expect_true(slice.player.camera_push_blend == 0.0, "descent should fully return to third-person camera blend")
	_expect_true(slice.player.get_node("Body").visible, "third-person body should be visible after exiting push")
	_expect_true(not slice.player.get_node("FirstPersonHands").visible, "first-person hands should be hidden after exiting push")
	var left_hand: MeshInstance3D = slice.player.get_node("Body/LeftArm/Hand")
	var right_hand: MeshInstance3D = slice.player.get_node("Body/RightArm/Hand")
	_expect_true(left_hand.position.y < -0.30, "left hand should rest near the side after push exit")
	_expect_true(right_hand.position.y < -0.30, "right hand should rest near the side after push exit")
	_expect_true(absf(left_hand.position.z) < 0.20, "left hand should not stay reaching forward after push exit")
	_expect_true(absf(right_hand.position.z) < 0.20, "right hand should not stay reaching forward after push exit")

	slice.queue_free()
	await process_frame


func test_push_view_status_matches_reticle_contact() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	_expect_true(slice.has_method("push_view_status"), "vertical slice should expose push-view status for real-scene reticle/contact verification")
	if not slice.has_method("push_view_status"):
		slice.queue_free()
		await process_frame
		return

	slice._apply_push_visual(Vector3.LEFT * 0.42 + Vector3.DOWN * 0.42)
	var status: Dictionary = slice.push_view_status()
	_expect_true(bool(status.get("hands_visible", false)), "push view should show first-person hands in the real vertical slice")
	_expect_true(not bool(status.get("body_visible", true)), "push view should hide the third-person body before it can stretch")
	_expect_true(float(status.get("stone_camera_x_ratio", 99.0)) < 0.78, "biased/downward vertical-slice push should keep the stone readable")
	_expect_true(float(status.get("contact_camera_x_ratio", 99.0)) < 0.50, "reticle-selected contact should remain aimable in the real vertical slice")
	_expect_true(
		float(status.get("camera_forward_y", 1.0)) < -0.16,
		"push camera should allow looking down at hands/contact in the real vertical slice: %.3f" % float(status.get("camera_forward_y", 1.0))
	)
	_expect_true(bool(status.get("contact_cue_visible", false)), "push view should show the pressure cue in the real vertical slice")
	_expect_true(float(status.get("contact_cue_to_contact", 99.0)) < 0.14, "pressure cue should sit on the selected contact point")
	_expect_true(status.has("nearest_hand_to_contact"), "vertical-slice push status should expose palm-to-contact distance")
	_expect_true(float(status.get("nearest_hand_to_contact", 99.0)) < 0.70, "at least one palm should press near the selected contact point in the real vertical slice")
	_expect_true(float(status.get("minimum_hand_surface_clearance", -99.0)) > 0.02, "first-person palms should stay outside the stone surface")
	_expect_true(status.has("minimum_forearm_surface_clearance"), "vertical-slice push status should expose forearm-to-stone clearance")
	_expect_true(float(status.get("minimum_forearm_surface_clearance", -99.0)) > 0.02, "first-person forearms should not cut through the stone in the real vertical slice")
	_expect_true(float(status.get("camera_fov", 0.0)) >= 108.0, "push camera should keep enough FOV for peripheral route judgment")
	_expect_true(status.has("visible_left_route_markers"), "vertical-slice push status should expose left route-edge visibility")
	_expect_true(status.has("visible_right_route_markers"), "vertical-slice push status should expose right route-edge visibility")
	_expect_true(int(status.get("visible_left_route_markers", 0)) >= 1, "left route edge should remain readable in the real vertical-slice push view")
	_expect_true(int(status.get("visible_right_route_markers", 0)) >= 1, "right route edge should remain readable in the real vertical-slice push view")
	_expect_true(float(status.get("route_edge_camera_x_ratio", 99.0)) < 1.15, "vertical-slice route edges should sit inside push-view peripheral vision")
	slice.queue_free()
	await process_frame


func test_push_transition_uses_bounded_first_person_hands() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	slice._apply_push_visual(Vector3.ZERO)
	slice.player.camera_push_blend = 0.06
	slice.player.update_push_visual_mode()
	slice.player._update_first_person_hands(slice.player.push_frame.aim_direction)
	var hands = slice.player.get_node_or_null("FirstPersonHands")
	var body = slice.player.get_node_or_null("Body")
	var left_arm = slice.player.get_node_or_null("Body/LeftArm")
	var right_arm = slice.player.get_node_or_null("Body/RightArm")
	_expect_true(hands != null and not hands.visible, "first-person hands should wait until the push camera is close enough")
	_expect_true(body != null and body.visible, "third-person body should remain visible during the early camera transition")
	_expect_true(left_arm != null and left_arm.visible, "left connected arm should remain visible during early reach-in")
	_expect_true(right_arm != null and right_arm.visible, "right connected arm should remain visible during early reach-in")
	slice.player.camera_push_blend = 0.96
	slice.player.update_push_visual_mode()
	slice.player._update_first_person_hands(slice.player.push_frame.aim_direction)
	_expect_true(hands != null and hands.visible, "first-person hands should take over once the push camera is close")
	_expect_true(body != null and not body.visible, "third-person body should hide once first-person hands take over")
	_expect_true(left_arm != null and not left_arm.visible, "left third-person arm should hide once first-person hands take over")
	_expect_true(right_arm != null and not right_arm.visible, "right third-person arm should hide once first-person hands take over")
	if hands != null:
		var max_visual_length: float = slice.tuning.first_person_forearm_max_length + 0.04
		_expect_true(_forearm_visual_length(hands, "LeftForearm") <= max_visual_length, "left first-person forearm should remain bounded during vertical-slice push transition")
		_expect_true(_forearm_visual_length(hands, "RightForearm") <= max_visual_length, "right first-person forearm should remain bounded during vertical-slice push transition")
	slice.queue_free()
	await process_frame


func test_connected_loop_visual_mode_progresses_through_required_states() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	_expect_true(slice.has_method("advance_visual_loop"), "vertical slice should expose a deterministic connected-loop driver")
	if not slice.has_method("advance_visual_loop"):
		slice.queue_free()
		await process_frame
		return

	slice.apply_visual_mode("loop")
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.APPROACH, "loop should begin at approach")
	_advance_loop(slice, 1.1)
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.ASCENT, "loop should advance into ascent")
	_expect_true(slice.player.push_engaged, "loop ascent should engage push")
	_expect_true(slice.trail_recorder.points.size() > 0, "loop ascent should record trail points")
	_advance_loop(slice, 1.2)
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.RELEASE, "loop should advance into release")
	_expect_true(not slice.player.push_engaged, "loop release should disengage push")
	_advance_loop(slice, 1.2)
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.DESCENT, "loop should advance into descent")
	_expect_true(slice.environment_response.response_points.size() > 0, "loop descent should show environment response")
	_advance_loop(slice, 1.2)
	_expect_true(slice.humming_controller.clarity > 0.6, "loop should end with a clear hum reward state")
	_expect_true(slice.get_node_or_null("HumPlayer") is AudioStreamPlayer, "loop should keep a hum audio player")
	if slice.get_node_or_null("HumPlayer") is AudioStreamPlayer:
		var hum_player: AudioStreamPlayer = slice.get_node("HumPlayer")
		_expect_true(hum_player.stream is AudioStreamWAV, "loop should route generated hum audio to the player")
	_advance_loop(slice, 1.2)
	_expect_eq(slice.game_state.phase, GameStateScript.Phase.COMPLETE, "loop visual driver should end at complete, not restart into another push")
	_expect_true(not slice.player.push_engaged, "loop complete should leave push disengaged")
	slice.queue_free()
	await process_frame


func _advance_loop(slice, seconds: float) -> void:
	var steps: int = int(ceil(seconds / 0.1))
	for index in steps:
		slice.advance_visual_loop(0.1)


func _forearm_visual_length(hands: Node, child_name: String) -> float:
	var forearm = hands.get_node_or_null(child_name)
	if forearm == null or not (forearm is MeshInstance3D):
		return 999.0
	var mesh_instance: MeshInstance3D = forearm
	if mesh_instance.mesh is CapsuleMesh:
		return mesh_instance.mesh.height * mesh_instance.scale.y
	return mesh_instance.scale.y


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
