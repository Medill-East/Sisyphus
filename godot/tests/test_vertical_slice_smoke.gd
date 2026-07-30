extends SceneTree

const LevelDefinitionScript = preload("res://scripts/LevelDefinition.gd")
const LevelManagerScript = preload("res://scripts/LevelManager.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("All vertical slice smoke tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run() -> void:
	test_vertical_slice_loop_contract()


func test_vertical_slice_loop_contract() -> void:
	var manager = LevelManagerScript.new()
	var level = LevelDefinitionScript.create_storm_vertical_slice()
	manager.start_level(level)
	manager.mark_ascent_started()
	_expect_true(manager.phase == "ascent", "level should enter ascent")
	manager.mark_released(Vector3.ZERO)
	manager.mark_stone_entered_back_slope()
	_expect_true(manager.phase == "descent", "release should lead to descent")
	manager.metrics.ascent_seconds = level.par_ascent_seconds
	manager.metrics.contact_stability = 0.75
	manager.mark_complete()
	_expect_true(manager.phase == "complete", "level should complete")
	_expect_true(manager.metrics.hum_clarity > 0.0, "completion should finalize metrics")
	manager.free()


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
