extends SceneTree

const VerticalSliceScene = preload("res://scenes/VerticalSlice.tscn")

const REPORT_PATH := "/private/tmp/sisyphus-manual-snapshot-test.md"
const SCREENSHOT_PATH := "/private/tmp/sisyphus-manual-snapshot-test.png"
const CHAPTER_END_REPORT_PATH := "/private/tmp/sisyphus-chapter-end-snapshot-test.md"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_async")


func _run_async() -> void:
	test_save_playtest_report_input_action_is_bound()
	await test_vertical_slice_can_save_manual_playtest_snapshot()
	await test_complete_snapshot_records_chapter_end_shell()
	if failures.is_empty():
		print("All vertical slice playtest capture tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func test_vertical_slice_can_save_manual_playtest_snapshot() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	slice.apply_visual_mode("hum")
	_expect_true(slice.has_method("save_playtest_report"), "vertical slice should expose manual playtest report saving")
	if slice.has_method("save_playtest_report"):
		var error = slice.save_playtest_report(REPORT_PATH, "capture-test")
		_expect_eq(error, OK, "manual playtest report save should return OK")
		_expect_true(FileAccess.file_exists(REPORT_PATH), "manual playtest report should be written to disk")
		if FileAccess.file_exists(REPORT_PATH):
			var content := FileAccess.get_file_as_string(REPORT_PATH)
			_expect_true(content.contains("# Playtest Report"), "manual report should use playtest report format")
			_expect_true(content.contains("capture-test"), "manual report should include tester id")
			_expect_true(content.contains("Manual snapshot"), "manual report should identify itself as a manual snapshot")
			_expect_true(content.contains("Generated Hum Stream"), "manual report should include hum stream evidence")
			_expect_true(content.contains("Telemetry HUD"), "manual report should include final telemetry HUD")
			_expect_true(content.contains("Screenshot Path"), "manual report should include screenshot path")
			_expect_true(content.contains(SCREENSHOT_PATH), "manual report should link the saved screenshot")
			_expect_true(content.contains("Gate:"), "manual report should include telemetry gate")
			_expect_true(content.contains("Environment Response Layers"), "manual report should include layered descent response counts")
			_expect_true(content.contains("changed the world"), "manual report should tie descent response to world-change evidence")
			_expect_true(content.contains("- **Phase At End**: descent"), "manual report quantitative phase should match current scene phase")
		_expect_true(FileAccess.file_exists(SCREENSHOT_PATH), "manual playtest snapshot should write a screenshot PNG")
		if FileAccess.file_exists(SCREENSHOT_PATH):
			var image := Image.load_from_file(SCREENSHOT_PATH)
			_expect_true(image != null and image.get_width() > 16 and image.get_height() > 16, "snapshot PNG should be a readable viewport image")
		_expect_true(slice.get("last_playtest_report_saved"), "slice should track successful manual report save")
		_expect_true(slice.get("last_playtest_report_path") == REPORT_PATH, "slice should expose last manual report path")
		_expect_true(slice.get("last_playtest_screenshot_path") == SCREENSHOT_PATH, "slice should expose last manual screenshot path")
	await _free_slice(slice)


func test_complete_snapshot_records_chapter_end_shell() -> void:
	var slice = VerticalSliceScene.instantiate()
	root.add_child(slice)
	await physics_frame
	slice.apply_visual_mode("complete")
	if slice.has_method("advance_chapter_end_hold"):
		slice.advance_chapter_end_hold(4.0)
	var error = slice.save_playtest_report(CHAPTER_END_REPORT_PATH, "chapter-end-test")
	_expect_eq(error, OK, "chapter-end playtest report save should return OK")
	_expect_true(FileAccess.file_exists(CHAPTER_END_REPORT_PATH), "chapter-end report should be written to disk")
	if FileAccess.file_exists(CHAPTER_END_REPORT_PATH):
		var content := FileAccess.get_file_as_string(CHAPTER_END_REPORT_PATH)
		_expect_true(content.contains("Chapter End Evidence"), "complete report should include chapter-end evidence")
		_expect_true(content.contains("Chapter End Active"), "complete report should record whether the hold shell is active")
		_expect_true(content.contains("Next Punishment Pending"), "complete report should keep the next transition unresolved")
		_expect_true(content.contains("Returning Storm Beat"), "complete report should record the chapter-end visual beat")
		_expect_true(content.contains("Light Crack"), "complete report should record the unresolved light crack")
		_expect_true(content.contains("Audio Beat"), "complete report should record the chapter-end audio beat")
		_expect_true(content.contains("Storm Audio Presence"), "complete report should record storm audio presence")
		_expect_true(content.contains("Hum Does Not Overpower Storm"), "complete report should record that hum does not erase storm")
		_expect_true(content.contains("chapter-end-test"), "complete report should include tester id")
		_expect_true(content.contains("- **Phase**: complete"), "complete report should save from complete phase")
	await _free_slice(slice)


func test_save_playtest_report_input_action_is_bound() -> void:
	_expect_true(InputMap.has_action("save_playtest_report"), "project should bind save_playtest_report input action")
	if InputMap.has_action("save_playtest_report"):
		var has_f9 := false
		for event in InputMap.action_get_events("save_playtest_report"):
			if event is InputEventKey and event.keycode == KEY_F9:
				has_f9 = true
		_expect_true(has_f9, "save_playtest_report should be bound to F9")


func _free_slice(slice) -> void:
	if slice.has_method("_release_hum_audio"):
		slice._release_hum_audio()
	slice.queue_free()
	for index in 4:
		await process_frame


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
