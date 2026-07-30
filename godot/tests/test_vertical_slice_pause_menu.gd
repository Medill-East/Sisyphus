extends SceneTree

const VerticalSliceScene = preload("res://scenes/VerticalSlice.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	test_pause_input_action_exists()
	await test_vertical_slice_pause_menu_contract()
	await test_pause_and_resume_methods()
	if failures.is_empty():
		print("All vertical slice pause menu tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_pause_input_action_exists() -> void:
	_expect_true(InputMap.has_action("pause_game"), "project should define a pause_game input action")


func test_vertical_slice_pause_menu_contract() -> void:
	var node = VerticalSliceScene.instantiate()
	root.add_child(node)
	await process_frame
	_expect_true(node.get_node_or_null("HUD/PauseMenu") != null, "vertical slice should include a pause menu overlay")
	_expect_true(node.get_node_or_null("HUD/PauseMenu/Panel/Content/ResumeButton") != null, "pause menu should include Resume")
	_expect_true(node.get_node_or_null("HUD/PauseMenu/Panel/Content/MainMenuButton") != null, "pause menu should include Main Menu")
	_expect_true(node.get_node_or_null("HUD/PauseMenu/Panel/Content/QuitButton") != null, "pause menu should include Quit")
	_expect_true(node.has_method("main_menu_scene_path"), "vertical slice should expose its menu target for tests")
	if node.has_method("main_menu_scene_path"):
		_expect_eq(node.main_menu_scene_path(), "res://scenes/MainMenu.tscn", "pause menu should target the release menu")
	node.queue_free()
	await process_frame


func test_pause_and_resume_methods() -> void:
	var node = VerticalSliceScene.instantiate()
	root.add_child(node)
	await process_frame
	_expect_true(node.has_method("pause_game"), "vertical slice should expose pause_game")
	_expect_true(node.has_method("resume_game"), "vertical slice should expose resume_game")
	if not node.has_method("pause_game") or not node.has_method("resume_game"):
		node.queue_free()
		await process_frame
		return
	node.pause_game()
	await process_frame
	_expect_true(paused, "pause_game should pause the scene tree")
	var pause_menu = node.get_node_or_null("HUD/PauseMenu")
	_expect_true(pause_menu != null and pause_menu.visible, "pause_game should show the pause menu")
	node.resume_game()
	await process_frame
	_expect_true(not paused, "resume_game should unpause the scene tree")
	_expect_true(pause_menu != null and not pause_menu.visible, "resume_game should hide the pause menu")
	node.queue_free()
	await process_frame
	paused = false


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
