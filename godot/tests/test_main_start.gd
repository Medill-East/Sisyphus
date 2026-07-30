extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const MainMenuScene = preload("res://scenes/MainMenu.tscn")
const GameStateScript = preload("res://scripts/GameState.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	test_project_boots_to_release_menu()
	await test_release_menu_contract()
	await test_main_scene_starts_in_approach()
	await test_vertical_slice_scene_loads()
	if failures.is_empty():
		print("All main start tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_project_boots_to_release_menu() -> void:
	_expect_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/MainMenu.tscn", "exported app should boot to the release menu")


func test_release_menu_contract() -> void:
	var menu = MainMenuScene.instantiate()
	root.add_child(menu)
	await process_frame
	_expect_true(menu.get_node_or_null("Panel/Content/Title") != null, "release menu should show the game title")
	_expect_true(menu.get_node_or_null("Panel/Content/PlayButton") != null, "release menu should expose a play button")
	_expect_true(menu.get_node_or_null("Panel/Content/QuitButton") != null, "release menu should expose a quit button")
	_expect_true(menu.has_method("vertical_slice_scene_path"), "release menu should expose its play target for tests")
	if menu.has_method("vertical_slice_scene_path"):
		_expect_eq(menu.vertical_slice_scene_path(), "res://scenes/VerticalSlice.tscn", "release menu play button should target the vertical slice")
	menu.queue_free()
	await process_frame


func test_main_scene_starts_in_approach() -> void:
	var main = MainScene.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame
	var distance: float = main.player.global_position.distance_to(main.stone.global_position)
	_expect_eq(main.game_state.phase, GameStateScript.Phase.APPROACH, "main scene should start in approach")
	_expect_true(distance > main.tuning.contact_distance, "player should start outside push contact distance")
	_expect_true(main.stone.linear_velocity.length() < 0.2, "stone should wait at the base instead of rolling before contact")
	_expect_true(main.get_node_or_null("HUD/CenterReticle") != null, "main scene should provide a center reference for push aiming")
	_expect_true(_reticle_is_subtle(main), "main reticle should read as a muted pressure reference, not a yellow debug cross")
	main.queue_free()
	await process_frame


func test_vertical_slice_scene_loads() -> void:
	_expect_true(ResourceLoader.exists("res://scenes/VerticalSlice.tscn"), "VerticalSlice scene should exist")
	if not ResourceLoader.exists("res://scenes/VerticalSlice.tscn"):
		return
	var scene: PackedScene = load("res://scenes/VerticalSlice.tscn")
	var node = scene.instantiate()
	root.add_child(node)
	await physics_frame
	_expect_true(node.get_node_or_null("Player") != null, "vertical slice needs player")
	_expect_true(node.get_node_or_null("Stone") != null, "vertical slice needs stone")
	_expect_true(node.get_node_or_null("Mountain") != null, "vertical slice needs mountain")
	_expect_true(node.get_node_or_null("LevelManager") != null, "vertical slice needs level manager")
	_expect_true(node.get_node_or_null("TrailRecorder") != null, "vertical slice needs trail recorder")
	_expect_true(node.get_node_or_null("EnvironmentResponse") != null, "vertical slice needs environment response")
	_expect_true(node.get_node_or_null("WeatherController") != null, "vertical slice needs weather controller")
	_expect_true(node.get_node_or_null("HummingController") != null, "vertical slice needs humming controller")
	_expect_true(node.get_node_or_null("HUD/CenterReticle") != null, "vertical slice should provide a center reference for push aiming")
	_expect_true(_reticle_is_subtle(node), "vertical slice reticle should not look like a bright debug vector")
	var rain_markers = node.get_node_or_null("RainMarkers")
	_expect_true(rain_markers == null or not rain_markers.visible, "placeholder rain marker rods should stay hidden until replaced with readable weather")
	node.queue_free()
	await process_frame


func _reticle_is_subtle(scene_root: Node) -> bool:
	var horizontal = scene_root.get_node_or_null("HUD/CenterReticle/Horizontal")
	var vertical = scene_root.get_node_or_null("HUD/CenterReticle/Vertical")
	if not (horizontal is ColorRect and vertical is ColorRect):
		return false
	for rect in [horizontal, vertical]:
		var color: Color = rect.color
		var saturation_hint: float = maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b))
		if saturation_hint > 0.16 or color.a > 0.45:
			return false
	return true


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
