extends SceneTree

const PlayerScene = preload("res://scenes/Player.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	var player = PlayerScene.instantiate()
	root.add_child(player)
	await process_frame
	var left_audio: AudioStreamPlayer3D = player.get_node_or_null("LeftScrapeAudio")
	var right_audio: AudioStreamPlayer3D = player.get_node_or_null("RightScrapeAudio")
	var hands = player.get_node_or_null("FirstPersonHands")
	_expect_true(left_audio != null and right_audio != null, "player should expose independent left/right scrape players")
	_expect_true(player.has_method("apply_per_hand_feedback_levels"), "player should expose per-hand feedback routing")
	_expect_true(hands != null and hands.has_method("set_hand_loads"), "first-person hands should accept independent load strengths")
	if left_audio != null and right_audio != null and player.has_method("apply_per_hand_feedback_levels"):
		player.call("apply_per_hand_feedback_levels", 0.85, 0.15)
		print(
			"TWO_HAND_FEEDBACK left_loaded_db=(%.1f,%.1f) haptic=(%.2f,%.2f)"
			% [left_audio.volume_db, right_audio.volume_db, player.left_haptic_level, player.right_haptic_level]
		)
		_expect_true(left_audio.stream is AudioStreamWAV and right_audio.stream is AudioStreamWAV, "scrape players should use generated local audio")
		_expect_true(left_audio.volume_db > right_audio.volume_db + 8.0, "left-loaded state should be measurably louder on the left")
		_expect_true(float(player.get("left_haptic_level")) > float(player.get("right_haptic_level")) + 0.5, "left-loaded state should differ across haptic channels")
		player.call("apply_per_hand_feedback_levels", 0.10, 0.90)
		print(
			"TWO_HAND_FEEDBACK right_loaded_db=(%.1f,%.1f) haptic=(%.2f,%.2f)"
			% [left_audio.volume_db, right_audio.volume_db, player.left_haptic_level, player.right_haptic_level]
		)
		_expect_true(right_audio.volume_db > left_audio.volume_db + 8.0, "right-loaded state should be measurably louder on the right")
		_expect_true(float(player.get("right_haptic_level")) > float(player.get("left_haptic_level")) + 0.5, "right-loaded state should differ across haptic channels")
	if hands != null and hands.has_method("set_hand_loads"):
		hands.call("set_hand_loads", 0.9, 0.1)
		var left_hand: MeshInstance3D = hands.get_node("LeftHand")
		var right_hand: MeshInstance3D = hands.get_node("RightHand")
		_expect_true(left_hand.scale.x > right_hand.scale.x + 0.15, "left hand should visibly compress more under greater left load")
	player.queue_free()
	await process_frame
	if failures.is_empty():
		print("All two-hand feedback tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
